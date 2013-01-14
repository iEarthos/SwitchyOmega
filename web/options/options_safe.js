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

'use strict';
var i18nCache = {};
strings.forEach(function (name) {
  i18nCache[name] = chrome.i18n.getMessage(name);
});

// Set the title
document.title = i18nCache['options_title'];

var c = new Communicator();

c.on({
  'tab.get': function (_, respond) {
    var hash;
    if (location.hash) {
      hash = location.hash;
      location.hash = '';
    } else {
      hash = localStorage['options_last_tab'];
    }
    respond([hash]);
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
  	respond({
  	  // The profiles are from the pac_gen_test.
  	  'date': true,
  	  'test': 'fail',
  	  'profiles': {
  	    'ssh' : {
  	      "name":"ssh",
  	      "profileType":"FixedProfile",
  	      "fallbackProxy":{"scheme":"socks5","port":7070,"host":"127.0.0.1"},
  	      "bypassList":[
  	        {"pattern":"127.0.0.1:3333","conditionType":"BypassCondition"},
  	        {"pattern":"https://www.example.com","conditionType":"BypassCondition"},
  	        {"pattern":"*:3333","conditionType":"BypassCondition"},
  	        {"pattern":"<local>","conditionType":"BypassCondition"}
  	      ],
  	      "color":"#0000cc",
  	      "proxyForHttp":{"scheme":"http","port":8080,"host":"127.0.0.1"}
  	    },
  	    "http": {
  	      "name":"http",
  	      "profileType":"FixedProfile",
  	      "color":"#0000cc",
  	      "fallbackProxy":{"scheme":"http","port":8888,"host":"127.0.0.1"},
  	      "bypassList":[]
  	    },
  	    "script" : {
  	      "name":"script",
  	      "profileType":"PacProfile",
  	      "color":"#0000cc",
  	      "pacUrl":"http://example.com/proxy.pac",
  	      "pacScript":"\
		    var FindProxyForURL = function (url, host) {\n\
		      if (host == 'www.example.com') {\n\
		        return 'SOCKS5 127.0.0.1:7070';\n\
		      }\n\
		      if (host == 'www2.example.com') {\n\
		        return 'PROXY 127.0.0.1:8888';\n\
		      }\n\
		      return 'DIRECT';\n\
		    };"
  	    },
  	    "auto": {
  	      "name":"auto",
  	      "profileType":"SwitchProfile",
  	      "color":"#0000cc",
  	      "defaultProfileName":"http",
  	      "rules":[
  	        {"profileName":"ssh","condition":{"pattern":"*.example.com","conditionType":"HostWildcardCondition"}},
  	        {"profileName":"direct","condition":{"minValue":0,"conditionType":"HostLevelsCondition","maxValue":0}},
  	        {"profileName":"ssh","condition":{"pattern":"foo","conditionType":"KeywordCondition"}}
  	      ]
  	    },
  	    'direct' : { 'name': 'direct', 'profileType': 'DirectProfile' },
  	    'system' : { 'name': 'system', 'profileType': 'SystemProfile' }
  	  },
  	  'quickSwitchProfiles' : []
  	});
  }
});

document.addEventListener('DOMContentLoaded', function () {
  c.dest = document.getElementsByTagName('iframe')[0].contentWindow;
}, false);