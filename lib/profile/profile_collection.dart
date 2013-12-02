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
 * A set of profiles. Predefined profiles are pre-added to the set,
 * but they are not converted to plain.
 */

class ProfileCollection extends ObservableMap<String, Profile>
   implements Plainable, ProfileTracker {
  Map<String, _ProfileData> _profiles;

  /**
   * Returns the profile by its [name].
   */
  Profile getProfileByName(String name) {
    return this[name];
  }

  static final List<Profile> predefinedProfiles = [new AutoDetectProfile(),
                                                   new DirectProfile(),
                                                   new SystemProfile()];

  void _addPredefined() {
    for (var profile in predefinedProfiles) {
      super[profile.name] = profile;
      _profiles[profile.name] = new _ProfileData(profile);
    }
  }

  /**
   * Convert this collection to a map of plain profile objects.
   * Predefined profiles will not be included in the result.
   */
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    if (p == null) p = new Map<String, Object>();
    _profiles.values.forEach((prof) {
      if (!prof.profile.predefined) {
        p['+' + prof.profile.name] = prof.profile.toPlain();
      }
    });

    return p;
  }

  ProfileCollection([Iterable<Profile> profiles = null]) {
    _profiles = new Map<String, _ProfileData>();
    _addPredefined();
    if (profiles != null) {
      this.addProfiles(profiles);
    }
  }

  @reflectable void operator []=(String key, Profile value) {
    var len = this.length;
    var profile = this[key];
    if (profile.predefined) return;
    if (profile is InclusiveProfile) {
      profile.tracker = null;
    }

    super[key] = value;
    if (value is InclusiveProfile) {
      value.tracker = this;
    }
  }

  void addProfiles(Iterable<Profile> profiles) {
    var added_profile = new Queue<Profile>();
    profiles.forEach((profile) {
      if (!this.containsKey(profile.name)) {
        this[profile.name] = profile;
        _profiles[profile.name] = new _ProfileData(profile);
        added_profile.add(profile);
      }
    });
    added_profile.forEach((profile) {
      if (profile is InclusiveProfile) {
        profile.tracker = this;
      }
    });
  }

  void addAll(Map<String, Profile> profiles) {
    this.addProfiles(profiles.values);
  }

  Profile putIfAbsent(String key, Profile ifAbsent()) {
    Profile result = super.putIfAbsent(key, ifAbsent);
    if (result is InclusiveProfile) {
      result.tracker = this;
    }
    return result;
  }

  /**
   * Remove the profile with [name] if it is not predefined.
   * If the profile is still referred by another profile, throws [StateError].
   */
  Profile remove(String name) {
    var profile = this[name];
    if (profile == null || profile.predefined) return null;
    var data = _profiles[name];
    if (data.referredBy.length > 0) throw new StateError(
        'This profile cannot be removed because it is still referred by'
        'at least one profile.');
    Profile result = super.remove(name);
    if (result is InclusiveProfile) {
      result.tracker = this;
    }
    return result;
  }

  /**
   * This method doesn't really clear all profiles, because predefined
   * profiles cannot be removed.
   */
  void clear() {
    int len = length;
    this.values.forEach((profile) {
      if (profile is InclusiveProfile) {
        profile.tracker = null;
      }
    });
    super.clear();
    _profiles.clear();
    _addPredefined();
  }

  void loadPlain(Map<String, Object> p) {
    var plainProfiles = new Queue<Profile>();

    p.forEach((key, value) {
      if (key[0] == '+') {
        plainProfiles.add(new Profile.fromPlain(value));
      }
    });

    this.addAll(plainProfiles);
  }

  factory ProfileCollection.fromPlain(List<Object> p) {
    var c = new ProfileCollection();
    c.loadPlain(p);
    return c;
  }

  bool contains(Profile value) {
    return _profiles.containsKey(value.name);
  }

  bool add(Profile profile) {
    bool added = false;
    super.putIfAbsent(profile.name, () {
      added = true;
      return profile;
    });

    return added;
  }

  /**
   * Remove the profile with [name] if it is not predefined.
   * If the profile is still referred by another profile, the references are
   * cleared.
   * This method may cause inconsistency unless used with great care.
   */
  Profile forceRemove(String name) {
    var profile = this[name];
    if (profile == null || profile.predefined) return null;
    var data = _profiles[name];
    if (data.referredBy.length > 0) {
      new Map.from(data.referredBy).forEach((profile, count) {
        for (var i = 0; i < count; i++)
          removeReferenceByName(profile, name);
      });
    }
    return remove(name);
  }

  Object toJson() {
    return this.toPlain();
  }

  void addReferenceByName(InclusiveProfile from, String toName) {
    var fromName = from.name;
    var from_data = _profiles[fromName];
    var to_data = _profiles[toName];

    if (to_data.allRef != null && to_data.allRef.containsKey(fromName)) {
      throw new CircularReferenceException(from, _profiles[toName].profile);
    }

    from_data.directRef.increase(toName);
    from_data.allRef.increase(toName);
    to_data.referredBy.increase(fromName);

    from_data.referredBy.forEach((profile, count) {
      _profiles[profile].allRef.increase(fromName, count);
    });

    if (to_data.allRef != null) {
      to_data.allRef.forEach((profile, count) {
        _profiles[profile].referredBy.increase(fromName, count);
        from_data.allRef.increase(profile, count);
      });
    }
  }

  void removeReferenceByName(InclusiveProfile from, String toName) {
    var fromName = from.name;
    var from_data = _profiles[fromName];
    var to_data = _profiles[toName];

    to_data.referredBy.decrease(fromName);

    if (from_data != null) {
      from_data.directRef.decrease(toName);
      from_data.allRef.decrease(toName);
      from_data.referredBy.forEach((profile, count) {
        _profiles[profile].allRef.decrease(toName, count);
      });
    }

    if (to_data.allRef != null) {
      to_data.allRef.forEach((profile, count) {
        _profiles[profile].referredBy.decrease(fromName, count);
        from_data.allRef.decrease(profile, count);
      });
    }
  }

  void renameProfile(String oldName, String newName) {
    var profileData = _profiles[oldName];
    if (profileData == null) return;

    var profile = profileData.profile;
    profile.name = newName;
    this.add(profileData.profile);

    this.deliverChanges();
    profile.name = oldName;

    for (var data in _profiles.values) {
      if (data.profile is InclusiveProfile && data.profile.name != oldName) {
        (data.profile as InclusiveProfile)
            ..renameProfile(oldName, newName)
            ..deliverChanges();

      }
    }

    this.remove(profile);
    if (profile is InclusiveProfile) {
      profile.tracker = this;
    }
    this.deliverChanges();
    profile.name = newName;
  }

  Iterable<Profile> validResultProfilesFor(InclusiveProfile profile) {
    return this.values.where((p) {
      if (p == profile || p is! IncludableProfile) return false;
      if (p is InclusiveProfile) if (p.hasReferenceTo(profile.name))
        return false;
      return true;
    });
  }

  void addReference(InclusiveProfile from, IncludableProfile to) {
    addReferenceByName(from, to.name);
  }

  void removeReference(InclusiveProfile from, IncludableProfile to) {
    removeReferenceByName(from, to.name);
  }

  bool hasReference(InclusiveProfile from, IncludableProfile to) =>
      hasReferenceToName(from, to.name);

  Iterable<IncludableProfile> directReferences(InclusiveProfile profile) =>
      _profiles[profile.name].directRef.keys.map(getProfileByName);

  Iterable<IncludableProfile> allReferences(InclusiveProfile profile) =>
      _profiles[profile.name].allRef.keys.map(getProfileByName);

  Iterable<InclusiveProfile> referredBy(IncludableProfile profile) =>
      _profiles[profile.name].referredBy.keys.map(getProfileByName);

  bool hasReferenceToName(InclusiveProfile from, String toName) =>
      _profiles[from.name].allRef.containsKey(toName);
}

