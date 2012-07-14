/**
 * Selects the result profile of the first matching [Rule],
 * or the [defaultProfile] if no rule matches.
 */
class SwitchProfile extends InclusiveProfile implements List<Rule> {
  String get profileType() => 'SwitchProfile';
  
  List<Rule> _rules;
  
  Map<IncludableProfile, int> _refCount;

  void _addReference(IncludableProfile p) {
    if (p is InclusiveProfile) {
      InclusiveProfile sp = p; // CAST
      if (sp.containsProfile(this)) {
        throw new CircularReferenceException(this, sp);
      }
      for (var pp in sp.getProfiles()) {
        _refCount[pp] = ifNull(_refCount[pp], 0) + 1;
      }
    }
    _refCount[p] = ifNull(_refCount[p], 0) + 1;
  }

  void _releaseRef(IncludableProfile p) {
    var c = _refCount[p];
    if (c > 1) {
      _refCount[p] = c - 1;
    } else {
      _refCount.remove(p);
    }
  }
  
  void _removeReference(IncludableProfile p) {
    if (p is InclusiveProfile) {
      InclusiveProfile sp = p; // CAST
      for (var pp in sp.getProfiles()) {
        _releaseRef(pp);
      }
    }
    _releaseRef(p);
  }
  
  IncludableProfile _defaultProfile;
  IncludableProfile get defaultProfile() => _defaultProfile;
  void set defaultProfile(IncludableProfile value) {
    _addReference(value);
    _refCount.remove(_defaultProfile);
    _defaultProfile = value;
  }

  bool containsProfile(IncludableProfile p) {
    return _refCount.containsKey(p);
  }
  
  List<IncludableProfile> getProfiles() {
    return _refCount.getKeys();
  }
  
  void writeTo(CodeWriter w) {
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");
    
    for (var rule in _rules) {
      w.inline('if (');
      rule.condition.writeTo(w);
      w.code(')').indent()
       .code('return ${rule.profile.getScriptName()};')
       .outdent();
    }
    
    w.code('return ${defaultProfile.getScriptName()};');
    w.inline('}');
  }

  Profile choose(String url, String host, String scheme, Date datetime) {
    for (var rule in _rules) {
      if (rule.condition.match(url, host, scheme, datetime))
        return rule.profile;
    }
    return defaultProfile;
  }
  
  /**
   * [:config['profileNameOnly']:] can be set to true for writing
   * [defaultProfile.name] as defaultProfileName instead of the whole profile.
   * This config is also applied to all rules.
   */
  Map<String, Object> toPlain([Map<String, Object> p, Map<String, Object> config]) {
    p = super.toPlain(p, config);
    if (config != null && config['profileNameOnly'] != null) {
      p['defaultProfileName'] = defaultProfile.name;
    } else {
      p['defaultProfile'] = defaultProfile.toPlain(null, config);
    }
    p['rules'] = this.map((r) => r.toPlain(null, config));
    
    return p;
  }
  
  SwitchProfile(String name, IncludableProfile defaultProfile)
      : super(name) {
    this._refCount = new Map<IncludableProfile, int>();
    _defaultProfile = defaultProfile;
    _addReference(_defaultProfile);
    this._rules = <Rule>[];
  }
  
  /**
   * If [:p['defaultProfileName']:] is used instead of [:p['defaultProfile']:],
   * [:config['profileResolver']:] must be set to a [ProfileResolver].
   */
  factory SwitchProfile.fromPlain(Map<String, Object> p, 
    [Map<String, Object> config]) {
    var prof = p['defaultProfile'];
    var dp = null;
    if (prof == null) {
      ProfileResolver resolver = config['profileResolver']; // CAST
      dp = resolver(p['defaultProfileName']);
    } else {
      dp = new Profile.fromPlain(prof, config);
    }
    var f = new SwitchProfile(p['name'], dp);
    f.color = p['color'];
    List<Rule> rl = p['rules']; // CAST
    f.addAll(rl.map((r) => new Rule.fromPlain(r, config)));
    
    return f;
  }

  int get length() => _rules.length;

  void set length(int newLength) {
    _rules.length = newLength;
  }

  void forEach(void f(Rule element)) {
    _rules.forEach(f);
  }

  Collection map(f(Rule element)) => _rules.map(f);

  Collection<Rule> filter(bool f(Rule element))  => _rules.filter(f);

  bool every(bool f(Rule element)) => _rules.every(f);

  bool some(bool f(Rule element)) => _rules.some(f);

  bool isEmpty() => _rules.isEmpty();

  Iterator<Rule> iterator() => _rules.iterator();

  Rule operator [](int index) => _rules[index];

  void operator []=(int index, Rule value) {
    _addReference(value.profile);
    if (index < _rules.length) _refCount.remove(_rules[index].profile);
    _rules[index] = value;
  }

  void add(Rule value) {
    _addReference(value.profile);
    _rules.add(value);
  }

  void addLast(Rule value) {
    _addReference(value.profile);
    _rules.addLast(value);
  }

  void addAll(Collection<Rule> collection) {
    for (var rule in collection) {
      _addReference(rule.profile);
    }
    _rules.addAll(collection);
  }

  void sort(int compare(Rule a, Rule b)) {
    _rules.sort(compare);
  }

  int indexOf(Rule element, [int start]) {
    return _rules.indexOf(element, start);
  }

  int lastIndexOf(Rule element, [int start]) {
    _rules.lastIndexOf(element, start);
  }

  void clear() {
    _rules.clear();
    _refCount.clear();
    _addReference(_defaultProfile);
  }

  Rule removeLast() {
    var rule = _rules.removeLast();
    _removeReference(rule.profile);
    return rule;
  }

  Rule last() => _rules.last();

  List<Rule> getRange(int start, int length) => _rules.getRange(start, length);

  void setRange(int start, int length, List<Rule> from, [int startFrom]) {
    for(var rule in _rules.getRange(start, length)) {
      _removeReference(rule.profile);
    }
    for (var rule in from) {
      _addReference(rule.profile);
    }
    _rules.setRange(start, length, from, startFrom);
  }

  void removeRange(int start, int length) {
    for(var rule in _rules.getRange(start, length)) {
      _removeReference(rule.profile);
    }
    _rules.removeRange(start, length);
  }

  void insertRange(int start, int length, [Rule initialValue]) {
     if (initialValue != null) _addReference(initialValue.profile);
     _rules.insertRange(start, length);
  }
}

/**
 * Thrown when a circular reference of two [InclusiveProfile]s is detected.
 */
class CircularReferenceException implements Exception {
  final InclusiveProfile parent;
  final InclusiveProfile result;

  CircularReferenceException(this.parent, this.result);

  String toString() => 'Profile "${result.name}" cannot be configured as a '
                       'result profile of Profile "${parent.name}", because it'
                       'references Profile "${parent.name}", directly or indirectly.';
}

