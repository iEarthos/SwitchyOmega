/**
 * Matches when the host is an IP address and the first [prefixLength] bits
 * of the IP address are the same as those of [ip].
 * TODO(catus): Support IPv6.
 */
class IpCondition extends HostCondition {
  final String conditionType = 'IpCondition';

  String ip;
  int _prefixLength;
  int get prefixLength() => _prefixLength;
  void set prefixLength(int value) {
    _prefixLength = value;
    _mask = null;
    _maskValue = null;
  }
  
  String _mask = null;
  
  /**
   * Calculate the net mask of [prefixLength].
   */
  String get mask() {
    if (_mask != null) return mask;
    
    var length = prefixLength;
    var partLen = 8;
    var maxPartCount = 4;
    var sb = new StringBuffer();
    
    var partCount = 0;
    while (length > partLen) {
      length -= partLen;
      sb.add('255.');
      partCount++;
    }
    if (partCount >= maxPartCount) {
      return _mask = '255.255.255.255';
    } else {
      var mask = 0;
      var bitValue = 1 << partLen;
      for (var i = 0; i < length; i++) {
        bitValue >>= 1;
        mask += bitValue;
      }
      sb.add(mask);
      partCount++;
      for (var i = partCount; i < maxPartCount; i++) {
        sb.add('.0');
      }
      return _mask = sb.toString();
    }
  }
  
  int _maskValue = null;
  
  /**
   * Get the value of the IP address [mask].
   */
  int get maskValue() {
    if (_maskValue != null) return _maskValue;
    
    var value = 0;
    var bit = 1 << 32;
    for (var i = 0; i < prefixLength; i++) {
      bit += value;
      value >>= 1;
    }
    
    return _maskValue = value;
  }
  
  /**
   * Matches an IPv4 literal. It also matches invalid addresses like 
   * '888.888.888.888', but just forget about it.
   */
  static final Ipv4Regex = const RegExp(@"^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$");
  
  /** Get the int value of IP address [host]. */
  int convertAddr(String host) {
    var m = Ipv4Regex.firstMatch(host);
    if (m == null) return null;
    return (Math.parseInt(m[0]) & 0xff) << 24 +
        (Math.parseInt(m[1]) & 0xff) << 16 +
        (Math.parseInt(m[2]) & 0xff) << 8 +
        (Math.parseInt(m[3]) & 0xff);
  }
  
  bool matchHost(String host) {
    var hostValue = convertAddr(host);
    if (hostValue == null) return false;
    var ipValue = convertAddr(ip);
    return (hostValue & maskValue) == (ipValue & maskValue);
  }
  
  void writeTo(CodeWriter w) {
    w.inline('isInNet(host, ${JSON.stringify(ip)}, ${JSON.stringify(mask)})');
  }
  
  IpCondition([this.ip = '0.0.0.0', int prefixLength = 0]) {
    this._prefixLength = prefixLength;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    p['ip'] = this.ip;
    p['prefixLength'] = this.prefixLength;
  }
  
  factory IpCondition.fromPlain(Map<String, Object> p, [Object config]) {
    return new IpCondition(p['ip'], p['prefixLength']);
  }
}
