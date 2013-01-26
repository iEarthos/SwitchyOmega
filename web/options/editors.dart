library switchy_options_editors;

import 'dart:json';
import '../html/converters.dart' as convert;
import "package:switchyomega/profile/lib.dart";
import "package:switchyomega/lang/lib.dart";

class FixedProfileEditor {
  FixedProfile profile;
  FixedProfileEditor(this.profile) {
    _proxies = {
        '': new ProxyServerEditor(this, '', profile.fallbackProxy),
        'http': new ProxyServerEditor(this, 'http', profile.proxyForHttp),
        'https': new ProxyServerEditor(this, 'https', profile.proxyForHttps),
        'ftp': new ProxyServerEditor(this, 'ftp', profile.proxyForFtp)
    };
  }

  Map<String, ProxyServerEditor> _proxies;

  List<ProxyServerEditor> get proxies => _proxies.values.toList();

  ProxyServerEditor operator [](String scheme) {
    return _proxies[scheme];
  }

  void _update(String scheme) {
    switch(scheme) {
      case '':
        profile.fallbackProxy = this._proxies[scheme].proxy;
        break;
      case 'http':
        profile.proxyForHttp = this._proxies[scheme].proxy;
        break;
      case 'https':
        profile.proxyForHttps = this._proxies[scheme].proxy;
        break;
      case 'ftp':
        profile.proxyForFtp = this._proxies[scheme].proxy;
        break;
    }
  }

}

class ProxyServerEditor {
  ProxyServer get proxy {
    if (_isEmpty || _host == '') return null;
    return new ProxyServer(_host, _protocol, _port);
  }
  FixedProfileEditor profileEditor = null;
  final String scheme;
  bool get isDefault => scheme == '';

  ProxyServerEditor(this.profileEditor, this.scheme,
      [ProxyServer proxy = null]) {
    if (proxy != null) {
      this._protocol = proxy.protocol;
      this._host = proxy.host;
      this._port = proxy.port;
      _isEmpty = false;
    }
  }

  bool _isEmpty = true;
  bool get isEmpty => _isEmpty;

  void _applyDefaults() {
    if (_protocol == null) _protocol = defaultProtocol;
    if (_host == '') _host = 'proxy.example.com';
    if (_port == null) _port = defaultPort;
  }

  String _protocol = defaultProtocol;
  String get protocol => _isEmpty ? '' : _protocol;
  void set protocol(String value) {
    if (value == '') {
      _isEmpty = true;
    } else {
      _protocol = value;
      _isEmpty = false;
      _applyDefaults();
    }
    profileEditor._update(scheme);
  }

  String _host;
  String get host => _isEmpty ? '' : _host;
  void set host(String value) {
    _host = value;
    _isEmpty = _host == '';
    if (!_isEmpty) _applyDefaults();
    profileEditor._update(scheme);
  }

  int _port = null;
  String get portAsString => _isEmpty ? '' : _port.toString();
  void set portAsString(String value) {
    if (value == '') {
      _port = null;
    } else {
      try {
        _port = int.parse(value);
      } on FormatException {
        return;
      }
      _isEmpty = false;
      _applyDefaults();
      profileEditor._update(scheme);
    }
  }

  static String get defaultProtocol => ProxyServer.defaultProtocol;

  int get defaultPort {
    if (!this.isEmpty) {
      return ProxyServer.defaultPort[this.protocol];
    } else {
      if (this.isDefault) return null;
      var default_proxy = this.profileEditor[''];
      return ifNull(default_proxy._port, default_proxy.defaultPort);
    }
  }
}