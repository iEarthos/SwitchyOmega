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
 * Selects the result profile of the first matching [Rule],
 * or the [defaultProfile] if no rule matches.
 */
class SwitchProfile extends InclusiveProfile implements List<Rule> {
  String get profileType => 'SwitchProfile';

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
  String get defaultProfileName => _defaultProfileName;
  void set defaultProfile(String value) {
    _refCount.remove(_defaultProfileName);
    _addReference(value);
    _defaultProfileName = value;
  }

  bool containsProfileName(String name) {
    return _refCount.containsKey(name);
  }

  List<String> getProfileNames() {
    return _refCount.keys.toList();
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
      if (rule.condition.match(url, host, scheme, datetime)) {
        return rule.profileName;
      }
    }
    return defaultProfileName;
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['defaultProfileName'] = defaultProfileName;
    p['rules'] = this.mappedBy((r) => r.toPlain()).toList();

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
    this.addAll(rl.mappedBy((r) => new Rule.fromPlain(r)));
  }

  factory SwitchProfile.fromPlain(Map<String, Object> p) {
    var f = new SwitchProfile(p['name'], p['defaultProfileName'], p['resolver']);
    f.loadPlain(p);
    return f;
  }

  int get length => _rules.length;

  void set length(int newLength) {
    _rules.length = newLength;
  }

  void forEach(void f(Rule element)) {
    _rules.forEach(f);
  }
  
  Rule get first => this[0];

  Iterable<Rule> mappedBy(f(Rule element)) => _rules.mappedBy(f);

  Iterable<Rule> where(bool f(Rule element))  => _rules.where(f);

  bool every(bool f(Rule element)) => _rules.every(f);

  bool any(bool f(Rule element)) => _rules.any(f);

  bool get isEmpty => _rules.isEmpty;

  Iterator<Rule> get iterator => _rules.iterator;

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

  bool contains(Rule element) {
    for (Rule e in this) {
      if (e == element) return true;
    }
    return false;
  }

  void sort([Comparator<Rule> compare]) {
    _rules.sort(compare);
  }

  int indexOf(Rule element, [int start = 0]) {
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

  Rule removeAt(int index) {
    var rule = _rules.removeAt(index);
    _removeReference(rule.profileName);
    return rule;
  }

  Rule get last => _rules.last;

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

  dynamic reduce(dynamic initialValue,
                 dynamic combine(dynamic previousValue, Rule element)) {
    _rules.reduce(initialValue, combine);
  }
  
  void remove(Rule r) {
    this.removeMatching((e) => e == r);
  }
  
  void removeAll(Iterable<dynamic> w) {
    
  }
  void retainAll(Iterable<dynamic> d) {}
  
  void removeMatching(bool test(Rule element)) {
    for (var i = 0; i < this.length; i++) {
      if (test(this[i])) {
        this.removeAt(i);
        return;
      }
    }
  }
  
  void retainMatching(bool test(Rule element)) {
    this.removeMatching((e) => !test(e));
  }
  
  // Note: The following members are copied from dart:core because I know no
  // better way to implement all the members.

  /**
   * Convert each element to a [String] and concatenate the strings.
   *
   * Converts each element to a [String] by calling [Object.toString] on it.
   * Then concatenates the strings, optionally separated by the [separator]
   * string.
   */
  String join([String separator]) {
    Iterator<Rule> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = new StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.add("${iterator.current}");
      } while (iterator.moveNext());
    } else {
      buffer.add("${iterator.current}");
      while (iterator.moveNext()) {
        buffer.add(separator);
        buffer.add("${iterator.current}");
      }
    }
    return buffer.toString();
  }

  List<Rule> toList() => new List<Rule>.from(this);
  Set<Rule> toSet() => new Set<Rule>.from(this);

  /**
   * Find the least element in the iterable.
   *
   * Returns null if the iterable is empty.
   * Otherwise returns an element [:x:] of this [Iterable] so that
   * [:x:] is not greater than [:y:] (that is, [:compare(x, y) <= 0:]) for all
   * other elements [:y:] in the iterable.
   *
   * The [compare] function must be a proper [Comparator<T>]. If a function is
   * not provided, [compare] defaults to [Comparable.compare].
   */
  Rule min([int compare(Rule a, Rule b)]) {
    if (compare == null) throw new ArgumentError("compare must be provided.");
    Iterator it = iterator;
    if (!it.moveNext()) return null;
    Rule min = it.current;
    while (it.moveNext()) {
      Rule current = it.current;
      if (compare(min, current) > 0) min = current;
    }
    return min;
  }

  /**
   * Find the largest element in the iterable.
   *
   * Returns null if the iterable is empty.
   * Otherwise returns an element [:x:] of this [Iterable] so that
   * [:x:] is not smaller than [:y:] (that is, [:compare(x, y) >= 0:]) for all
   * other elements [:y:] in the iterable.
   *
   * The [compare] function must be a proper [Comparator<T>]. If a function is
   * not provided, [compare] defaults to [Comparable.compare].
   */
  Rule max([int compare(Rule a, Rule b)]) {
    if (compare == null) throw new ArgumentError("compare must be provided.");
    Iterator it = iterator;
    if (!it.moveNext()) return null;
    Rule max = it.current;
    while (it.moveNext()) {
      Rule current = it.current;
      if (compare(max, current) < 0) max = current;
    }
    return max;
  }

  /**
   * Returns an [Iterable] with at most [n] elements.
   *
   * The returned [Iterable] may contain fewer than [n] elements, if [this]
   * contains fewer than [n] elements.
   */
  Iterable<Rule> take(int n) {
    return new TakeIterable<Rule>(this, n);
  }

  /**
   * Returns an [Iterable] that stops once [test] is not satisfied anymore.
   *
   * The filtering happens lazily. Every new [Iterator] of the returned
   * [Iterable] will start iterating over the elements of [this].
   * When the iterator encounters an element [:e:] that does not satisfy [test],
   * it discards [:e:] and moves into the finished state. That is, it will not
   * ask or provide any more elements.
   */
  Iterable<Rule> takeWhile(bool test(Rule value)) {
    return new TakeWhileIterable<Rule>(this, test);
  }

  /**
   * Returns an [Iterable] that skips the first [n] elements.
   *
   * If [this] has fewer than [n] elements, then the resulting [Iterable] will
   * be empty.
   */
  Iterable<Rule> skip(int n) {
    return new SkipIterable<Rule>(this, n);
  }

  /**
   * Returns an [Iterable] that skips elements while [test] is satisfied.
   *
   * The filtering happens lazily. Every new [Iterator] of the returned
   * [Iterable] will iterate over all elements of [this].
   * As long as the iterator's elements do not satisfy [test] they are
   * discarded. Once an element satisfies the [test] the iterator stops testing
   * and uses every element unconditionally.
   */
  Iterable<Rule> skipWhile(bool test(Rule value)) {
    return new SkipWhileIterable<Rule>(this, test);
  }

  /**
   * Returns the single element in [this].
   *
   * If [this] is empty or has more than one element throws a [StateError].
   */
  Rule get single {
    Iterator it = iterator;
    if (!it.moveNext()) throw new StateError("No elements");
    Rule result = it.current;
    if (it.moveNext()) throw new StateError("More than one element");
    return result;
  }

  /**
   * Returns the first element that satisfies the given predicate [f].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is `null`, a [StateError] is
   * thrown.
   */
  Rule firstMatching(bool test(Rule value), { Rule orElse() }) {
    // TODO(floitsch): check that arguments are of correct type?
    for (Rule element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  /**
   * Returns the last element that satisfies the given predicate [f].
   *
   * If none matches, the result of invoking the [orElse] function is
   * returned. By default, when [orElse] is [:null:], a [StateError] is
   * thrown.
   */
  Rule lastMatching(bool test(Rule value), {Rule orElse()}) {
    // TODO(floitsch): check that arguments are of correct type?
    Rule result = null;
    bool foundMatching = false;
    for (Rule element in this) {
      if (test(element)) {
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw new StateError("No matching element");
  }

  /**
   * Returns the single element that satisfies [f]. If no or more than one
   * element match then a [StateError] is thrown.
   */
  Rule singleMatching(bool test(Rule value)) {
    // TODO(floitsch): check that argument is of correct type?
    Rule result = null;
    bool foundMatching = false;
    for (Rule element in this) {
      if (test(element)) {
        if (foundMatching) {
          throw new StateError("More than one matching element");
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    throw new StateError("No matching element");
  }

  /**
   * Returns the [index]th element.
   *
   * If [this] [Iterable] has fewer than [index] elements throws a
   * [RangeError].
   *
   * Note: if [this] does not have a deterministic iteration order then the
   * function may simply return any element without any iteration if there are
   * at least [index] elements in [this].
   */
  Rule elementAt(int index) {
    if (index is! int || index < 0) throw new RangeError.value(index);
    int remaining = index;
    for (Rule element in this) {
      if (remaining == 0) return element;
      remaining--;
    }
    throw new RangeError.value(index);
  }
}

