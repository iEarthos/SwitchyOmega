abstract class UrlCondition extends Condition {
  bool match(String url, String host, String scheme, Date datetime) =>
      matchUrl(url, scheme);
  
  /**
   * Returns true if the [url] matches this condition. False otherwise.
   * [scheme] is provided for faster speed. 
   */
  abstract bool matchUrl(String url, String scheme);
}
