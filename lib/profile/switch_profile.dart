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
@observable
class SwitchProfile extends InclusiveProfile with ListMixin, Observable
    implements List<Rule> {
  String get profileType => 'SwitchProfile';

  void initTracker(ProfileTracker tracker) {
    tracker.addReferenceByName(this, defaultProfileName);
    _list.forEach((rule) {
      tracker.addReferenceByName(this, rule.profileName);
    });
  }

  void renameProfile(String oldName, String newName) {
    _list.forEach((rule) {
      if (rule.profileName == oldName) {
        rule.profileName = newName;
      }
    });
    if (this.defaultProfileName == oldName) this.defaultProfileName = newName;
  }

  String defaultProfileName;

  void writeTo(CodeWriter w) {
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");

    for (var rule in _list) {
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
    for (var rule in _list) {
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

  final Map<Rule, ChangeUnobserver> _unobserve = {};

  SwitchProfile(String name, this.defaultProfileName) : super(name) {
    if (tracker != null) tracker.addReferenceByName(this, defaultProfileName);

    observeChanges(this, (List<ChangeRecord> changes) {
      changes.forEach((rec) {
        if (rec.type == ChangeRecord.FIELD &&
            rec.key == 'defaultProfileName') {
          if (rec.newValue != rec.oldValue && tracker != null) {
            tracker.removeReferenceByName(this, rec.oldValue);
            tracker.addReferenceByName(this, rec.newValue);
          }
        }
        if (rec.type == ChangeRecord.REMOVE ||
            rec.type == ChangeRecord.INDEX) {
          if (rec.oldValue != null) {
            Rule r = rec.oldValue as Rule;
            if (tracker != null) tracker.removeReferenceByName(this,
                r.profileName);
            _unobserve[r]();
          }
        }
        if (rec.type == ChangeRecord.INSERT ||
            rec.type == ChangeRecord.INDEX) {
          if (rec.newValue != null) {
            Rule r = rec.newValue as Rule;
            if (tracker != null) tracker.addReferenceByName(this,
                r.profileName);
            _unobserve[r] = observeChanges(r as Observable,
                (List<ChangeRecord> changes) {
              if (tracker == null) return;
              var changed = false;
              changes.forEach((rec2) {
                if (rec2.oldValue != rec2.newValue) {
                  changed = true;
                  if (rec2.key == 'profileName') {
                    tracker.removeReferenceByName(this, rec2.oldValue);
                    tracker.addReferenceByName(this, rec2.newValue);
                  }
                }
              });
              if (changed) {
                notifyChange(this, ChangeRecord.FIELD, '[rules]', '', null);
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
    this.clear();
    this.addAll(rl.map((r) => new Rule.fromPlain(r)));
    deliverChangesSync();
  }

  factory SwitchProfile.fromPlain(Map<String, Object> p) {
    var f = new SwitchProfile(p['name'], p['defaultProfileName']);
    f.loadPlain(p);
    return f;
  }

  // Members below are copied from package:web_ui/observe/list.dart and
  // then modified (replacing <E> with <Rule>).

  /** The inner [List<Rule>] with the actual storage. */
  final List<Rule> _list = [];

  int get length {
    if (observeReads) notifyRead(this, ChangeRecord.FIELD, 'length');
    return _list.length;
  }

  set length(int value) {
    int len = _list.length;
    if (len == value) return;

    // Produce notifications if needed
    if (hasObservers(this)) {
      if (value < len) {
        // Remove items, then adjust length. Note the reverse order.
        for (int i = len - 1; i >= value; i--) {
          notifyChange(this, ChangeRecord.REMOVE, i, _list[i], null);
        }
        notifyChange(this, ChangeRecord.FIELD, 'length', len, value);
      } else {
        // Adjust length then add items
        notifyChange(this, ChangeRecord.FIELD, 'length', len, value);
        for (int i = len; i < value; i++) {
          notifyChange(this, ChangeRecord.INSERT, i, null, null);
        }
      }
    }

    _list.length = value;
  }

  Rule operator [](int index) {
    if (observeReads) notifyRead(this, ChangeRecord.INDEX, index);
    return _list[index];
  }

  operator []=(int index, Rule value) {
    var oldValue = _list[index];
    if (hasObservers(this)) {
      notifyChange(this, ChangeRecord.INDEX, index, oldValue, value);
    }
    _list[index] = value;
  }

  List<Rule> sublist(int start, [int end]) =>
    toObservable(super.sublist(start, end));

  // The following three methods (add, removeRange, insertRange) are here so
  // that we can provide nice change events (insertions and removals). If we
  // use the mixin implementation, we would only report changes on indices.

  void add(Rule value) {
    int len = _list.length;
    if (hasObservers(this)) {
      notifyChange(this, ChangeRecord.FIELD, 'length', len, len + 1);
      notifyChange(this, ChangeRecord.INSERT, len, null, value);
    }

    _list.add(value);
  }

  // TODO(jmesserly): removeRange and insertRange will cause duplicate
  // notifcations for insert/remove in the middle. The first will be for the
  // insert/remove and the second will be for the array move. Also, setting
  // length happens after the insert/remove notifcation. I think this is
  // probably unavoidable because of how arrays work: if you insert/remove in
  // the middle you effectively change elements throughout the array.
  // Maybe we need a ChangeRecord.MOVE?

  void removeRange(int start, int length) {
    if (length == 0) return;

    _Arrays.rangeCheck(this, start, length);
    if (hasObservers(this)) {
      for (int i = start; i < length; i++) {
        notifyChange(this, ChangeRecord.REMOVE, i, this[i], null);
      }
    }
    _Arrays.copy(this, start + length, this, start,
        this.length - length - start);

    this.length = this.length - length;
  }

  void insertRange(int start, int length, [Rule initialValue]) {
    if (length == 0) return;
    if (length < 0) {
      throw new ArgumentError("invalid length specified $length");
    }
    if (start < 0 || start > this.length) throw new RangeError.value(start);

    if (hasObservers(this)) {
      for (int i = start; i < length; i++) {
        notifyChange(this, ChangeRecord.INSERT, i, null, initialValue);
      }
    }

    var oldLength = this.length;
    this.length = oldLength + length;  // Will expand if needed.
    _Arrays.copy(this, start, this, start + length, oldLength - start);
    for (int i = start; i < start + length; i++) {
      this[i] = initialValue;
    }
  }

}

// Copied from package:web_ui/src/utils_observe.dart.
class _Arrays {
  static void copy(List src, int srcStart,
                   List dst, int dstStart, int count) {
    if (srcStart == null) srcStart = 0;
    if (dstStart == null) dstStart = 0;

    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
           i >= srcStart; i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }

  static void rangeCheck(List a, int start, int length) {
    if (length < 0) {
      throw new ArgumentError("negative length $length");
    }
    if (start < 0 ) {
      String message = "$start must be greater than or equal to 0";
      throw new RangeError(message);
    }
    if (start + length > a.length) {
      String message = "$start + $length must be in the range [0..${a.length})";
      throw new RangeError(message);
    }
  }
}
