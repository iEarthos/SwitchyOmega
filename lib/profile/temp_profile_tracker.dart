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
 * A [TempProfileTracker] resolves profile names to profiles using the [inner]
 * tracker. It tracks the references of profiles locally, avoid
 * modifications to the [inner] tracker.
 */
class TempProfileTracker extends ProfileTracker {
  @reflectable final ProfileTracker inner;

  TempProfileTracker(this.inner);

  final CountMap<String> _references = new CountMap<String>();

  Profile getProfileByName(String name) => inner.getProfileByName(name);

  void addReference(InclusiveProfile from, IncludableProfile to) {
    _references.increase(to.name);
  }

  void removeReference(InclusiveProfile from, IncludableProfile to) {
    _references.decrease(to.name);
  }

  bool hasReference(InclusiveProfile from, IncludableProfile to) => true;

  Iterable<IncludableProfile> directReferences(InclusiveProfile profile) {
    return _references.keys.map(getProfileByName);
  }

  Iterable<IncludableProfile> allReferences(InclusiveProfile profile) {
    var result = new Set<IncludableProfile>();
    for (var p in directReferences(profile)) {
      result.add(p);
      if (p is InclusiveProfile) {
        result.addAll(inner.allReferences(p));
      }
    }
    return result;
  }

  Iterable<InclusiveProfile> referredBy(IncludableProfile profile) => [];
}