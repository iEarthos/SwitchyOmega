/**
 * Handles communication with the browser and other browser related stuff.
 */ 
abstract class Browser {
  abstract AsyncStorage get storage;
  abstract Future applyProfile(Profile profile);
}

/**
 * Provide a [Future]-based interface for accessing a storage.
 */
abstract class AsyncStorage {
  abstract Future<Map<String, Object>> retive(List<String> names);
  abstract Future put(Map<String, Object> map);
  abstract Future remove(List<String> names);
}