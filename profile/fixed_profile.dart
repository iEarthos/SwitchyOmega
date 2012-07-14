/**
 * A [FixedProfile] is a set of servers for different protocols.
 * Besides, a [bypassList] can also be used for server which should be
 * connected directly.
 */
class FixedProfile extends IncludableProfile {
  final String profileType = 'FixedProfile';
  
  ProxyServer proxyForHttp;
  ProxyServer proxyForHttps;
  ProxyServer proxyForFtp;
  ProxyServer fallbackProxy;
  
  /**
   * When the url matches one of the [BypassConditions],
   * direct connection is used.
   */
  List<BypassCondition> bypassList;
  
  /**
   * Write the proxy servers and [bypassList] to a PAC script.
   * See <https://code.google.com/chrome/extensions/proxy.html> for the logic.
   */
  void writeTo(CodeWriter w) {
    if (bypassList.length == 0 && proxyForHttp == null && 
        proxyForHttps == null && proxyForFtp == null) {
      if (fallbackProxy != null) {
        w.inline("[${JSON.stringify(fallbackProxy.toPacResult())}]");
      } else {
        w.inline("['DIRECT']");
      }
      return;
    } else {
      w.code('function (url, host, scheme) {');
      w.code("'use strict';");
      if (bypassList.length > 0) {
        w.inline('if (').indent().indent(); // Double-indent.
        for (var b in bypassList) {
          b.writeTo(w);
          w.code(' || ');
        }
        w.code("false) return ['DIRECT'];").outdent().outdent().newLine();
      }
    }
    
    if (proxyForHttp != null) {
      w.inline("if (scheme === 'http') ")
         .code("return [${JSON.stringify(proxyForHttp.toPacResult())}];");
    }
    if (proxyForHttps != null) {
      w.inline("if (scheme === 'https') ")
         .code("return [${JSON.stringify(proxyForHttps.toPacResult())}];");
    }
    if (proxyForFtp != null) {
      w.inline("if (scheme === 'ftp') ")
         .code("return [${JSON.stringify(proxyForFtp.toPacResult())}];");
    }
    if (fallbackProxy != null) {
      w.code("return [${JSON.stringify(fallbackProxy.toPacResult())}];");
    } else {
      w.code("return ['DIRECT'];");
    }
    w.inline('}');
  }
  
  /**
   * Get the [ProxyServer] for the [url].
   * Returns [null] if direct connection should be used.
   */
  ProxyServer getProxyFor(String url, String host, String scheme) {
    for (var b in bypassList) {
      if (b.match(url, host, scheme, null)) return null;
    }
    if (proxyForHttp != null && scheme == 'http') return proxyForHttp;
    if (proxyForHttps != null && scheme == 'https') return proxyForHttps;
    if (proxyForFtp != null && scheme == 'ftp') return proxyForFtp;
    
    return fallbackProxy;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    p = super.toPlain(p, config);
    
    if (this.proxyForHttp != null)
      p['proxyForHttp'] = this.proxyForHttp.toPlain(null, config);
    if (this.proxyForHttps != null)
      p['proxyForHttps'] = this.proxyForHttps.toPlain(null, config);
    if (this.proxyForFtp != null)
      p['proxyForFtp'] = this.proxyForFtp.toPlain(null, config);
    if (this.fallbackProxy != null)
      p['fallbackProxy'] = this.fallbackProxy.toPlain(null, config);
    p['bypassList'] = this.bypassList.map((b) => b.toPlain(null, config));
    return p;
  }
  
  FixedProfile(String name) : super(name) {
    bypassList = new List<BypassCondition>();
  }
  
  factory FixedProfile.fromPlain(Map<String, Object> p, [Object config]) {
    var f = new FixedProfile(p['name']);
    f.color = p['color'];
    if (p['proxyForHttp'] != null)
      f.proxyForHttp = new ProxyServer.fromPlain(p['proxyForHttp'], config);
    if (p['proxyForHttps'] != null)
      f.proxyForHttps = new ProxyServer.fromPlain(p['proxyForHttps'], config);
    if (p['proxyForFtp'] != null)
      f.proxyForFtp = new ProxyServer.fromPlain(p['proxyForFtp'], config);
    if (p['fallbackProxy'] != null)
      f.fallbackProxy = new ProxyServer.fromPlain(p['fallbackProxy'], config);
    List<Object> bl = p['bypassList']; // CAST
    f.bypassList = bl.map((b) => new BypassCondition.fromPlain(b, config));
    
    return f;
  }
}

/**
 * A [ProxyServer].
 */
class ProxyServer extends Plainable {
  String scheme = 'http';
  String host;
  int port;
  
  /**
   * Converts this ProxyServer to a token of a PAC result string.
   */
  String toPacResult() {
    return '${pacScheme[scheme]} $host:$port';
  }
  
  /**
   * See <https://code.google.com/chrome/extensions/proxy.html>.
   */
  static final Map<String, int> defaultPort = const {
    'http': 80,
    'https': 443,
    'socks4' : 1080,
    'socks5': 1080
  };
  
  static final Map<String, String> pacScheme = const {
    'http': 'PROXY',
    'https': 'HTTPS',
    'socks4' : 'SOCKS', //compatibility
    'socks5': 'SOCKS5'
  };
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    if (p == null) p = new Map<String, Object>();
    p['scheme'] = this.scheme;
    p['host'] = this.host;
    p['port'] = this.port;
    
    return p;
  }
  
  ProxyServer(this.host, [this.scheme = 'http', this.port]) {
    if (this.port == null) this.port = defaultPort[scheme];
  }
  
  ProxyServer.fromPlain(Map<String, Object> p, [Object config]) {
    this.scheme = p['scheme'];
    this.host = p['host'];
    this.port = p['port'];
  }
}
