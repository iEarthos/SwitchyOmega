/**
 * Matches when the host matches the [regex] [pattern].
 */
class HostRegexCondition extends HostCondition {
  final String conditionType = 'HostRegexCondition';

  RegExp regex;
  
  /** Get the pattern of the [regex]. */
  String get pattern() => regex.pattern;
  
  /** Set the [regex] to a new [RegExp] with a pattern of [value]. */
  void set pattern(String value) { regex = new RegExp(value); }
  
  bool matchHost(String host) {
    return regex.hasMatch(host);
  }
  
  void writeTo(CodeWriter w) {
    w.inline('new RegExp(${JSON.stringify(regex.pattern)}).test(host)');
  }
  
  HostRegexCondition([Object regex = '']) {
    this.regex = (regex is String) ? new RegExp(regex) : regex;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['pattern'] = this.pattern;
    return p;
  }
  
  factory HostRegexCondition.fromPlain(Map<String, Object> p, [Object config])
    => new HostRegexCondition(p['pattern']);
}
