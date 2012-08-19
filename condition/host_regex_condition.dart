/*!
 * Copyright (C) 2012, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * Matches when the host matches the [regex] [pattern].
 */
class HostRegexCondition extends HostCondition {
  final String conditionType = 'HostRegexCondition';

  RegExp regex;
  
  /** Get the pattern of the [regex]. */
  String get pattern() => regex.pattern;
  
  /** Set the [regex] to a new [RegExp] with a pattern of [value]. */
  void set pattern(String value) { regex = new RegExp(value); }
  
  bool matchHost(String host) {
    return regex.hasMatch(host);
  }
  
  void writeTo(CodeWriter w) {
    w.inline('new RegExp(${JSON.stringify(regex.pattern)}).test(host)');
  }
  
  HostRegexCondition([Object regex = '']) {
    this.regex = (regex is String) ? new RegExp(regex) : regex;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['pattern'] = this.pattern;
    return p;
  }
  
  void fromPlain(Map<String, Object> p) {
    super.fromPlain(p);
    this.pattern = p['pattern'];
  }
  
  factory HostRegexCondition.fromPlain(Map<String, Object> p) {
    var c = new HostRegexCondition(p['pattern']);
    c.fromPlain(p);
    return c;
  }
}
