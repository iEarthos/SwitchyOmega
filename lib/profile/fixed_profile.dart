part of switchy_profile;

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

/**
 * A [FixedProfile] is a set of servers for different protocols.
 * Besides, a [bypassList] can also be used for server which should be
 * connected directly.
 */
class FixedProfile extends IncludableProfile {
  @reflectable final String profileType = 'FixedProfile';

  @observable ProxyServer proxyForHttp;
  @observable ProxyServer proxyForHttps;
  @observable ProxyServer proxyForFtp;
  @observable ProxyServer fallbackProxy;

  /**
   * When the url matches one of the [BypassConditions],
   * direct connection is used.
   */
  @reflectable
  final ObservableList<BypassCondition> bypassList = toObservable([]);

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

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);

    if (this.proxyForHttp != null) {
      p['proxyForHttp'] = this.proxyForHttp.toPlain();
    }
    if (this.proxyForHttps != null) {
      p['proxyForHttps'] = this.proxyForHttps.toPlain();
    }
    if (this.proxyForFtp != null) {
      p['proxyForFtp'] = this.proxyForFtp.toPlain();
    }
    if (this.fallbackProxy != null) {
      p['fallbackProxy'] = this.fallbackProxy.toPlain();
    }
    p['bypassList'] = this.bypassList.map((b) => b.toPlain()).toList();
    return p;
  }

  FixedProfile(String name) : super(name) {
    this.bypassList.changes.listen((_) {
      this.notifyPropertyChange(#details, null, '');
    });
  }

  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    if (p['proxyForHttp'] != null) {
      proxyForHttp = new ProxyServer.fromPlain(p['proxyForHttp']);
    }
    if (p['proxyForHttps'] != null) {
      proxyForHttps = new ProxyServer.fromPlain(p['proxyForHttps']);
    }
    if (p['proxyForFtp'] != null) {
      proxyForFtp = new ProxyServer.fromPlain(p['proxyForFtp']);
    }
    if (p['fallbackProxy'] != null) {
      fallbackProxy = new ProxyServer.fromPlain(p['fallbackProxy']);
    }
    var bl = p['bypassList'] as List<Object>;
    bypassList.clear();
    bypassList.addAll(bl.map((b) => new BypassCondition.fromPlain(b)));
  }

  factory FixedProfile.fromPlain(Map<String, Object> p) {
    var f = new FixedProfile(p['name']);
    f.loadPlain(p);
    return f;
  }
}

/**
 * A [ProxyServer].
 */
class ProxyServer extends Plainable with Observable {
  @observable String protocol = defaultProtocol;
  @observable String host;
  @observable int port;

  /**
   * Converts this ProxyServer to a token of a PAC result string.
   */
  String toPacResult() {
    return '${pacScheme[protocol]} $host:$port';
  }

  /**
   * See <https://code.google.com/chrome/extensions/proxy.html>.
   */
  static final String defaultProtocol = 'http';

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

  Map<String, Object> toPlain([Map<String, Object> p]) {
    if (p == null) p = new Map<String, Object>();
    p['scheme'] = this.protocol;
    p['host'] = this.host;
    p['port'] = this.port;

    return p;
  }

  ProxyServer(this.host, [this.protocol = null, this.port = null]) {
    if (this.protocol == null) this.protocol = defaultProtocol;
    if (this.port == null) this.port = defaultPort[protocol];
  }

  void loadPlain(Map<String, Object> p) {
    this.protocol = p['scheme'];
    this.host = p['host'];
    this.port = p['port'];
  }

  ProxyServer.fromPlain(Map<String, Object> p) {
    this.loadPlain(p);
  }

  factory ProxyServer.parse(String proxyString, String scheme) {
    var match = new RegExp(r':(\d+)$').firstMatch(proxyString);
    if (match != null) {
      return new ProxyServer(
          proxyString.substring(0, proxyString.length - match.group(0).length),
          scheme,
          int.parse(match.group(1)));
    }
  }

  bool equals(ProxyServer other) =>
      this.protocol == other.protocol &&
      this.host == other.host &&
      this.port == other.port;

}
