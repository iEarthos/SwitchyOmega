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
 * Matches when the url matches the [ruleList].
 * If [sourceUrl] is not null, the ruleList will be downloaded from [sourceUrl].
 */
abstract class RuleListProfile extends InclusiveProfile {
  String _sourceUrl;
  String get sourceUrl() => _sourceUrl;
  
  void set sourceUrl(String value) {
    _sourceUrl = value;
    _ruleList = null;
    _rules = null;
  }
  
  IncludableProfile matchProfile;
  IncludableProfile defaultProfile;
  
  List<Rule> _rules;
  
  String _ruleList;
  String get ruleList() => _ruleList;
  
  void set ruleList(String value) {
    _ruleList = value;
    _rules = null;
  }
  
  void writeTo(CodeWriter w) {
    if (_rules == null) _rules = parseRules(ruleList);
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");
    
    for (var rule in _rules) {
      w.inline('if (');
      rule.condition.writeTo(w);
      w.code(')').indent()
       .code('return ${rule.profile.getScriptName()};')
       .outdent();
    }
    
    w.code('return ${defaultProfile.getScriptName()};');
    w.inline('}');
  }
  
  /**
   * Parse the [rules] and return the results.
   */
  abstract List<Rule> parseRules(String rules);
  
  bool containsProfile(IncludableProfile p) {
    return matchProfile == p || defaultProfile == p;
  }
  
  List<IncludableProfile> getProfiles() {
    return [matchProfile, defaultProfile];
  }
  
  /**
   * [:config['profileNameOnly']:] can be set to true for writing
   * [defaultProfile.name] as defaultProfileName and
   * [matchProfile.name] as matchProfileName.
   */
  Map<String, Object> toPlain([Map<String, Object> p, Map<String, Object> config]) {
    p = super.toPlain(p, config);
    if (config != null && config['profileNameOnly'] != null) {
      p['defaultProfileName'] = defaultProfile.name;
      p['matchProfileName'] = matchProfile.name;
    } else {
      p['defaultProfile'] = defaultProfile.toPlain(null, config);
      p['matchProfile'] = matchProfile.toPlain(null, config);
    }
    if (sourceUrl != null) {
      p['sourceUrl'] = sourceUrl;
    } else {
      p['ruleList'] = ruleList;
    }
  }
  
  RuleListProfile(String name, this.defaultProfile, this.matchProfile)
    : super(name);
  
  /**
   * If [:p['defaultProfileName']:] is used instead of [:p['defaultProfile']:],
   * or [:p['matchProfileName']:] is used instead of [:p['matchProfile']:],
   * [:config['profileResolver']:] must be set to a [ProfileResolver].
   */
  factory RuleListProfile.fromPlain(Map<String, Object> p, 
    [Map<String, Object> config]) {
    RuleListProfile f = null;
    
    f.color = p['color'];
    var prof = p['defaultProfile'];
    if (prof == null) {
      ProfileResolver resolver = config['profileResolver']; // CAST
      f.defaultProfile = resolver(p['defaultProfileName']);
    } else {
      f.defaultProfile = new Profile.fromPlain(prof, config);
    }
    prof = p['matchProfile'];
    if (prof == null) {
      ProfileResolver resolver = config['profileResolver']; // CAST
      f.matchProfile = resolver(p['matchProfileName']);
    } else {
      f.matchProfile = new Profile.fromPlain(prof, config);
    }
    
    var u = p['sourceUrl'];
    if (u != null) {
      f.sourceUrl = u;
    } else {
      f.ruleList = p['ruleList'];
    }
    
    return f;
  }
}
