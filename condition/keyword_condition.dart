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
 * Matches if the scheme of the url is 'http' and the [pattern] is a 
 * substring of the [url].
 */
class KeywordCondition extends UrlCondition {
  final String conditionType = 'KeywordCondition';

  String pattern;
  
  bool matchUrl(String url, scheme) {
    return scheme == 'http' && url.contains(pattern);
  }
  
  void writeTo(CodeWriter w) {
    w.inline("scheme === 'http' && url.indexOf(${JSON.stringify(pattern)}) >= 0");
  }
  
  KeywordCondition([this.pattern = '']);
  
  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['pattern'] = this.pattern;
    return p;
  }
  
  void fromPlain(Map<String, Object> p) {
    super.fromPlain(p);
    this.pattern = p['pattern'];
  }
  
  factory KeywordCondition.fromPlain(Map<String, Object> p) {
    var c = new KeywordCondition(p['pattern']);
    c.fromPlain(p);
    return c;
  }
}