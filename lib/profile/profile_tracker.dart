part of switchy_profile;

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
