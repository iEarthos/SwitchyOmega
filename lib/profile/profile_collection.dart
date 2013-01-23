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
class ProfileCollection extends Collection<Profile>
    implements Set<Profile>, Plainable {
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
    p.addAll(_profiles.values.where((prof) => !prof.predefined)
        .mappedBy((prof) => prof.toPlain()));

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
  
  /**
   * This method doesn't really clear all profiles, because predefined
   * profiles cannot be removed.
   */
  void clear() {
    _profiles.clear();
    _addPredefined();
  }

  int get length {
    return _profiles.length;
  }

  Iterator<Profile> get iterator {
    return _profiles.values.iterator;
  }

  bool isSubsetOf(Collection<Profile> collection) {
    return new Set<Profile>.from(collection).containsAll(this);
  }
  
  bool containsAll(Collection<Profile> collection) {
    return collection.every((e) => this.contains(e));
  }
  
  Set<Profile> intersection(Collection<Profile> collection) {
    return new Set<Profile>.from(collection.where((e) => this.contains(e)));
  }
  
  Object toJson() {
    return this.toPlain();
  }
}
