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
 * Selects the result profile of the first matching [Rule],
 * or the [defaultProfileName] if no rule matches.
 */
class SwitchProfile extends InclusiveProfile with Observable {
  @reflectable String get profileType => 'SwitchProfile';

  @reflectable final ObservableList<Rule> rules = toObservable([]);

  void initTracker(ProfileTracker tracker) {
    tracker.addReferenceByName(this, defaultProfileName);
    rules.forEach((rule) {
      tracker.addReferenceByName(this, rule.profileName);
    });
  }

  void renameProfile(String oldName, String newName) {
    rules.forEach((rule) {
      if (rule.profileName == oldName) {
        rule.profileName = newName;
      }
    });
    if (this.defaultProfileName == oldName) this.defaultProfileName = newName;
  }

  @observable String defaultProfileName;

  void writeTo(CodeWriter w) {
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");

    for (var rule in rules) {
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
    for (var rule in rules) {
      if (rule.condition.match(url, host, scheme, datetime)) {
        return rule.profileName;
      }
    }
    return defaultProfileName;
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['defaultProfileName'] = defaultProfileName;
    p['rules'] = this.rules.map((r) => r.toPlain()).toList();

    return p;
  }

  final Map<Rule, StreamSubscription<List<ChangeRecord>>> _subs = {};

  SwitchProfile(String name, this.defaultProfileName) : super(name) {
    if (tracker != null) tracker.addReferenceByName(this, defaultProfileName);

    this.changes.listen((records) {
      records.forEach((rec) {
        if (rec is PropertyChangeRecord &&
            rec.name == #defaultProfileName) {
          if (rec.newValue != rec.oldValue && tracker != null) {
            tracker.removeReferenceByName(this, rec.oldValue);
            tracker.addReferenceByName(this, rec.newValue);
          }
        }
      });
    });
    this.rules.changes.listen((records) {
      records.forEach((rec) {
        if (rec is MapChangeRecord && (rec.isRemove || !rec.isInsert)) {
          if (rec.oldValue != null) {
            Rule r = rec.oldValue as Rule;
            if (tracker != null) tracker.removeReferenceByName(this,
                r.profileName);
            _subs[r].cancel();
          }
        }
        if (rec is MapChangeRecord && (rec.isInsert || !rec.isRemove)) {
          if (rec.newValue != null) {
            Rule r = rec.newValue as Rule;
            if (tracker != null) tracker.addReferenceByName(this,
                r.profileName);
            _subs[r] = r.changes.listen((changes) {
              if (tracker == null) return;
              var changed = false;
              changes.forEach((rec2) {
                if (rec2 is PropertyChangeRecord &&
                    rec2.oldValue != rec2.newValue) {
                  changed = true;
                  if (rec2.name == #profileName) {
                    tracker.removeReferenceByName(this, rec2.oldValue);
                    tracker.addReferenceByName(this, rec2.newValue);
                  }
                }
              });
              if (changed) {
                this.notifyPropertyChange(#details, null, '');
              }
            });
          }
        }
      });
    });
  }

  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    this.defaultProfileName = p['defaultProfileName'];
    var rl = p['rules'] as List<Map<String, Object>>;
    this.rules.clear();
    this.rules.addAll(rl.map((r) => new Rule.fromPlain(r)));
    this.deliverChanges();
  }

  factory SwitchProfile.fromPlain(Map<String, Object> p) {
    var f = new SwitchProfile(p['name'], p['defaultProfileName']);
    f.loadPlain(p);
    return f;
  }
}
