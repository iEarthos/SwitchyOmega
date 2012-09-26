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
 * When a [Condition] is met in an [InclusiveProfile], the corresponding result
 * profile is selected.
 */
abstract class Condition extends Plainable {
  String get conditionType();
  
  /**
   * Returns true if the [url], [host], [scheme] and [datetime] matches this
   * condition. False otherwise. 
   */
  bool match(String url, String host, String scheme, Date datetime);
  
  /**
   * Write this condition to [w] as a JavaScript expression.
   */
  void writeTo(CodeWriter w);
  
  Map<String, Object> toPlain([Map<String, Object> p]) {
    if (p == null) p = new Map<String, Object>();
    p['conditionType'] = this.conditionType;

    return p;
  }
  
  Condition();
  
  void loadPlain(Object p) {}
  
  factory Condition.fromPlain(Map<String, Object> p) {
    switch (p['conditionType']) {
      case 'BypassCondition':
        return new BypassCondition.fromPlain(p);
      case 'AlwaysCondition':
        return new AlwaysCondition.fromPlain(p);
      case 'NeverCondition':
        return new NeverCondition.fromPlain(p);
      case 'HostLevelsCondition':
        return new HostLevelsCondition.fromPlain(p);
      case 'HostRegexCondition':
        return new HostRegexCondition.fromPlain(p);
      case 'HostWildcardCondition':
        return new HostWildcardCondition.fromPlain(p);
      case 'IpCondition':
        return new IpCondition.fromPlain(p);
      case 'KeywordCondition':
        return new KeywordCondition.fromPlain(p);
      case 'UrlRegexCondition':
        return new UrlRegexCondition.fromPlain(p);
      case 'UrlWildcardCondition':
        return new UrlWildcardCondition.fromPlain(p);
    }
  }
}
