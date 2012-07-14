/**
 * Matches when the number of dots in the host is within the range
 * [minValue](inclusive) ~ [maxValue](inclusive).
 */
class HostLevelsCondition extends HostCondition {
  final String conditionType = 'HostLevelsCondition';

  /** Cache the charCode of '.' for greater speed. */
  static final int dotCharCode = 46;
  
  int maxValue = 0;
  int minValue = 0;
  
  bool matchHost(String host) {
    int dotCount = 0;
    for (var i = 0; i < host.length; i++) {
      if (host.charCodeAt(i) == dotCharCode) {
        dotCount++;
        if (dotCount > maxValue) return false;
      }
    }
    return dotCount >= minValue;
  }
  
  void writeTo(CodeWriter w) {
    if (maxValue == minValue) {
      w.inline("host.split('.').length - 1 === $minValue");
    } else {
      w.inline('(function (a) { return a >= $minValue && a <= $maxValue; })'
             "(host.split('.').length - 1)");
    }
  }
  
  HostLevelsCondition([this.minValue = 0, this.maxValue = 0]);
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['minValue'] = this.minValue;
    p['maxValue'] = this.maxValue;
    return p;
  }
  
  factory HostLevelsCondition.fromPlain(Map<String, Object> p, [Object config]) {
    return new HostLevelsCondition(p['minValue'], p['maxValue']);
  }
}
