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
class ProfileCollection extends Plainable implements Set<Profile> {
  Map<String, Profile> _profiles;

  /**
   * Returns the profile by its [name].
   */
  Profile getProfileByName(String name) {
    return _profiles[name];
  }

  /**
   * Returns the profile by its [name].
   */
  Profile operator [](String name) {
    return _profiles[name];
  }

  void _addPredefined() {
    this.add(new AutoDetectProfile());
    this.add(new DirectProfile());
    this.add(new SystemProfile());
  }

  void _setResolver(Profile p) {
    if (p is InclusiveProfile) {
      (p as InclusiveProfile).getProfileByName = this.getProfileByName;
    }
  }

  /**
   * Convert this collection to a list of plain profile objects.
   * Predefined profiles will not be included in the result.
   */
  List<Object> toPlain([List<Object> p, Object config]) {
    if (p == null) p = new List<Object>();
    p.addAll(_profiles.getValues().filter((prof) => !prof.predefined)
        .map((prof) => prof.toPlain()));

    return p;
  }

  ProfileCollection([Collection<Profile> profiles = null]) {
    _profiles = new Map<String, Profile>();
    _addPredefined();
    if (profiles != null) {
      this.addAll(profiles);
      profiles.forEach(_setResolver);
    }
  }

  void loadPlain(List<Object> p) {
    for (Map<String, Object> profile in p) {
      var pp = new Profile.fromPlain(profile);
      _setResolver(pp);
      this.add(pp);
    }
  }

  factory ProfileCollection.fromPlain(List<Object> p) {
    var c = new ProfileCollection();
    c.loadPlain(p);
    return c;
  }

  bool contains(Profile value) {
    return _profiles.containsKey(value.name);
  }

  void add(Profile value) {
    _profiles[value.name] = value;
    _setResolver(value);
  }

  /**
   * Remove [value] from this set if [value] is not predefined.
   */
  bool remove(Profile value) {
    if (value.predefined) return false;
    _profiles.remove(value.name);
  }

  void addAll(Collection<Profile> collection) {
    for (var p in collection) {
      _profiles[p.name] = p;
      _setResolver(p);
    }
  }

  /**
   * Remove all profiles of [collection] from this profile, expect
   * the predefined ones.
   */
  void removeAll(Collection<Profile> collection) {
    for (var p in collection) {
      if (!p.predefined) _profiles.remove(p.name);
    }
  }

  bool isSubsetOf(Collection<Profile> other) {
    return new Set<Profile>.from(other).containsAll(this);
  }

  bool containsAll(Collection<Profile> collection) {
    return collection.every(bool _(Profile value) {
      return contains(value);
    });
  }

  Set<Profile> intersection(Collection<Profile> collection) {
    Set<Profile> result = new Set<Profile>();
    collection.forEach(void _(Profile value) {
      if (contains(value)) result.add(value);
    });
    return result;
  }

  /**
   * This method doesn't really clear all profiles, because predefined
   * profiles cannot be removed.
   */
  void clear() {
    _profiles.clear();
    _addPredefined();
  }

  void forEach(void f(Profile element)) {
    _profiles.forEach(void _(String key, Profile value) {
      f(value);
    });
  }

  Set map(f(Profile element)) {
    Set result = new Set();
    _profiles.forEach(void _(String key, Profile value) {
      result.add(f(value));
    });
    return result;
  }

  Set<Profile> filter(bool f(Profile element)) {
    Set<Profile> result = new Set<Profile>();
    _profiles.forEach(void _(String key, Profile value) {
      if (f(value)) result.add(value);
    });
    return result;
  }

  bool every(bool f(Profile element)) {
    Collection<Profile> keys = _profiles.getValues();
    return keys.every(f);
  }

  bool some(bool f(Profile element)) {
    Collection<Profile> keys = _profiles.getValues();
    return keys.some(f);
  }

  bool isEmpty() {
    return _profiles.isEmpty();
  }

  int get length {
    return _profiles.length;
  }

  Iterator<Profile> iterator() {
    return _profiles.getValues().iterator();
  }

  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic previousValue, Profile element)) {
    _profiles.getValues().reduce(initialValue, combine);
  }
}
