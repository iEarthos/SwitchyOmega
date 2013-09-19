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

  var storage = chrome.storage.local;

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
      storage.get(null, function (items) {
        respond({
          'options': items,
          'tab': localStorage['options_last_tab'],
          'currentProfileName': localStorage['currentProfileName'] || 'direct'
        });
      });
    },
    'options.reset': function (data, respond) {
      chrome.runtime.sendMessage({
        action: 'options.reset'
      }, function () {
        respond(JSON.parse(localStorage['options']));
      });
    },
    'options.set': function (data, respond) {
      localStorage['options'] = data;
      chrome.runtime.sendMessage({
        action: 'options.update'
      });
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
    'storage.get': function (keys, respond) {
      storage.get(keys, respond);
    },
    'storage.set': function (items, respond) {
      storage.set(items, respond);
    },
    'storage.remove': function (keys, respond) {
      storage.remove(keys, respond);
    }
  });

  document.addEventListener('DOMContentLoaded', function () {
    c.dest = document.getElementsByTagName('iframe')[0].contentWindow;
  }, false);
})();
