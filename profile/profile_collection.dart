/**
 * A set of profiles. Predefined profiles are pre-added to the set,
 * but they are not converted to plain.
 */
class ProfileCollection extends Plainable implements Set<Profile> {
  Map<String, Profile> _profiles;
  
  /**
   * A plain option map which tells objects to use profile names instead of
   * profiles.
   */
  static final Map<String, bool> profileNameOnly = 
      const { 'profileNameOnly' : true };
  
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

  void _dumpProfilesTo(List<Object> list, Set<Profile> profiles) {
    var it = profiles.iterator();
    while (it.hasNext()) {
      var first = it.next();
      if (first is InclusiveProfile) {
        InclusiveProfile p = first; // CAST
        var h = profiles.intersection(new HashSet.from(p.getProfiles()));
        profiles.removeAll(h);
        _dumpProfilesTo(list, h);
      }
      list.add(first.toPlain(null, profileNameOnly));
      profiles.remove(first);
      it = profiles.iterator();
    }
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
    _dumpProfilesTo(p, new HashSet.from(
      _profiles.getValues().filter((prof) => !prof.predefined)));
    
    return p;
  }
  
  ProfileCollection([Collection<Profile> profiles = null]) {
    _profiles = new Map<String, Profile>();
    _addPredefined();
    if (profiles != null) {
      this.addAll(profiles);
    }
  }
  
  factory ProfileCollection.fromPlain(List<Object> p, [Object config]) {
    var c = new ProfileCollection();
    var config = { 'profileResolver' : c.getProfileByName };
    for (var profile in p) {
      c.add(new Profile.fromPlain(profile, config));
    }
    
    return c;
  }

  bool contains(Profile value) {
    return _profiles.containsKey(value.name);
  }

  void add(Profile value) {
    _profiles[value.name] = value;
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

  int get length() {
    return _profiles.length;
  }

  Iterator<Profile> iterator() {
    return _profiles.getValues().iterator();
  }
}
