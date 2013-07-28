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
 * Matches when the url matches the [ruleList].
 * If [sourceUrl] is not null, the ruleList will be downloaded from [sourceUrl].
 */
abstract class RuleListProfile extends InclusiveProfile {
  String _sourceUrl;
  String get sourceUrl => _sourceUrl;

  void set sourceUrl(String value) {
    _sourceUrl = value;
    _ruleList = null;
    _rules = null;
  }

  String _matchProfileName;
  String get matchProfileName => _matchProfileName;
  void set matchProfileName(String value) {
    if (value != _matchProfileName && tracker != null) {
      tracker.removeReferenceByName(this, _matchProfileName);
      tracker.addReferenceByName(this, value);
    }
    _matchProfileName = value;
  }

  String _defaultProfileName;
  String get defaultProfileName => _defaultProfileName;
  void set defaultProfileName(String value) {
    if (value != _defaultProfileName && tracker != null) {
      tracker.removeReferenceByName(this, _defaultProfileName);
      tracker.addReferenceByName(this, value);
    }
    _defaultProfileName = value;
  }

  List<Rule> _rules;

  String _ruleList;
  String get ruleList => _ruleList;

  void set ruleList(String value) {
    _ruleList = value;
    _rules = null;
  }

  void writeTo(CodeWriter w) {
    if (_rules == null) _rules = parseRules(ruleList);
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");

    IncludableProfile mp = tracker.getProfileByName(matchProfileName);
    var matchScriptName = mp.getScriptName();
    IncludableProfile dp = tracker.getProfileByName(defaultProfileName);
    var defaultScriptName = dp.getScriptName();

    for (var rule in _rules) {
      w.inline('if (');
      rule.condition.writeTo(w);
      w.code(')').indent();
      var scriptName = rule.profileName == this.matchProfileName ?
          matchScriptName :
          defaultScriptName;
      w.code('return ${scriptName};')
       .outdent();
    }

    w.code('return ${defaultScriptName};');
    w.inline('}');
  }

  void renameProfile(String oldName, String newName) {
    if (matchProfileName == oldName) {
      matchProfileName = newName;
    }
    if (defaultProfileName == oldName) {
      defaultProfileName = newName;
    }
  }

  String choose(String url, String host, String scheme, DateTime datetime) {
    for (var rule in _rules) {
      if (rule.condition.match(url, host, scheme, datetime)) {
        return rule.profileName;
      }
    }
    return defaultProfileName;
  }

  void initTracker(ProfileTracker tracker) {
    tracker.addReferenceByName(this, matchProfileName);
    tracker.addReferenceByName(this, defaultProfileName);
  }

  /**
   * Parse the [rules] and return the results.
   */
  List<Rule> parseRules(String rules);

  bool containsProfileName(String name) {
    return matchProfileName == name || defaultProfileName == name;
  }

  Iterable<Profile> getProfileNames() {
    return [tracker.getProfileByName(matchProfileName),
            tracker.getProfileByName(defaultProfileName)];
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['defaultProfileNameName'] = defaultProfileName;
    p['matchProfileNameName'] = matchProfileName;
    if (sourceUrl != null) {
      p['sourceUrl'] = sourceUrl;
    } else {
      p['ruleList'] = ruleList;
    }
  }

  RuleListProfile(String name, this._defaultProfileName,
                  this._matchProfileName)
    : super(name);

  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    defaultProfileName = p['defaultProfileNameName'];
    matchProfileName = p['matchProfileNameName'];
    var u = p['sourceUrl'];
    if (u != null) {
      sourceUrl = u;
    } else {
      ruleList = p['ruleList'];
    }
  }

  factory RuleListProfile.fromPlain(Map<String, Object> p) {
    RuleListProfile f = null; // TODO

    return f;
  }
}
