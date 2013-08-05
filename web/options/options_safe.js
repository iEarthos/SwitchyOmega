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

(function () {
  'use strict';
  var i18nCache = {};
  strings.forEach(function (name) {
    i18nCache[name] = chrome.i18n.getMessage(name);
  });

  // Set the title
  document.title = i18nCache['options_title'];

  var c = new Communicator();

  var getDefaultOptions = function () {
    return {
      'schemaVersion': 0,
      'confirmDeletion': true,
      'currentProfileName': 'auto',
      'enableQuickSwitch': false,
      'refreshOnProfileChange': true,
      'revertProxyChanges': false,
      'startupProfileName': 'auto',
      'profiles': [
          {
            "name":"ssh",
            "bypassList":[
              {"pattern":"127.0.0.1:3333","conditionType":"BypassCondition"},
              {"pattern":"https://www.example.com","conditionType":"BypassCondition"},
              {"pattern":"*:3333","conditionType":"BypassCondition"},
              {"pattern":"<local>","conditionType":"BypassCondition"}
            ],
            "profileType":"FixedProfile",
            "color":"#99ccee",
            "proxyForHttp":{"scheme":"http","port":8080,"host":"127.0.0.1"},
            "fallbackProxy":{"scheme":"socks5","port":7070,"host":"127.0.0.1"}
          },
          {
            "name":"http",
            "color":"#ffee99",
            "fallbackProxy":{"scheme":"http","port":8888,"host":"127.0.0.1"},
            "bypassList":[],
            "profileType":"FixedProfile"
          },
          {
            "name":"auto",
            "color":"#99dd99",
            "defaultProfileName":"rulelist",
            "rules": [
              {"profileName":"ssh","condition":{"pattern":"*.example.com","conditionType":"HostWildcardCondition"}},
              {"profileName":"direct","condition":{"minValue":0,"conditionType":"HostLevelsCondition","maxValue":0}},
              {"profileName":"ssh","condition":{"pattern":"foo","conditionType":"KeywordCondition"}}
            ],
            "profileType":"SwitchProfile"
          },
          {
            "name":"rulelist",
            "color":"#99ccee",
            "defaultProfileName":"direct",
            "matchProfileName":"http",
            "ruleList": "[AutoProxy]\nexample.com",
            "profileType":"AutoProxyRuleListProfile"
          }
        ],
      'quickSwitchProfiles' : []
    };
  };

  c.on({
    'tab.get': function (_, respond) {
      var hash;
      if (location.hash) {
        hash = location.hash;
        location.hash = '';
      } else {
        hash = localStorage['options_last_tab'];
      }
      respond(hash);
    },
    'tab.set': function (hash, respond) {
      localStorage['options_last_tab'] = hash;
      respond();
    },
    'i18n.get': function (data, respond) {
      respond(chrome.i18n.getMessage(data.name, data.substs));
    },
    'i18n.cache': function (data, respond) {
      respond(i18nCache);
    },
    'options.get': function (data, respond) {
      var options = localStorage['options'];
      if (options) {
        options = JSON.parse(options);
      } else {
        options = getDefaultOptions();
      }

      respond({
        'options': options,
        'tab': localStorage['options_last_tab'],
        'currentProfileName': localStorage['currentProfileName'] || 'direct'
      });
    },
    'options.default': function (data, respond) {
      respond({'options': getDefaultOptions()});
    },
    'options.set': function (data, respond) {
      localStorage['options'] = data;
      chrome.runtime.sendMessage({
        action: 'options.update'
      });
      respond();
    }
  });

  document.addEventListener('DOMContentLoaded', function () {
    c.dest = document.getElementsByTagName('iframe')[0].contentWindow;
  }, false);
})();
