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


abstract class InclusiveProfile_MixinBugWorkaround extends InclusiveProfile {
  InclusiveProfile_MixinBugWorkaround() : super('');
  void workaroundSetName(String name) { _name = name; }
}

/**
 * Selects the result profile of the first matching [Rule],
 * or the [defaultProfileName] if no rule matches.
 */
class SwitchProfile extends InclusiveProfile_MixinBugWorkaround with ListMixin
    implements List<Rule> {
  String get profileType => 'SwitchProfile';

  List<Rule> _rules;

  void _onRuleProfileNameChange(Rule rule, String oldProfileName) {
    if (tracker != null) {
      tracker.removeReferenceByName(this, oldProfileName);
      tracker.addReferenceByName(this, rule.profileName);
    }
  }

  void initTracker(ProfileTracker tracker) {
    tracker.addReferenceByName(this, defaultProfileName);
    _rules.forEach((rule) {
      tracker.addReferenceByName(this, rule.profileName);
      rule.onProfileNameChange = _onRuleProfileNameChange;
    });
  }

  void renameProfile(String oldName, String newName) {
    _rules.forEach((rule) {
      if (rule.profileName == oldName) {
        rule.profileName = newName;
      }
    });
    if (this.defaultProfileName == oldName) this.defaultProfileName = newName;
  }

  void _track(Rule r) {
    if (tracker != null) tracker.addReferenceByName(this, r.profileName);
    r.onProfileNameChange = _onRuleProfileNameChange;
  }

  void _untrack(Rule r) {
    if (tracker != null) tracker.removeReferenceByName(this, r.profileName);
    r.onProfileNameChange = null;
  }

  String _defaultProfileName;
  String get defaultProfileName => _defaultProfileName;
  void set defaultProfileName(String value) {
    if (tracker != null) {
      tracker.removeReferenceByName(this, _defaultProfileName);
      tracker.addReferenceByName(this, value);
    }
    _defaultProfileName = value;
  }

  void writeTo(CodeWriter w) {
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");

    for (var rule in _rules) {
      w.inline('if (');
      rule.condition.writeTo(w);
      w.code(')').indent();
      var ip = tracker.getProfileByName(rule.profileName) as IncludableProfile;
      w.code('return ${ip.getScriptName()};')
       .outdent();
    }

    var dp = tracker.getProfileByName(defaultProfileName) as IncludableProfile;
    w.code('return ${dp.getScriptName()};');
    w.inline('}');
  }

  String choose(String url, String host, String scheme, DateTime datetime) {
    for (var rule in _rules) {
      if (rule.condition.match(url, host, scheme, datetime)) {
        return rule.profileName;
      }
    }
    return defaultProfileName;
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['defaultProfileName'] = defaultProfileName;
    p['rules'] = this.map((r) => r.toPlain()).toList();

    return p;
  }

  SwitchProfile(String name, String defaultProfileName) : super() {
    workaroundSetName(name);
    if (tracker != null) tracker.addReferenceByName(this, defaultProfileName);
    this._defaultProfileName = defaultProfileName;
    this._rules = new List<Rule>();
  }

  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    var rl = p['rules'] as List<Map<String, Object>>;
    this.addAll(rl.map((r) => new Rule.fromPlain(r)));
  }

  factory SwitchProfile.fromPlain(Map<String, Object> p) {
    var f = new SwitchProfile(p['name'], p['defaultProfileName']);
    f.loadPlain(p);
    return f;
  }

  int get length => _rules.length;

  void set length(int newLength) {
    if (newLength < this.length) {
      for (var i = newLength; i < this.length; i++) {
        _untrack(this[i]);
      }
    }
    this._rules.length = newLength;
  }

  Rule operator [](int i) => this._rules[i];

  void operator []=(int i, Rule rule) {
    if (this[i] != null) _untrack(this[i]);
    _track(rule);
    this._rules[i] = rule;
  }

  void add(Rule rule) {
    _track(rule);
    this._rules.add(rule);
  }

  bool remove(Rule rule) {
    var index = this._rules.indexOf(rule);
    if (index < 0) return false;
    _untrack(rule);
    return this._rules.remove(rule);
  }

  void addAll(Iterable<Rule> rules) {
    rules.forEach(_track);
    this._rules.addAll(rules);
  }

  void clear() {
    this._rules.forEach(_untrack);
    this._rules.clear();
  }

  void removeAll(Iterable<Rule> elementsToRemove) {
    for (var rule in elementsToRemove) {
      this.remove(rule);
    }
  }

  bool contains(Rule rule) {
    return this._rules.contains(rule);
  }

}