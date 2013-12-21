part of switchy_browser_message;

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
 * A [MessageBrowser] sends browser requests via a [Communicator], then the
 * requested actions are performed at its target.
 */
class MessageBrowser extends Browser {
  Communicator _c;

  MessageBrowserStorage _storage = null;

  MessageBrowserStorage get storage {
    if (_storage == null) {
      _storage = new MessageBrowserStorage(_c);
    }
    return _storage;
  }

  MessageBrowser([Communicator c = null]) {
    if (c == null) {
      this._c = new Communicator();
    } else {
      this._c = c;
    }
  }

  /**
   * Transform the [profile] to a plain and browser-friendly structure, then
   * send it via the [Communicator].
   * The data strcture is based on Chromium Extensions Proxy API
   * <https://developer.chrome.com/extensions/proxy.html>, but I don't
   * mean to block other browsers. The target can transform the data
   * structure to whatever format the browser likes after receiving it.
   */
  Future applyProfile(Profile profile, List<String> possibleResults,
                      {bool readonly: false, String profileName: null,
                       bool refresh: false,
                       bool noConfig: false}) {
    var completer = new Completer();

    Map<String, Object> config = {};

    if (noConfig) {
      config = null;
    } else if (profile is SystemProfile) {
      config['mode'] = 'system';
    } else if (profile is DirectProfile) {
      config['mode'] = 'direct';
    } else if (profile is AutoDetectProfile) {
      config['mode'] = 'auto_detect';
    } else if (profile is FixedProfile) {
      if (profile.proxyForHttp == null &&
          profile.proxyForHttps == null && profile.proxyForFtp == null &&
          profile.fallbackProxy == null) {
        config['mode'] = 'direct';
      } else {
        config['mode'] = 'fixed_servers';
        var rules = {};
        var plain = profile.toPlain();
        for (var key in ['proxyForHttp', 'proxyForHttps',
                         'proxyForFtp', 'fallbackProxy']) {
          if (plain[key] != null)
            rules[key] = plain[key];
        }
        if (profile.fallbackProxy != null &&
            profile.fallbackProxy.protocol == 'http') {
          // Chromium does not allow HTTP proxies in 'fallbackProxy'.
          rules.remove('fallbackProxy');
          if (profile.proxyForHttp == null &&
              profile.proxyForHttps == null && profile.proxyForFtp == null) {
            // Use 'singleProxy' if no proxy is configured for other protocols.
            rules['singleProxy'] = profile.fallbackProxy.toPlain();
          } else {
            // Otherwise, try to set the proxies of all possible protocols.
            var getFallback = () => plain['fallbackProxy'];
            rules.putIfAbsent('proxyForHttp', getFallback);
            rules.putIfAbsent('proxyForHttps', getFallback);
            rules.putIfAbsent('proxyForFtp', getFallback);
          }
        }
        rules['bypassList'] = profile.bypassList.map((b) => b.pattern)
            .toList();
        config['rules'] = rules;
      }
    } else if (profile is PacProfile && profile.pacUrl != null &&
        profile.pacUrl.isNotEmpty) {
      config['mode'] = 'pac_script';
      config['pacScript'] = { 'url': profile.pacUrl,
                              'mandatory': true };
    } else if (profile is ScriptProfile) {
      config['mode'] = 'pac_script';
      config['pacScript'] = { 'data': profile.toScript(),
                              'mandatory': true};
    } else {
      throw new UnsupportedError(profile.profileType);
    }


    _c.send('proxy.set', {
      'displayName': profile.name,
      'currentProfile': ifNull(profileName, profile.name),
      'color': profile.color,
      'inclusive': profile is InclusiveProfile,
      'readonly': readonly || possibleResults.length == 0,
      'possibleResults': possibleResults,
      'config': config,
      'refresh': refresh
    }, (_, [__]) {
      completer.complete(null);
    });

    return completer.future;
  }

  Map<String, StreamController<String>> _alarms = null;

  Stream<String> setAlarm(String name, num periodInMinutes) {
    if (_alarms == null) {
      _alarms = {};
      _c.on('alarm.fire', (alarm, [_]) {
        print(alarm);
        _alarms[alarm].add(alarm);
      });
    }
    _c.send('alarm.set', {
      'name': name,
      'periodInMinutes': periodInMinutes
    });
    if (periodInMinutes <= 0) {
      var controller = _alarms.remove(name);
      if (controller != null) {
        controller.close();
      }
      return null;
    }
    var controller = new StreamController(onCancel: () {
      setAlarm(name, -1);
    });
    _alarms[name] = controller;
    return controller.stream;
  }

  StreamController<MessageProxyChangeEvent> _proxyChanges = null;

  Stream<MessageProxyChangeEvent> get onProxyChange {
    if (_proxyChanges == null) {
      _proxyChanges = new StreamController();
      _c.on('proxy.onchange', (proxy, [_]) {
        var level = proxy['levelOfControl'];
        var controllable = (level == 'controllable_by_this_extension' ||
            level == 'controlled_by_this_extension');
        var incognitoSpecific = proxy['incognitoSpecific'] == true;
        _proxyChanges.add(new MessageProxyChangeEvent(proxy['value'],
            controllable: controllable,
            incognitoSpecific: incognitoSpecific));
      });
      _c.send('proxy.get');
      _c.send('proxy.listen');
    }
    return _proxyChanges.stream;
  }

