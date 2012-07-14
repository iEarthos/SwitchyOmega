/**
 * Matches when the url matches the [regex].
 */
class UrlRegexCondition extends UrlCondition {
  final String conditionType = 'UrlRegexCondition';

  RegExp regex;
  
  /** Get the pattern of the [regex]. */
  String get pattern() => regex.pattern;
  
  /** Set the [regex] to a new [RegExp] with a pattern of [value]. */
  void set pattern(String value) { regex = new RegExp(value); }
  
  bool matchUrl(String url, scheme) {
    return regex.hasMatch(url);
  }
  
  void writeTo(CodeWriter w) {
    w.inline('new RegExp(${JSON.stringify(regex.pattern)}).test(url)');
  }
  
  UrlRegexCondition([Object regex = '']) {
    this.regex = (regex is String) ? new RegExp(regex) : regex;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['pattern'] = this.pattern;
    return p;
  }
  
  factory UrlRegexCondition.fromPlain(Map<String, Object> p, [Object config]) {
    return new UrlRegexCondition(p['pattern']);
  }
}
