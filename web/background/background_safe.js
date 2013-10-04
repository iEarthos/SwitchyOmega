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

  var c = new Communicator();

  var proxyListening = false;
  var inclusiveProfile = false;
  var readonly = false;
  var canvasIcon = null;
  var profileColor = '';
  var currentProfileName = '';
  var urlParser = null;
  var dirtyTabs = {};
  var pendingAlarms = [];
  var optionsResetRespond = null;
  var possibleResults = false;
  var storage = chrome.storage.local;

  var setIcon = function (resultColor, tabId) {
    if (canvasIcon == null) return;
    var ctx = canvasIcon.getContext('2d');
    if (resultColor != null) {
      drawOmega(ctx, resultColor, profileColor);
    } else {
      drawOmega(ctx, profileColor);
    }
    if (tabId != null) {
      chrome.browserAction.setIcon({
        imageData: ctx.getImageData(0, 0, 19, 19),
        tabId: tabId
      });
    } else {
      chrome.browserAction.setIcon({
        imageData: ctx.getImageData(0, 0, 19, 19)
      });
    }
  };

  var resetAllIcons = function () {
    chrome.tabs.query({}, function (tabs) {
      dirtyTabs = {};
      tabs.forEach(function (tab) {
        if (inclusiveProfile) {
          dirtyTabs[tab.id] = tab.id;
          if (tab.active) {
            processTab(tab.id, {}, tab);
          }
        } else {
          setIcon(null, tab.id);
        }
      });
    });
    setIcon();
  };

  var onProxyChange = function (details) {
    if (details['levelOfControl'] !== 'controlled_by_this_extension') {
      c.send('proxy.onchange', details);
    }
  };
  
  delete localStorage['seriousError'];

  chrome.browserAction.setBadgeText({text: ''});
  
  c.on({
    'background.init': function (_, respond) {
      var alarms = {};
      pendingAlarms.forEach(function (alarm) {
        // Fire at most once on each alarm.
        if (!alarms.hasOwnProperty(alarm)) {
          c.send('alarm.fire', alarm);
          alarms[alram] = alarm;
        }
      });
      pendingAlarms = null;
    },
    'proxy.set': function (data, respond) {
      inclusiveProfile = data.inclusive;
      profileColor = data.color;
      if (currentProfileName == '') {
        chrome.browserAction.setBadgeText({text: ''});
      }
      currentProfileName = data.displayName;
      localStorage['currentProfileName'] = data.currentProfile;
      localStorage['currentProfileReadOnly'] = data.readonly;
      possibleResults = !!data.possibleResults;
      localStorage['possibleResults'] = JSON.stringify(data.possibleResults);
      resetAllIcons();
      chrome.browserAction.setTitle({
        title: chrome.i18n.getMessage('browserAction_titleNormal',
                  currentProfileName)
      });
      if (data.config == null) return;
      var onProxySet = function () {
        if (data.refresh) {
          chrome.tabs.query({
            active: true,
            lastFocusedWindow: true
          }, function (tabs) {
            var tab = tabs[0];
            // Avoid reloading chrome or extension pages.
            if (tab.url != null && tab.url.indexOf('chrome') != 0) {
              chrome.tabs.reload(/* the selected tab of the current window */);
            }
          })
        }
        respond();
      };
      if (data.config['mode'] == 'system') {
        // Clear proxy settings, returning proxy control to Chromium.
        chrome.proxy.settings.clear({}, onProxySet);
      } else {
        chrome.proxy.settings.set({value: data.config}, onProxySet);
      }
    },
    'proxy.get': function (_, respond) {
      chrome.proxy.settings.get({}, onProxyChange);
    },
    'proxy.listen': function () {
      if (!proxyListening) {
        chrome.proxy.settings.onChange.addListener(onProxyChange);
        proxyListening = true;
      }
    },
    'options.get': function (_, respond) {
      storage.get(null, function (items) {
        if (items['schemaVersion'] == null) {
          // First run or upgrading from SwichySharp.
          var oldOptions = null;
          if (localStorage['config']) {
            oldOptions = {};
            for (key in localStorage) {
              if (localStorage.hasOwnProperty(key)) {
                oldOptions[key] = localStorage[key];
              }
            }
          }
          respond({'oldOptions': oldOptions});
        } else {
          respond({
            'options': items,
            'currentProfileName': localStorage['currentProfileName']
          });
        }
      });
    },
    'options.set': function (options, respond) {
      localStorage['options'] = options;
      respond();
    },
    'ajax.get': function (url, respond) {
      jQuery.ajax({
        url: url,
        cache: false,
        dataType: 'text',
        success: function (data) {
          respond({'data': data});
        },
        error: function (_, status, error) {
          respond({'status': status, 'error': error});
        }
      });
    },
    'alarm.set': function (details, respond) {
      if (details['periodInMinutes'] < 0) {
        chrome.alarms.clear(details['name']);
      } else {
        chrome.alarms.create(details['name'], {
          delayInMinutes: details['periodInMinutes'],
          periodInMinutes: details['periodInMinutes']
        });
      }
    },
    'state.set': function (details, respond) {
      chrome.browserAction.setBadgeText({
        text: details['badge']
      });
      var colors = {
        'info': '#49afcd',
        'success': '#5bb75b',
        'warning': '#faa732',
        'error': '#da4f49'
      };
      chrome.browserAction.setBadgeBackgroundColor({
        color: colors[details['type']]
      });

      switch (details['reason']) {
        case 'download':
          chrome.browserAction.setTitle({
            title: chrome.i18n.getMessage('browserAction_titleDownloadFail')
          });
          break;
        case 'schemaVersion':
          localStorage['seriousError'] = 'schemaVersion';
          chrome.browserAction.setTitle({
            title: chrome.i18n.getMessage('browserAction_titleNewerOptions')
          });
          break;
        case 'options':
          localStorage['seriousError'] = 'options';
          chrome.browserAction.setTitle({
            title: chrome.i18n.getMessage('browserAction_titleOptionError')
          });
          break;
        case 'externalProxy':
          chrome.browserAction.setTitle({
            title: chrome.i18n.getMessage('browserAction_titleExternalProxy')
          });
          break;
      }
    },
    'storage.get': function (keys, respond) {
      storage.get(keys, respond);
    },
    'storage.set': function (items, respond) {
      storage.set(items, respond);
    },
    'storage.remove': function (keys, respond) {
      if (keys == null) {
        storage.clear(respond);
      } else {
        storage.remove(keys, respond);
      }
    },
    'storage.watch': function () {
      chrome.storage.onChanged.addListener(function(changes, namespace) {
        if (namespace == 'local') {
          c.send('storage.onchange', changes);
        }
      });
    },
    'error.log': function (data) {
      window.onerror(data.message, data.url, data.line);
    }
  });

  chrome.runtime.onMessage.addListener(function (request, sender, respond) {
    switch (request.action) {
      case 'profile.apply':
        c.send('profile.apply', request.data);
        break;
      case 'tempRules.add':
        c.send('tempRules.add', request.data);
        break;
      case 'condition.add':
        c.send('condition.add', request.data);
        break;
      case 'externalProfile.add':
        c.send('externalProfile.add', request.data);
        break;
      case 'options.update':
        c.send('options.update', JSON.parse(localStorage['options']));
        break;
      case 'options.reset':
        c.send('options.reset', null, function () {
          respond();
        });
        return true;
    }
  });

  var setCurrentDomain = function (url) {
    if (!possibleResults || url == null || url.indexOf('chrome') == 0) {
      localStorage.removeItem('currentDomain');
    } else if (urlParser != null) {
      urlParser.href = url;
      localStorage['currentDomain'] = urlParser.hostname;
    }
  };

  var processTab = function (tabId, changeInfo, tab) {
    if (dirtyTabs.hasOwnProperty(tab.id)) {
      delete dirtyTabs[tab.id];
    }
    if (tab.url != null) {
      setCurrentDomain(tab.url);
      if (!inclusiveProfile) return;
      if (tab.url.indexOf('chrome') == 0) {
        setIcon(null, tabId);
        return;
      }
      c.send('profile.match', tab.url, function (result) {
        localStorage['currentMatch'] = result.name;
        setIcon(result.color, tabId);
        chrome.browserAction.setTitle({
          title: chrome.i18n.getMessage('browserAction_titleWithResult',
                   [currentProfileName, result.name, result.details]),
          tabId: tabId
        });
      });
    }
  };

  chrome.tabs.onUpdated.addListener(processTab);
  chrome.tabs.onActivated.addListener(function (info) {
    if (!possibleResults && !dirtyTabs.hasOwnProperty(info.tabId)) return;
    chrome.tabs.get(info.tabId, function (tab) {
      if (inclusiveProfile && dirtyTabs.hasOwnProperty(info.tabId)) {
        processTab(tab.id, {}, tab);
      } else {
        setCurrentDomain(tab.url);
      }
    });
  });

  chrome.alarms.onAlarm.addListener(function (alarm) {
    if (pendingAlarms != null) {
      pendingAlarms.push(alarm.name);
    } else {
      c.send('alarm.fire', alarm.name);
    }
  });

  document.addEventListener('DOMContentLoaded', function () {
    c.dest = document.getElementsByTagName('iframe')[0].contentWindow;

    canvasIcon = document.getElementById('canvas-icon');
    urlParser = document.getElementById('url-parser');
  }, false);
})();
