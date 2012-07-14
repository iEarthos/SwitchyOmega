/**
 * Matches when the url matches the wildcard [pattern].
 */
class UrlWildcardCondition extends UrlCondition {
  final String conditionType = 'UrlWildcardCondition';

  String _pattern;
  String get pattern() => _pattern;
  void set pattern(String value) {
    _pattern = value;
    _regex = null;
    _recorder = null;
  }
  
  RegExp _regex;
  CodeWriterRecorder _recorder;
  
  bool matchUrl(String url, scheme) {
    if (_regex == null) _regex = new RegExp(shExp2RegExp(_pattern, trimAsterisk: true));
    return _regex.hasMatch(url);
  }
  
  static final schemeOnlyPattern = const RegExp(@'^(\w+)://\*$');
  
  void writeTo(CodeWriter w) {
    if (_recorder == null) {
      _recorder = new CodeWriterRecorder();
      _recorder.inner = w;
      
      Match m;
      if ((m = schemeOnlyPattern.firstMatch(_pattern)) != null) {
        _recorder.inline('scheme === ${JSON.stringify(m[1])}');
      } else {
        // TODO(catus): use shExpCompile
        var regex = shExp2RegExp(_pattern, trimAsterisk: true);
        w.inline('new RegExp(${JSON.stringify(regex)}).test(url)');
        // shExpCompile(_pattern, _recorder, target: 'url');
      }
      _recorder.inner = null;
    } else {
      _recorder.replay(w);
    }
  }
  
  UrlWildcardCondition([String pattern = '']) {
    this._pattern = pattern;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['pattern'] = this.pattern;
    return p;
  }
  
  factory UrlWildcardCondition.fromPlain(Map<String, Object> p, 
      [Object config]) {
    return new UrlWildcardCondition(p['pattern']);
  }
}
