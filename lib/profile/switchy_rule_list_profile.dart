part of switchy_profile;

/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS file
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
 * Matches when the url matches the Switchy [ruleList].
 * The Switchy [ruleList] format is defined by:
 * https://code.google.com/p/switchy/wiki/RuleList
 */
class SwitchyRuleListProfile extends RuleListProfile {
  @reflectable final String profileType = 'SwitchyRuleListProfile';

  SwitchyRuleListProfile(String name, String defaultProfileName,
      String matchProfileName)
      : super(name, defaultProfileName, matchProfileName);

  /**
   * The rule list format is defined by:
   * https://code.google.com/p/switchy/wiki/RuleList
   */
  List<Rule> parseRules(String rules) {
    bool begin = false;
    var lines = rules.split(new RegExp(r'\n|\r'));
    var normal_rules = <Rule>[];
    var exclusive_rules = <Rule>[];
    var section = '';
    for (var line in lines) {
      line = line.trim();
      if (!begin) {
        if (line == '#BEGIN') {
          begin = true;
        }
        continue;
      }
      if (line.length == 0) continue;
      if (line == '#END') break;
      if (line == '[Wildcard]' || line == '[RegExp]') {
        section = line;
      } else {
        String profile = this.matchProfileName;
        var list = normal_rules;
        if (line[0] == '!') {
          profile = this.defaultProfileName;
          list = exclusive_rules;
          line = line.substring(1);
        }
        Condition cond = null;
        switch (section) {
          case '[Wildcard]':
            cond = new UrlWildcardCondition(line);
            break;
          case '[RegExp]':
            cond = new UrlRegexCondition(line);
            break;
          default:
            continue;
        }
        list.add(new Rule(cond, profile));
      }
    }
    // Exclusive rules have higher priority, so they come first.
    exclusive_rules.addAll(normal_rules);
    return exclusive_rules;
  }
}