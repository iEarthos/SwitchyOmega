/*!
 * Copyright (C) 2012, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'profile/lib.dart';
import 'condition/lib.dart';
import 'dart:json';

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

  var s = new SwitchProfile('auto', d.name, null);
  // The following line will only work in PAC files because it uses isInNet.
  // f.bypassList.add(new BypassCondition('192.168.0.0/18'));
  s.add(new Rule(new HostWildcardCondition('*.example.com'), f.name));
  s.add(new Rule(new HostLevelsCondition(0, 0), new DirectProfile().name));
  s.add(new Rule(new KeywordCondition('foo'), f.name));

  var col = new ProfileCollection([d, f, s]);

  // Serialize the profiles to JSON and then parse back to test the roundtrip.
  var json = JSON.stringify(col);
  col = new ProfileCollection.fromPlain(JSON.parse(json));

  var auto = col['auto'] as InclusiveProfile;
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
      p = p.getProfileByName(p.choose(url, host, scheme, null));
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