  Future<String> download(String url) {
    var comp = new Completer<String>();
    _c.send('ajax.get', url, (result, [_]) {
      if (result['error'] != null) {
        comp.completeError(new DownloadFailException(
            result['status'], result['error']));
      } else {
        comp.complete(result['data']);
      }
    });

    return comp.future;
  }

}

class MessageProxyChangeEvent extends ProxyChangeEvent {
  Map<Object, Object> _proxy;

  MessageProxyChangeEvent(this._proxy,
      {bool incognitoSpecific, bool controllable})
    : super(incognitoSpecific, controllable);

  Profile toProfile(ProfileCollection col) {
    Profile newProfile = null;
    switch (_proxy['mode']) {
      case 'system':
        return new SystemProfile();
      case 'direct':
        return new DirectProfile();
      case 'auto_detect':
        return new AutoDetectProfile();
      case 'pac_script':
        var pacScript = _proxy['pacScript'] as Map<String, String>;
        var url = pacScript['url'] as String;
        if (url != null) {
          for (var profile in col) {
            if (profile is PacProfile && profile.pacUrl == url) {
              return profile;
            }
          }
          newProfile = new PacProfile('')..pacUrl = url;
        } else {
          var script = pacScript['data'] as String;
          for (var profile in col) {
            // TODO(catus): toScript() is too expensive. Remove script check?
            if (profile is ScriptProfile && profile.toScript() == script) {
              return profile;
            }
          }
          newProfile = new PacProfile('')..pacScript = script;
        }
        break;
      case 'fixed_servers':
        var rules = _proxy['rules'] as Map<String, Object>;
        var bypass = (rules['bypassList'] as List<String>).toSet();
        var servers = new Map<String, ProxyServer>();
        for (var scheme in ['singleProxy', 'proxyForHttp', 'proxyForHttps',
                            'proxyForFtp', 'fallbackProxy']) {
          var server = rules[scheme];
          if (server != null) {
            servers[scheme] = new ProxyServer(server['host'],
                server['scheme'], server['port']);
          }
        }
        if (servers['singleProxy'] != null || (
            servers['fallbackProxy'] == null &&
            servers['proxyForHttp'].protocol == 'http' &&
            servers['proxyForHttp'].equals(servers['proxyForHttps']) &&
            servers['proxyForHttp'].equals(servers['proxyForFtp']))) {
          var fb = ifNull(servers['singleProxy'], servers['proxyForHttp']);
          servers.clear();
          servers['fallbackProxy'] = fb;
        }
        for (var profile in col) {
          if (profile is FixedProfile) {
            var bypassSet = profile.bypassList.map((c) => c.pattern).toSet();
            if (bypassSet.containsAll(bypass) &&
                bypass.containsAll(bypassSet) &&
                profile.proxyForHttp.equals(servers['proxyForHttp']) &&
                profile.proxyForHttps.equals(servers['proxyForHttps']) &&
                profile.proxyForFtp.equals(servers['proxyForFtp']) &&
                profile.fallbackProxy.equals(servers['fallbackProxy']))
              return profile;
          }
        }
        newProfile = new FixedProfile('')
          ..proxyForHttp = servers['proxyForHttp']
          ..proxyForHttps = servers['proxyForHttps']
          ..proxyForFtp = servers['proxyForFtp']
          ..fallbackProxy = servers['fallbackProxy']
          ..bypassList.addAll(
              bypass.map((pattern) => new BypassCondition(pattern)));
        break;
      default:
        throw new UnsupportedError(
            'Unsupported proxy mode: ${_proxy['mode']}.');
    }

    newProfile.color = ProfileColors.unknown;
    return newProfile;
  }
}

class MessageBrowserStorage extends BrowserStorage {
  Communicator _c;

  MessageBrowserStorage([Communicator c = null]) {
    if (c == null) {
      this._c = new Communicator();
    } else {
      this._c = c;
    }
  }

  Future<Map<String, Object>> get(List<String> keys) {
    var comp = new Completer<Map<String, Object>>();
    _c.send('storage.get', keys, (data, [_]) {
      comp.complete(data);
    });
    return comp.future;
  }

  Future set(Map<String, Object> items) {
    var comp = new Completer();
    _c.send('storage.set', items, (_, [__]) {
      comp.complete();
    });
    return comp.future;
  }

  Future remove(List<String> keys) {
    var comp = new Completer();
    _c.send('storage.remove', keys, (_, [__]) {
      comp.complete();
    });
    return comp.future;
  }

  StreamController<BrowserStorageChangeRecord> _changes = null;

  Stream<BrowserStorageChangeRecord> get onChange {
    if (_changes == null) {
      _changes = new StreamController();
      _c.on('storage.onchange', (Map<String, Object> changes, [_]) {
        changes.forEach((key, change) {
          _changes.add(new BrowserStorageChangeRecord(key,
              change['oldValue'], change['newValue']));
        });
      });
      _c.send('storage.watch');
    }
    return _changes.stream.asBroadcastStream();
  }
}