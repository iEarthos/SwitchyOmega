/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS file
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

import 'dart:js';
import 'package:json/json.dart' as JSON;
import 'package:switchyomega/condition/lib.dart';
import 'package:switchyomega/profile/lib.dart';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';

void allTests() {
  var http = new FixedProfile('http');
  http.fallbackProxy = new ProxyServer('127.0.0.1', 'http', 8888);

  var ssh = new FixedProfile('ssh');
  ssh.proxyForHttp = new ProxyServer('127.0.0.1', 'http', 8080);
  ssh.fallbackProxy = new ProxyServer('127.0.0.1', 'socks5', 7070);
  ssh.bypassList.add(new BypassCondition('127.0.0.1:3333'));
  ssh.bypassList.add(new BypassCondition('https://www.example.com'));
  ssh.bypassList.add(new BypassCondition('*:3333'));
  ssh.bypassList.add(new BypassCondition('<local>'));

  var list1 = new SwitchyRuleListProfile('list1', http.name, ssh.name);
  // Example rule list from https://code.google.com/p/switchy/wiki/RuleList
  list1.ruleList = r"""
      ; Summary: Example Rule List
      ; Author: Mhd Hejazi (my@email)
      ; Date: 2010-01-20
      ; URL: http://samabox.com/projects/chrome/switchy/switchyrules.txt
      
      #BEGIN
      
      [Wildcard]
      *://chrome.google.com/*
      *://*.samabox.com/*
      
      [RegExp]
      ^http://code\.google\.com/.*
      youtube
      
      #END
    """;

  var list2 = new AutoProxyRuleListProfile('list2', list1.name, ssh.name);
  list2.ruleList = r"""[AutoProxy]
      autoproxy.example.net
      ||autoproxy2.example.net
      |https://ssl.autoproxy3.example.net
      /^https?:\/\/[^\/]+autoproxy4.example\.net/
      @@||autoproxy5.example.net
      !Foo bar
    """;

  var sw = new SwitchProfile('auto', list2.name);
  // The following line will only work in PAC files because it uses isInNet.
  // f.bypassList.add(new BypassCondition('192.168.0.0/18'));
  sw.rules.add(new Rule(new HostWildcardCondition('*.example.com'),
      ssh.name));
  sw.rules.add(new Rule(new HostLevelsCondition(0, 0),
      new DirectProfile().name));
  sw.rules.add(new Rule(new KeywordCondition('foo'), ssh.name));

  var col = new ProfileCollection([http, ssh, list1, list2, sw]);

  Observable.dirtyCheck();

  // Serialize the profiles to JSON and then parse back to test the roundtrip.
  var json = JSON.stringify(col.toPlain());
  col = new ProfileCollection.fromPlain(JSON.parse(json));
  Observable.dirtyCheck();

  var auto = col['auto'] as InclusiveProfile;
  context.callMethod('initPac', [auto.toScript()]);

  // Some test cases
  testCase(sw, 'https://www.example.com/somepath');
  testCase(sw, 'ftp://www.example.com/somepath');
  testCase(sw, 'http://www.example.com/somepath');
  testCase(sw, 'http://www.example.net/');
  testCase(sw, 'http://foo.test/test');
  testCase(sw, 'http://bar/test');
  testCase(sw, 'http://foo.test:3333/test');
  testCase(sw, 'http://127.0.0.1/foo');
  testCase(sw, 'http://another.example.test');
  testCase(sw, 'https://chrome.google.com/');
  testCase(sw, 'http://samabox.com/');
  testCase(sw, 'http://code.google.com/p/switchy/wiki/RuleList');
  testCase(sw, 'http://autoproxy.example.net/');
  testCase(sw, 'http://autoproxy5.example.net/');
}

ProxyServer resolveProxy(Profile p, String url, String host, String scheme) {
  while (p != null) {
    var next_p = p;
    if (p is InclusiveProfile) {
      next_p = p.tracker.getProfileByName(p.choose(url, host, scheme, null));
    }
    p = next_p;
    if (p is FixedProfile) {
      return p.getProxyFor(url, host, scheme);
    }
    if (p is DirectProfile) {
      return null;
    }
  }
}

void testCase(Profile p, String url) {
  test(url, () {
    var scheme = url.substring(0, url.indexOf(':'));
    var host;

    var hostStart = scheme.length + 3;
    var slashPos = url.indexOf('/', hostStart);
    if (slashPos < 0) slashPos = url.length;

    if (url.codeUnitAt(slashPos - 1) == BypassCondition.closeSquareBracketCode) {
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

    var proxy = context.callMethod('FindProxyForURL', [url, host]);

    expect(proxy, equals(result));
  });
}