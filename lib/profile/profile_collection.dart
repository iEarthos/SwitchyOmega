part of switchy_profile;

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
 * A set of profiles. Predefined profiles are pre-added to the set,
 * but they are not converted to plain.
 */

class ProfileCollection extends HashSet<Profile>
   implements Set<Profile>, Plainable, ProfileTracker {
  Map<String, _ProfileData> _profiles;
  bool _renamingProfile = false;

  /**
   * Returns the profile by its [name].
   */
  Profile getProfileByName(String name) {
    var data = _profiles[name];
    return data == null ? null : data.profile;
  }

  /**
   * Returns the profile by its [name].
   */
  Profile operator [](String name) {
    return getProfileByName(name);
  }

  void _addPredefined() {
    this.add(new AutoDetectProfile());
    this.add(new DirectProfile());
    this.add(new SystemProfile());
  }

  /**
   * Convert this collection to a list of plain profile objects.
   * Predefined profiles will not be included in the result.
   */
  List<Object> toPlain([List<Object> p, Object config]) {
    if (p == null) p = new List<Object>();
    p.addAll(_profiles.values.where((prof) => !prof.profile.predefined)
        .map((prof) => prof.profile.toPlain()));

    return p;
  }

  ProfileCollection([Iterable<Profile> profiles = null]) {
    _profiles = new Map<String, _ProfileData>();
    _addPredefined();
    if (profiles != null) {
      this.addAll(profiles);
    }
  }

  void loadPlain(List<Object> p) {
    this.addAll(p.map(
        (Map<String, Object> profile) => new Profile.fromPlain(profile)));
  }

  factory ProfileCollection.fromPlain(List<Object> p) {
    var c = new ProfileCollection();
    c.loadPlain(p);
    return c;
  }

  bool contains(Profile value) {
    return _profiles.containsKey(value.name);
  }

  void add(Profile profile) {
    if (!_profiles.containsKey(profile.name)) {
      _profiles[profile.name] = new _ProfileData(profile);
      if (profile is InclusiveProfile) {
        profile.tracker = this;
      }
    }
  }

  void addAll(Iterable<Profile> profiles) {
    var added_profile = new Queue<Profile>();
    profiles.forEach((profile) {
      if (!_profiles.containsKey(profile.name)) {
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

  /**
   * Remove [value] from this set if [value] is not predefined.
   * If the [value] is still referred by another profile, throws [StateError].
   */
  bool remove(Profile value) {
    if (value.predefined) return false;
    var data = _profiles[value.name];
    if (data == null) return false;
    if (data.referredBy.length > 0) throw new StateError(
        'This profile cannot be removed because it is still referred by'
        'at least one profile.');
    _profiles.remove(value.name);
    if (value is InclusiveProfile) {
      value.tracker = null;
    }
    return true;
  }

  /**
   * This method doesn't really clear all profiles, because predefined
   * profiles cannot be removed.
   */
  void clear() {
    _profiles.values.forEach((data) {
      if (data.profile is InclusiveProfile) {
        (data.profile as InclusiveProfile).tracker = null;
      }
    });
    _profiles.clear();
    _addPredefined();
  }

  Object toJson() {
    return this.toPlain();
  }

  Iterator get iterator =>
      _profiles.values.map((data) => data.profile).iterator;

  int get length {
    return _profiles.length;
  }

  void addReference(InclusiveProfile from, IncludableProfile to) {
    if (_renamingProfile) return;
    var from_data = _profiles[from.name];
    var to_data = _profiles[to.name];

    if (to_data.allRef != null && to_data.allRef.containsKey(from)) {
      throw new CircularReferenceException(from, to);
    }

    from_data.directRef.increase(to);
    from_data.allRef.increase(to);
    to_data.referredBy.increase(from);

    for (var profile in from_data.referredBy.keys) {
      _profiles[profile.name].allRef.increase(to);
    }
    if (to_data.allRef != null) {
      for (var profile in to_data.allRef.keys) {
        _profiles[profile.name].referredBy.increase(from);
      }
    }
  }

  void removeReference(InclusiveProfile from, IncludableProfile to) {
    if (_renamingProfile) return;
    var from_data = _profiles[from.name];
    var to_data = _profiles[to.name];
    from_data.directRef.decrease(to);
    from_data.allRef.decrease(to);
    to_data.referredBy.decrease(from);

    for (var profile in from_data.referredBy.keys) {
      _profiles[profile.name].allRef.decrease(to);
    }
    if (to_data.allRef != null) {
      for (var profile in to_data.allRef.keys) {
        _profiles[profile.name].referredBy.decrease(from);
      }
    }
  }

  bool hasReference(InclusiveProfile from, IncludableProfile to) {
    return _profiles[from.name].allRef.containsKey(to);
  }

  Iterable<Profile> directReferences(InclusiveProfile profile) {
    return _profiles[profile.name].directRef.keys;
  }

  Iterable<Profile> allReferences(InclusiveProfile profile) {
    return _profiles[profile.name].allRef.keys;
  }

  Iterable<Profile> referredBy(IncludableProfile profile) {
    return _profiles[profile.name].referredBy.keys;
  }

  // Some helpers for name-based references.
  void addReferenceByName(InclusiveProfile from, String to) {
    if (_renamingProfile) return;
    addReference(from, getProfileByName(to));
  }

  void removeReferenceByName(InclusiveProfile from, String to) {
    if (_renamingProfile) return;
    removeReference(from, getProfileByName(to));
  }

  bool hasReferenceToName(InclusiveProfile from, String to) =>
      hasReference(from, getProfileByName(to));

  void renameProfile(String oldName, String newName) {
    var profileData = _profiles.remove(oldName);
    if (profileData == null) return;
    // InclusiveProfiles may call addReference or removeReference upon
    // renaming. We just ignore the reference  modification requests until
    // the renaming is complete.
    _renamingProfile = true;

    for (var data in _profiles.values) {
      if (data.profile is InclusiveProfile && data.profile.name != oldName) {
        (data.profile as InclusiveProfile).renameProfile(oldName, newName);
      }
    }
    // Update the name of the profile data.
    profileData.profile.name = newName;
    _profiles[newName] = profileData;
    _renamingProfile = false;
  }
}

/**
 * Contains data needed for ProfileCollection implementation.
 */
class _ProfileData {
  Profile profile;
  CountMap<IncludableProfile> directRef = null;
  CountMap<IncludableProfile> allRef = null;
  CountMap<InclusiveProfile> referredBy = null;

  _ProfileData(this.profile) {
    referredBy = new CountMap<InclusiveProfile>();
    if (profile is InclusiveProfile) {
      directRef = new CountMap<IncludableProfile>();
      allRef = new CountMap<IncludableProfile>();
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

  Iterable<E> get keys => _count.keys;

  Iterable<int> get values => _count.values;

  int get length => _count.length;

  bool get isEmpty => _count.isEmpty;
}