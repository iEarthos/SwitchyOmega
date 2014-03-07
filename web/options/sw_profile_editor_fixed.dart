import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:js';
import 'package:switchyomega/switchyomega.dart';
import 'options_utils.dart';

@CustomTag('sw-profile-editor-fixed')
class SwProfileEditorFixedElement extends PolymerElement
    with SwitchyOptionsUtils {
  bool get applyAuthorStyles => true;
  @published FixedProfile profile = null;

  SwProfileEditorFixedElement.created() : super.created() {
    _proxies = {};
  }

  void enteredView() {
    super.enteredView();
    context.callMethod('onShadowHostReady', [this]);
    _proxies = {
        '': new ProxyServerEditor(this, '', profile.fallbackProxy),
        'http': new ProxyServerEditor(this, 'http', profile.proxyForHttp),
        'https': new ProxyServerEditor(this, 'https', profile.proxyForHttps),
        'ftp': new ProxyServerEditor(this, 'ftp', profile.proxyForFtp)
    };
    this.notifyPropertyChange(#proxies, [], proxies);
  }

  String bypassListToText(List<BypassCondition> list) =>
      list.map((b) => b.pattern).join('\n');

  void onBypassListChange(event, detail, bypassList) {
    profile.bypassList.clear();
    profile.bypassList.addAll(bypassList.value.split('\n')
        .map((l) => l.trim()).where((l) => !l.isEmpty)
        .map((l) => new BypassCondition(l)));
    // Update the text in the textarea.
    bypassList.value = bypassListToText(profile.bypassList);
  }

  @observable Map<String, ProxyServerEditor> _proxies = null;

  @reflectable List<ProxyServerEditor> get proxies => _proxies.values.toList();

  ProxyServerEditor operator [](String scheme) {
    return _proxies[scheme];
  }

  void _update(String scheme) {
    switch(scheme) {
      case '':
        profile.fallbackProxy = this._proxies[scheme].proxy;
        _proxies.forEach((_, proxy) {
          proxy._updateDefaultPort();
        });
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

class ProxyServerEditor extends Observable {
  ProxyServer get proxy {
    if (_isEmpty || _host == '') return null;
    return new ProxyServer(_host, _protocol, _port);
  }
  @reflectable SwProfileEditorFixedElement profileEditor = null;
  @reflectable final String scheme;
  @reflectable bool get isDefault => scheme == '';

  ProxyServerEditor(this.profileEditor, this.scheme,
      [ProxyServer proxy = null]) {
    if (proxy != null) {
      this._protocol = proxy.protocol;
      this._host = proxy.host;
      this._port = proxy.port;
      _isEmpty = false;
    } else {
      this._host = '';
    }
  }

  bool __isEmpty = true;
  bool get _isEmpty => __isEmpty;
  void set _isEmpty(bool value) {
    __isEmpty = value;
    this.notifyPropertyChange(#protocol, null, protocol);
    this.notifyPropertyChange(#host, null, host);
    this.notifyPropertyChange(#portAsString, null, portAsString);
  }
  bool get isEmpty => __isEmpty;

  void _applyDefaults() {
    if (_protocol == null) _protocol = defaultProtocol;
    if (_host == '') _host = 'proxy.example.com';
    if (_port == null) _port = defaultPort;
    _isEmpty = false;
  }

  String _protocol = defaultProtocol;

  @observable String get protocol => _isEmpty ? '' : _protocol;
  @observable void set protocol(String value) {
    if (value == '') {
      _isEmpty = true;
    } else {
      _protocol = value;
      this.notifyPropertyChange(#protocol, null, protocol);
      _isEmpty = false;
      _applyDefaults();
    }
    profileEditor._update(scheme);
  }

  String _host;

  @observable
  String get host => _isEmpty ? '' : _host;
  @observable void set host(String value) {
    _host = value;
    _isEmpty = _host == '';
    this.notifyPropertyChange(#host, null, host);
    if (!_isEmpty) _applyDefaults();
    profileEditor._update(scheme);
  }

  @observable int _port = null;

  @observable String get portAsString => _isEmpty ? '' : _port.toString();
  @observable void set portAsString(String value) {
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
      this.notifyPropertyChange(#portAsString, null, portAsString);
      profileEditor._update(scheme);
    }
  }

  static String get defaultProtocol => ProxyServer.defaultProtocol;

  @reflectable
  int get defaultPort {
    if (!this.isEmpty) {
      return ProxyServer.defaultPort[this.protocol];
    } else {
      if (this.isDefault) return null;
      var default_proxy = this.profileEditor[''];
      var port = default_proxy.protocol.isEmpty ? null : default_proxy._port;
      return ifNull(port, default_proxy.defaultPort);
    }
  }

  void _updateDefaultPort() {
    this.notifyPropertyChange(#defaultPort, null, defaultPort);
  }
}