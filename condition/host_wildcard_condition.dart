/**
 * Matches when the host matches the wildcard [pattern].
 * Magic happens to the [pattern], see
 * <https://github.com/FelisCatus/SwitchyOmega/wiki/Host-wildcard-condition>.
 */
class HostWildcardCondition extends HostCondition {
  final String conditionType = 'HostWildcardCondition';

  String _pattern;
  String get pattern() => _pattern;
  void set pattern(String value) {
    _pattern = value;
    _regex = null;
    _recorder = null;
  }
  
  bool _magic_subdomain = false;
  RegExp _regex;
  CodeWriterRecorder _recorder;
  
  /**
   * Get the magical regex of this pattern. See 
   * <https://github.com/FelisCatus/SwitchyOmega/wiki/Host-wildcard-condition>
   * for the magic.
   */
  String magicRegex() {
    if (_pattern.startsWith('**.')) {
      return shExp2RegExp(_pattern.substring(1), trimAsterisk: true);
    } else if (_pattern.startsWith('*.')) {
      return shExp2RegExp(_pattern.substring(2), trimAsterisk: true)
          .replaceFirst('^', @'(^|\.)');
    }
    
    return shExp2RegExp(_pattern, trimAsterisk: true);
  }
  
  bool matchHost(String host) {
    if (_regex == null) _regex = new RegExp(magicRegex());
    
    return _regex.hasMatch(host);
  }
  
  void writeTo(CodeWriter w) {
    if (_recorder == null) {
      _recorder = new CodeWriterRecorder();
      _recorder.inner = w;
      
      // TODO(catus): use shExpCompile
      w.inline('new RegExp(${JSON.stringify(magicRegex())}).test(host)');
      // shExpCompile(_pattern, _recorder, target: 'host');
      
      _recorder.inner = null;
    } else {
      _recorder.replay(w);
    }
  }
  
  HostWildcardCondition([String pattern = '']) {
    this._pattern = pattern;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['pattern'] = this.pattern;
    return p;
  }
  
  factory HostWildcardCondition.fromPlain(Map<String, Object> p, 
      [Object config]) {
    return new HostWildcardCondition(p['pattern']);
  }
}
