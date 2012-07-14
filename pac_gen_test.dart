#import('profile/lib.dart');
#import('condition/lib.dart');
#import('dart:json');

void main() {
  var d = new FixedProfile('http');
  d.fallbackProxy = new ProxyServer('127.0.0.1', 'http', 8888);
  
  var f = new FixedProfile('ssh');
  f.proxyForHttp = new ProxyServer('127.0.0.1', 'http', 8080);
  f.fallbackProxy = new ProxyServer('127.0.0.1', 'socks5', 7070);
  f.bypassList.add(new BypassCondition('127.0.0.1:3333'));
  f.bypassList.add(new BypassCondition('https://www.example.com'));
  f.bypassList.add(new BypassCondition('*:3333'));
  f.bypassList.add(new BypassCondition('<local>'));
  
  var s = new SwitchProfile('auto', d);
  // The following line will only work in PAC files because it uses isInNet.
  // f.bypassList.add(new BypassCondition('192.168.0.0/18'));
  s.add(new Rule(new HostWildcardCondition('*.example.com'), f));
  s.add(new Rule(new HostLevelsCondition(0, 0), new DirectProfile()));
  s.add(new Rule(new KeywordCondition('foo'), f));
  
  var col = new ProfileCollection([d, f, s]);
  
  // Serialize the profiles to JSON and then parse back to test the roundtrip.
  var json = JSON.stringify(col.toPlain());
  col = new ProfileCollection.fromPlain(JSON.parse(json));
  
  InclusiveProfile auto = col['auto']; // CAST
  print(auto.toScript());
  
  // Some test cases
  print('var assert = function (actural, expected, extra) {\n'
        "  if (actural !== expected) \n"
        "    console.log('[' + extra + ']: ' + actural + "
        "' (Expected: ' + expected + ')');\n"
        '};');
  testCase(s, 'https://www.example.com/somepath');
  testCase(s, 'ftp://www.example.com/somepath');
  testCase(s, 'http://www.example.com/somepath');
  testCase(s, 'http://foo.test/test');
  testCase(s, 'http://bar/test');
  testCase(s, 'http://foo.test:3333/test');
  testCase(s, 'http://127.0.0.1/foo');
  testCase(s, 'http://another.example.test');
}

ProxyServer resolveProxy(Profile p, String url, String host, String scheme) {
  while (p != null) {
    if (p is InclusiveProfile) {
      p = p.choose(url, host, scheme, null);
    }
    if (p is FixedProfile) {
      return p.getProxyFor(url, host, scheme);
    }
    if (p is DirectProfile) {
      return null;
    }
  }
}

void testCase(Profile p, String url) {
  var scheme = url.substring(0, url.indexOf(':'));
  var host;
  
  var hostStart = scheme.length + 3;
  var slashPos = url.indexOf('/', hostStart);
  if (slashPos < 0) slashPos = url.length;
  
  if (url.charCodeAt(slashPos - 1) == BypassCondition.closeSquareBracketCode) {
    host = url.substring(hostStart, slashPos + 1);
  } else {
    var colonPos = url.lastIndexOf(':', slashPos - 1);
    if (colonPos < hostStart) {
      host = url.substring(hostStart, slashPos);
    } else {
      host = url.substring(hostStart, colonPos);
    }
  }
  
  var resultProxy = resolveProxy(p, url, host, scheme);
  var result = resultProxy == null ? 'DIRECT' : resultProxy.toPacResult();
  
  url = JSON.stringify(url);
  host = JSON.stringify(host);
  result = JSON.stringify(result);
  
  print('assert(FindProxyForURL($url, $host), $result, $url);');
}