/**
 * Contains data needed for ProfileCollection implementation.
 */
class _ProfileData {
  Profile profile;
  CountMap<String> directRef = null;
  CountMap<String> allRef = null;
  CountMap<String> referredBy = null;

  _ProfileData(this.profile) {
    referredBy = new CountMap<String>();
    if (profile is InclusiveProfile) {
      directRef = new CountMap<String>();
      allRef = new CountMap<String>();
    }
  }
}

class CountMap<E> implements Map<E, int> {
  Map<E, int> _count = new Map<E, int>();

  int increase(E element, [int count = 1]) {
    if (count < 0) throw new ArgumentError('count must not be negative.');
    return _count[element] = ifNull(_count[element], 0) + count;
  }

  int decrease(E element, [int count = 1]) {
    var c = _count[element];
    if (c == null) {
      throw new StateError('The element is not in the map.');
    }
    if (c > count) {
      return _count[element] = c - count;
    } else if (c == count) {
      _count.remove(element);
      return 0;
    } else {
      throw new StateError('count must not be greater than the value in map.');
    }
  }

  bool containsValue(int value) {
    return _count.containsValue(value);
  }

  bool containsKey(E key) {
    return _count.containsKey(key);
  }

  int operator [](E key) => _count[key];

  void operator []=(E key, int value) {
    throw new UnsupportedError('Count values cannot be set directly.');
  }

  int putIfAbsent(E key, int ifAbsent()) {
    throw new UnsupportedError('Count values cannot be set directly.');
  }

  int remove(E key) => _count.remove(key);

  void clear() {
    _count.clear();
  }

  void forEach(void f(E key, int value)) {
    _count.forEach(f);
  }

  void addAll(Map<E, int> items) {
    items.forEach((key, value) {
      this.increase(key, value);
    });
  }

  Iterable<E> get keys => _count.keys;

  Iterable<int> get values => _count.values;

  int get length => _count.length;

  bool get isEmpty => _count.isEmpty;
  bool get isNotEmpty => !_count.isEmpty;
}