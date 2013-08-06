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
  var switchProfile = false;
  var canvasIcon = null;
  var profileColor = '';
  var currentProfileName = '';
  var urlParser = null;
  var dirtyTabs = {};

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

  c.on({
    'background.init': function (_, respond) {
    },
    'proxy.set': function (data, respond) {
      inclusiveProfile = data.inclusive;
      switchProfile = data['switch'];
      profileColor = data.color;
      currentProfileName = data.profileName;
      localStorage['currentProfileName'] = data.profileName;
      localStorage['possibleResults'] = JSON.stringify(data.possibleResults);
      resetAllIcons();
      chrome.browserAction.setTitle({
        title: chrome.i18n.getMessage('browserAction_titleNormal',
                  currentProfileName)
      });
      chrome.proxy.settings.set({value: data.config}, function () {
        respond();
      });
    },
    'proxy.get': function (_, respond) {
      chrome.proxy.settings.get({}, function (o) {
        respond(o);
      });
    },
    'proxy.listen': function () {
      if (!proxyListening) {
        chrome.proxy.settings.onChange.addListener(function (details) {
          c.send('proxy.onchange', details);
        });
        proxyListening = true;
      }
    },
    'options.get': function (_, respond) {
      if (!localStorage['options']) {
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
        respond({'options': JSON.parse(localStorage['options'])});
      }
    },
    'options.set': function (options, respond) {
      localStorage['options'] = options;
      respond();
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
        console.log(request.data);
        break;
      case 'options.update':
        c.send('options.update', JSON.parse(localStorage['options']));
        break;
    }
  });

  var setCurrentDomain = function (url) {
    if (!switchProfile || url == null || url.indexOf('chrome') == 0) {
      localStorage.removeItem('currentDomain');
    } else if (urlParser != null) {
      urlParser.href = url;
      localStorage['currentDomain'] = urlParser.hostname;
    }
  };

  var processTab = function (tabId, changeInfo, tab) {
    if (!inclusiveProfile) return;
    if (dirtyTabs.hasOwnProperty(tab.id)) {
      changeInfo.url = tab.url;
      delete dirtyTabs[tab.id];
    }
    if (changeInfo.url != null) {
      setCurrentDomain(changeInfo.url);
      if (changeInfo.url.indexOf('chrome') == 0) {
        setIcon(null, tabId);
        return;
      }
      c.send('profile.match', changeInfo.url, function (result) {
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
    if (!inclusiveProfile) return;
    if (!switchProfile && !dirtyTabs.hasOwnProperty(info.tabId)) return;
    chrome.tabs.get(info.tabId, function (tab) {
      if (dirtyTabs.hasOwnProperty(info.tabId)) {
        processTab(tab.id, {}, tab);
      } else {
        setCurrentDomain(tab.url);
      }
    });
  });

  document.addEventListener('DOMContentLoaded', function () {
    c.dest = document.getElementsByTagName('iframe')[0].contentWindow;

    canvasIcon = document.getElementById('canvas-icon');
    urlParser = document.getElementById('url-parser');
  }, false);
})();
