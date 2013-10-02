part of switchy_browser;

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

StoredSwitchyOptions upgradeOptions(Map<String, Object> oldOptions,
                                    BrowserStorage storage) {
  if (oldOptions['schemaVersion'] == 0) {
    var newOptions = new Map<String, Object>();
    oldOptions.forEach((key, value) {
      if (key == 'profiles') {
        (value as Map<String, Object>).forEach((name, profile) {
          newOptions['+' + name] = profile;
        });
      } else {
        newOptions['-' + key] = value;
      }
    });
    return new StoredSwitchyOptions.fromPlain(newOptions, storage);
  }
  var config = JSON.parse(oldOptions['config']) as Map<String, Object>;
  if (config != null && config['firstTime'] != null) {
    var options = new StoredSwitchyOptions(storage);
    // Upgrade from SwitchySharp options.
    if (config['confirmDeletion'] != null) {
      options.confirmDeletion = config['confirmDeletion'] == true;
    }
    if (config['refreshTab'] != null) {
      options.refreshOnProfileChange = config['refreshTab'] == true;
    }
    if (config['quickSwitch'] != null) {
      options.enableQuickSwitch = config['quickSwitch'] == true;
    }
    if (config['preventProxyChanges'] != null) {
      options.revertProxyChanges = config['preventProxyChanges'] == true;
    }
    if (config['startupProfileId'] != null) {
      options.startupProfileName = config['startupProfileId'];
    }
    if (config['ruleListReload'] != null) {
      options.downloadInterval = int.parse(config['ruleListReload']);
    }

    if (oldOptions['profiles'] != null) {
      var profiles = JSON.parse(oldOptions['profiles'])
          as Map<String, Map<String, Object>>;

      var colorTranslations = {
                               'blue': '#99ccee',
                               'green': '#99dd99',
                               'red': '#ffaa88',
                               'yellow': '#ffee99',
                               'purple': '#d497ee',
                               '': '#99ccee'
      };
      var updatedProfiles = new Map<String, Profile>();
      profiles.forEach((_, profile) {
        Profile pf;
        /*
color: "blue"
id: "SSH"
name: "SSH"
proxyConfigUrl: ""
proxyExceptions: "localhost; 127.0.0.1; <local>"
proxyFtp: ""
proxyHttp: ""
proxyHttps: ""
proxyMode: "manual"
proxySocks: "127.0.0.1:7070"
socksVersion: 5
        */
        switch (profile['proxyMode']) {
          case 'manual':
            var fixedProfile = new FixedProfile(profile['id']);
            if (profile['useSameProxy'] == true) {
              fixedProfile.fallbackProxy = new ProxyServer.parse(
                  profile['proxyHttp'], 'http');
            } else if (profile['proxySocks'] != '') {
              fixedProfile.fallbackProxy = new ProxyServer.parse(
                  profile['proxySocks'],
                  profile['socksVersion'] == 5 ? 'socks5' : 'socks4');
            } else {
              fixedProfile.proxyForHttp = new ProxyServer.parse(
                  profile['proxyHttp'], 'http');
              fixedProfile.proxyForHttps = new ProxyServer.parse(
                  profile['proxyHttps'], 'http');
              fixedProfile.proxyForFtp = new ProxyServer.parse(
                  profile['proxyFtp'], 'http');
            }
            if (profile['proxyExceptions'] != null) {
              fixedProfile.bypassList.addAll(
                  (profile['proxyExceptions'] as String)
                  .split(';').map((x) => new BypassCondition(x.trim())));
            }
            pf = fixedProfile;
            break;
          case 'auto':
            var pacProfile = new PacProfile(profile['id']);
            var url = profile['proxyConfigUrl'] as String;
            if (url.startsWith('data:')) {
              var base64 = url.substring(url.indexOf(',') + 1);
              pacProfile.pacScript = new String.fromCharCodes(
                  CryptoUtils.base64StringToBytes(base64));
            } else {
              pacProfile.pacUrl = url;
            }
            pf = pacProfile;
            break;
          default:
            throw new UnsupportedError(
                'Unsupported proxy mode ${profile['proxyMode']}');
            break;
        }
        var rgbColor = colorTranslations[profile['color']];
        if (rgbColor == null) rgbColor = colorTranslations[''];
        pf.color = rgbColor;
        options.profiles.add(pf);
      });
    }

    if (oldOptions['rules'] != null) {
      var rules = JSON.parse(oldOptions['rules'])
          as Map<String, Map<String, String>>;
      var defaultProfileName = (JSON.parse(oldOptions['defaultRule'])
          as Map<String, String>)['profileId'];
      var switchProfile = new SwitchProfile('auto', defaultProfileName);
      rules.forEach((_, rule) {
        Condition c;
        switch(rule['patternType']) {
          case 'wildcard': {
            // TODO(catus): Recognize HostWildcardCondition.
            c = new UrlWildcardCondition(rule['urlPattern']);
          }
          break;
          case 'regexp': {
            c = new UrlRegexCondition(rule['urlPattern']);
          }
          break;
        }
        switchProfile.add(new Rule(c, rule['profileId']));
      });

      options.profiles.add(switchProfile);
    }

    if (config['ruleListEnabled'] == true) {
      RuleListProfile ruleList;
      if (config['ruleListAutoProxy'] == true) {
        ruleList = new AutoProxyRuleListProfile('rulelist', 'direct',
            config['ruleListProfileId']);
      } else {
        ruleList = new SwitchyRuleListProfile('rulelist', 'direct',
            config['ruleListProfileId']);
      }
      ruleList.sourceUrl = config['ruleListUrl'];
      if (oldOptions['rules'] != null) {
        var switchProfile = options.profiles['auto'] as SwitchProfile;
        ruleList.defaultProfileName = switchProfile.defaultProfileName;
        switchProfile.defaultProfileName = ruleList.name;
      }
      options.profiles.add(ruleList);
    }

    if (config['quickSwitchProfiles'] == true) {
      options.quickSwitchProfiles.addAll(config['quickSwitchProfiles']);
    }
    return options;
  }
  return null;
}