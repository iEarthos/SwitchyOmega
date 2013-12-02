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
@observable
abstract class RuleListProfile extends InclusiveProfile
    implements UpdatingProfile {
  String sourceUrl = '';

  String matchProfileName;

  String defaultProfileName;

  List<Rule> _rules;

  String ruleList = '';

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
    if (_rules == null) _rules = parseRules(ruleList);
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

  Iterable<Profile> getProfiles() {
    return [tracker.getProfileByName(matchProfileName),
            tracker.getProfileByName(defaultProfileName)];
  }

  String get updateUrl => sourceUrl;

  void applyUpdate(String data) {
    this.ruleList = data;
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['defaultProfileName'] = defaultProfileName;
    p['matchProfileName'] = matchProfileName;
    if (sourceUrl != null && sourceUrl.length > 0) {
      p['sourceUrl'] = sourceUrl;
    }
    p['ruleList'] = ruleList;

    return p;
  }

  RuleListProfile(String name, this.defaultProfileName,
                  this.matchProfileName)
    : super(name) {
    this.changes.listen((records) {
      if (records.any((rec) => rec is PropertyChangeRecord &&
          rec.name == #sourceUrl && rec.newValue != rec.oldValue &&
          rec.newValue != null && rec.newValue != '')) {
        this.ruleList = '';
      }
      if (tracker != null) {
        records.forEach((rec) {
          if (rec is PropertyChangeRecord) {
            switch (rec.name) {
              case 'defaultProfileName':
              case 'matchProfileName':
                if (rec.newValue != rec.oldValue) {
                  tracker.removeReferenceByName(this, rec.oldValue);
                  tracker.addReferenceByName(this, rec.newValue);
                }
                break;
            }
          }
        });
      }
    });
  }

  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    defaultProfileName = p['defaultProfileName'];
    matchProfileName = p['matchProfileName'];
    var u = p['sourceUrl'];
    if (u != null && u.length > 0) {
      sourceUrl = u;
    }
    ruleList = p['ruleList'];

    var unobserve;
    unobserve = this.changes.listen((records) {
      ruleList = p['rulelist'];
      unobserve();
    });
  }

  factory RuleListProfile.fromPlain(Map<String, Object> p) {
    RuleListProfile f = null;
    switch (p['profileType']) {
      case 'SwitchyRuleListProfile':
        f = new SwitchyRuleListProfile(p['name'], p['defaultProfileName'],
            p['matchProfileName']);
        break;
      case 'AutoProxyRuleListProfile':
        f = new AutoProxyRuleListProfile(p['name'],
            p['defaultProfileName'], p['matchProfileName']);
        break;
      default:
        throw new UnsupportedError(
            'Unknown profile type ${p['profileType']}.');
    }
    f.loadPlain(p);
    return f;
  }
}
