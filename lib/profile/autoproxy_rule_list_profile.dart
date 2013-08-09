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
 * Matches when the url matches the AutoProxy [ruleList].
 * The AutoProxy [ruleList] format is defined by:
 * https://autoproxy.org/zh-CN/node/19
 */
class AutoProxyRuleListProfile extends RuleListProfile {
  final String profileType = 'AutoProxyRuleListProfile';

  AutoProxyRuleListProfile(String name, String defaultProfileName,
      String matchProfileName)
      : super(name, defaultProfileName, matchProfileName);

  // The rule list can be Base 64 encoded.
  // Detect encoded "[AutoProxy" sequence at the beginning.
  static const _autoProxyRulesBase64Magic = 'W0F1dG9Qcm94';

  /**
   * The rule list format is defined by:
   * https://autoproxy.org/zh-CN/node/19
   */
  List<Rule> parseRules(String rules) {
    bool begin = false;
    rules = rules.trim();
    if (rules.startsWith(_autoProxyRulesBase64Magic)) {
      rules = new String.fromCharCodes(CryptoUtils.base64StringToBytes(rules));
    }
    var lines = rules.split(new RegExp(r'\n|\r'));
    var normal_rules = <Rule>[];
    var exclusive_rules = <Rule>[];
    for (var line in lines) {
      line = line.trim();
      if (line.length == 0 || line[0] == '!' || line[0] == '[') continue;
      String profile = this.matchProfileName;
      var list = normal_rules;
      if (line.startsWith('@@')) {
        profile = this.defaultProfileName;
        list = exclusive_rules;
        line = line.substring(2);
      }
      Condition cond;
      if (line[0] == '/') {
        cond = new UrlRegexCondition(line.substring(1, line.length - 1));
      } else if (line[0] == '|') {
        if (line[1] == '|') {
          cond = new HostWildcardCondition('*.${line.substring(2)}');
        } else {
          cond = new UrlWildcardCondition('${line.substring(1)}*');
        }
      } else {
        cond = new KeywordCondition(line);
      }
      list.add(new Rule(cond, profile));
    }
    // Exclusive rules have higher priority, so they come first.
    exclusive_rules.addAll(normal_rules);
    return exclusive_rules;
  }

  void applyUpdate(String data) {
    var rules = data.trim();
    if (rules.startsWith(_autoProxyRulesBase64Magic)) {
      rules = new String.fromCharCodes(CryptoUtils.base64StringToBytes(rules));
    }
    this.ruleList = rules;
  }
}