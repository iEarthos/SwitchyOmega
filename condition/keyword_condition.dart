/**
 * Matches if the scheme of the url is 'http' and the [pattern] is a 
 * substring of the [url].
 */
class KeywordCondition extends UrlCondition {
  final String conditionType = 'KeywordCondition';

  String pattern;
  
  bool matchUrl(String url, scheme) {
    return scheme == 'http' && url.contains(pattern);
  }
  
  void writeTo(CodeWriter w) {
    w.inline("scheme === 'http' && url.indexOf(${JSON.stringify(pattern)}) >= 0");
  }
  
  KeywordCondition([this.pattern = '']);
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['pattern'] = this.pattern;
    return p;
  }
  
  factory KeywordCondition.fromPlain(Map<String, Object> p, [Object config]) {
    return new KeywordCondition(p['pattern']);
  }
}