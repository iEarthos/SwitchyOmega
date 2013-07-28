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
 * A [ProfileTracker] resolves profile names to profiles and tracks references
 * of the profiles.
 */
abstract class ProfileTracker {
  Profile getProfileByName(String name);

  void addReference(InclusiveProfile from, IncludableProfile to);

  void removeReference(InclusiveProfile from, IncludableProfile to);

  bool hasReference(InclusiveProfile from, IncludableProfile to);

  Iterable<Profile> directReferences(InclusiveProfile profile);

  Iterable<Profile> allReferences(InclusiveProfile profile);

  Iterable<Profile> referredBy(IncludableProfile profile);

  // Some helpers for name-based references.
  void addReferenceByName(InclusiveProfile from, String to) {
    addReference(from, getProfileByName(to));
  }

  void removeReferenceByName(InclusiveProfile from, String to) {
    removeReference(from, getProfileByName(to));
  }

  bool hasReferenceToName(InclusiveProfile from, String to) =>
      hasReference(from, getProfileByName(to));
}

/**
 * Thrown when a circular reference of two [InclusiveProfile]s is detected.
 */
class CircularReferenceException implements Exception {
  /**
   * The profile that has a reference to [result].
   */
  final InclusiveProfile parent;

  /**
   * Adding [result] to [parent] fails due to a [CircularReferenceException].
   */
  final InclusiveProfile result;

  CircularReferenceException(this.parent, this.result);

  String toString() =>
      'Profile "${result.name}" cannot be configured as a result profile of '
      'Profile "${parent.name}", because it contains Profile "${parent.name}"'
      ', directly or indirectly.';
}
