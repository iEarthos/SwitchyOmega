abstract class HostCondition extends Condition {
  bool match(String url, String host, String scheme, Date datetime) =>
      matchHost(host);
  
  /**
   * Returns true if the [host] matches this condition.
   * False otherwise. 
   */
  abstract bool matchHost(String host);
}
