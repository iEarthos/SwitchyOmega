part of switchy_browser;

/**
 * Handles communication with the browser and other browser related stuff.
 */
abstract class Browser {
  AsyncStorage get storage;
  Future applyProfile(Profile profile);
}

/**
 * Provide a [Future]-based interface for accessing a storage.
 */
abstract class AsyncStorage {
  Future<Map<String, Object>> retive(List<String> names);
  Future put(Map<String, Object> map);
  Future remove(List<String> names);
}