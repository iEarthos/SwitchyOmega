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
  abstract String get conditionType();
  
  /**
   * Returns true if the [url], [host], [scheme] and [datetime] matches this
   * condition. False otherwise. 
   */
  abstract bool match(String url, String host, String scheme, Date datetime);
  
  /**
   * Write this condition to [w] as a JavaScript expression.
   */
  abstract void writeTo(CodeWriter w);
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    if (p == null) p = new Map<String, Object>();
    p['conditionType'] = this.conditionType;

    return p;
  }
  
  Condition();
  
  factory Condition.fromPlain(Map<String, Object> p, [Object config]) {
    switch (p['conditionType']) {
      case 'BypassCondition':
        return new BypassCondition.fromPlain(p, config);
      case 'AlwaysCondition':
        return new AlwaysCondition.fromPlain(p, config);
      case 'NeverCondition':
        return new NeverCondition.fromPlain(p, config);
      case 'HostLevelsCondition':
        return new HostLevelsCondition.fromPlain(p, config);
      case 'HostRegexCondition':
        return new HostRegexCondition.fromPlain(p, config);
      case 'HostWildcardCondition':
        return new HostWildcardCondition.fromPlain(p, config);
      case 'IpCondition':
        return new IpCondition.fromPlain(p, config);
      case 'KeywordCondition':
        return new KeywordCondition.fromPlain(p, config);
      case 'UrlRegexCondition':
        return new UrlRegexCondition.fromPlain(p, config);
      case 'UrlWildcardCondition':
        return new UrlWildcardCondition.fromPlain(p, config);
    }
  }
}
