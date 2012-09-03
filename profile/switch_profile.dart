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
 * Selects the result profile of the first matching [Rule],
 * or the [defaultProfile] if no rule matches.
 */
class SwitchProfile extends InclusiveProfile implements List<Rule> {
  String get profileType() => 'SwitchProfile';
  
  List<Rule> _rules;
  
  Map<String, int> _refCount;

  void _addReference(String name) {
    _refCount[name] = ifNull(_refCount[name], 0) + 1;
  }

  void _removeReference(String name) {
    var c = _refCount[name];
    if (c > 1) {
      _refCount[name] = c - 1;
    } else {
      _refCount.remove(name);
    }
  }
  
  String _defaultProfileName;
  String get defaultProfileName() => _defaultProfileName;
  void set defaultProfile(String value) {
    _refCount.remove(_defaultProfileName);
    _addReference(value);
    _defaultProfileName = value;
  }

  bool containsProfileName(String name) {
    return _refCount.containsKey(name);
  }
  
  List<String> getProfileNames() {
    return _refCount.getKeys();
  }
  
  void writeTo(CodeWriter w) {
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");
    
    for (var rule in _rules) {
      w.inline('if (');
      rule.condition.writeTo(w);
      w.code(')').indent();
      IncludableProfile ip = getProfileByName(rule.profileName);
      w.code('return ${ip.getScriptName()};')
       .outdent();
    }
    
    IncludableProfile dp = getProfileByName(defaultProfileName);
    w.code('return ${dp.getScriptName()};');
    w.inline('}');
  }

  String choose(String url, String host, String scheme, Date datetime) {
    for (var rule in _rules) {
      if (rule.condition.match(url, host, scheme, datetime))
        return rule.profileName;
    }
    return defaultProfileName;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['defaultProfileName'] = defaultProfileName;
    p['rules'] = this.map((r) => r.toPlain());
    
    return p;
  }
  
  SwitchProfile(String name, String defaultProfileName, ProfileResolver resolver)
      : super(name, resolver) {
    this._refCount = new Map<String, int>();
    this._defaultProfileName = defaultProfileName;
    _addReference(_defaultProfileName);
    this._rules = <Rule>[];
  }
  
  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    var rl = p['rules'] as List<Map<String, Object>>;
    this.addAll(rl.map((r) => new Rule.fromPlain(r)));
  }
  
  factory SwitchProfile.fromPlain(Map<String, Object> p) {
    var f = new SwitchProfile(p['name'], p['defaultProfileName'], p['resolver']);
    f.loadPlain(p);
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
    _addReference(value.profileName);
    if (index < _rules.length) _removeReference(_rules[index].profileName);
    _rules[index] = value;
  }

  void add(Rule value) {
    _addReference(value.profileName);
    _rules.add(value);
  }

  void addLast(Rule value) {
    _addReference(value.profileName);
    _rules.addLast(value);
  }

  void addAll(Collection<Rule> collection) {
    for (var rule in collection) {
      _addReference(rule.profileName);
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
    _addReference(defaultProfileName);
  }

  Rule removeLast() {
    var rule = _rules.removeLast();
    _removeReference(rule.profileName);
    return rule;
  }

  Rule last() => _rules.last();

  List<Rule> getRange(int start, int length) => _rules.getRange(start, length);

  void setRange(int start, int length, List<Rule> from, [int startFrom = 0]) {
    for(var rule in _rules.getRange(start, length)) {
      _removeReference(rule.profileName);
    }
    for (var i = startFrom; i < from.length; i++) {
      _addReference(from[i].profileName);
    }
    _rules.setRange(start, length, from, startFrom);
  }

  void removeRange(int start, int length) {
    for(var rule in _rules.getRange(start, length)) {
      _removeReference(rule.profileName);
    }
    _rules.removeRange(start, length);
  }

  void insertRange(int start, int length, [Rule initialValue]) {
     if (initialValue != null) _addReference(initialValue.profileName);
     _rules.insertRange(start, length);
  }
  
  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic previousValue, Rule element)) {
    _rules.reduce(initialValue, combine); 
  }
}

