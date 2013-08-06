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
  Future applyProfile(Profile profile) {
    var completer = new Completer();

    Map<String, Object> config = {};

    if (profile is SystemProfile) {
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
        var plain = (profile as FixedProfile).toPlain();
        for (var key in ['proxyForHttp', 'proxyForHttps', 'proxyForFtp', 'fallbackProxy']) {
          if (plain[key] != null)
            rules[key] = plain[key];
        }
        if (profile.fallbackProxy != null && profile.fallbackProxy.protocol == 'http') {
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
        rules['bypassList'] = profile.bypassList.map((b) => b.pattern).toList();
        config['rules'] = rules;
      }
    } else if (profile is PacProfile) {
      config['mode'] = 'pac_script';
      config['pacScript'] = { 'url': (profile as PacProfile).pacUrl };
    } else if (profile is ScriptProfile) {
      config['mode'] = 'pac_script';
      config['pacScript'] = { 'data': (profile as ScriptProfile).toScript() };
    } else {
      throw new UnsupportedError(profile.profileType);
    }

    var possibleResults = [];
    if (profile is SwitchProfile && profile.tracker is ProfileCollection) {
      var col = profile.tracker as ProfileCollection;
      possibleResults = col.validResultProfilesFor(profile).map((p) => p.name).toList();
    }

    _c.send('proxy.set', {
      'profileName': profile.name,
      'color': profile.color,
      'inclusive': profile is InclusiveProfile,
      'switch': profile is SwitchProfile,
      'possibleResults': possibleResults,
      'config': config
    }, (_, [__]) {
      completer.complete(null);
    });

    return completer.future;
  }
}