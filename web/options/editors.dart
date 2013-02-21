library switchy_options_editors;

import 'dart:json';
import 'package:switchyomega/condition/lib.dart';
import 'package:switchyomega/condition/shexp_utils.dart';
import 'package:switchyomega/lang/lib.dart';
import 'package:switchyomega/profile/lib.dart';
import 'package:switchyomega/html/converters.dart' as convert;

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

class RuleEditor {
  Rule rule;

  Condition get condition => rule.condition;

  RuleEditor(this.rule) {
    if (isRegex) {
      _regex = (rule.condition as PatternBasedCondition).pattern;
    } else if (isPatternBased) {
      _pattern = (rule.condition as PatternBasedCondition).pattern;
    } else {
      _pattern = '';
    }
  }

  bool get isPatternBased => rule.condition is PatternBasedCondition;
  bool get isRegex => rule.condition is RegexCondition;

  void _setPattern() {
    if (isRegex) {
      (rule.condition as RegexCondition).pattern = _regex;
    } else if (isPatternBased) {
      (rule.condition as PatternBasedCondition).pattern = _pattern;
    }
  }

  static String convertPattern(PatternBasedCondition from, String toType) {
    if (toType.contains('Regex')) {
      String regex = null;
      if (from is HostWildcardCondition) {
        regex = (from as HostWildcardCondition).magicRegex();
        if (toType == 'UrlRegexCondition') {
          var host = regex.replaceFirst(r'(^|\.)', r'([^/.]+\.)*')
              .replaceAll(r'$', '/');
          regex = '://$host';
        }
        return regex;
      } else if (from is KeywordCondition) {
        return shExp2RegExp('*${from.pattern}*', trimAsterisk: true);
      } else if (from is UrlWildcardCondition) {
        regex = (from as UrlWildcardCondition).convert2Regex();
      }
      if (from is UrlWildcardCondition || from is UrlRegexCondition &&
          toType == 'HostRegexCondition') {
        // Try to parse URL regex like ".*://HOST_PART/.*"
        var r = new RegExp(r'^(\.\*)?://(.*)/(\.\*)?$');
        var match = r.firstMatch(from.pattern);
        if (match != null) {
          return match[2];
        }
      }
      return regex;
    } else {
      if (from is HostWildcardCondition &&
          toType == 'UrlWildcardCondition') {
        // Well, not exactly when pattern contain wildcards.
        return '*://${from.pattern}/*';
      } else if (from is UrlWildcardCondition &&
          toType == 'HostWildcardCondition') {
        // Try to parse host wildcard like "*://HOST_PART/*"
        var r = new RegExp(r'^\*://(.*)/\*$');
        var match = r.firstMatch(from.pattern);
        if (match != null) {
          return match[1];
        }
      } else if (from is KeywordCondition) {
        return '*${from.pattern}*';
      } else if (toType == 'KeywordCondition') {
        if (from is RegexCondition) {
          // Try to parse regex like ".*KEYWORD.*"
          var r = new RegExp(
              r'^(\.\*)?([^\[\\\^\$\.\|\?\*\+\(\)\{\}]*)(\.\*)?$');
          var match = r.firstMatch(from.pattern);
          if (match != null) {
            return match[2];
          }
        } else {
          // Try to parse wildcard like "*KEYWORD*"
          var r = new RegExp(r'^\*([^\*\?]*)\*$');
          var match = r.firstMatch(from.pattern);
          if (match != null) {
            return match[1];
          }
        }
      }
    }
    return null;
  }

  String get conditionType => rule.condition.conditionType;

  void set conditionType(String value) {
    var converted_pattern = '';
    // Try converting some known conditions.
    if (condition is PatternBasedCondition) {
      converted_pattern = ifNull(convertPattern(
          condition as PatternBasedCondition,
          value), '');
    }

    rule.condition = new Condition.fromPlain({
      'conditionType': value,
      'pattern': converted_pattern
    });

    if (converted_pattern.length > 0) {
      if (isRegex) {
        _regex = converted_pattern;
      } else {
        _pattern = converted_pattern;
      }
    } else {
      // Keep the pattern so that the user can edit it.
      if (rule.condition is RegexCondition) {
        _pattern = _pattern.length > 0 ? _pattern : _regex;
      } else if (rule.condition is PatternBasedCondition) {
        _regex = _regex.length > 0 ? _regex : _pattern;
      }
      if (rule.condition is HostLevelsCondition) {
        var cond = rule.condition as HostLevelsCondition;
        cond.minValue = cond.maxValue = 1;
      }
    }
    _setPattern();
  }

  String _pattern = '';
  String _regex = '';

  String get pattern {
    if (isRegex) return _regex;
    if (isPatternBased) return _pattern;
    return '';
  }

  void set pattern(String value) {
    if (isRegex) {
      _regex = value;
      _pattern = '';
    } else {
      _pattern = value;
      _regex = '';
    }
    _setPattern();
  }

}
