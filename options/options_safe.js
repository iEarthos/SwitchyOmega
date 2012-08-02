'use strict';
var i18nCache = {};
strings.forEach(function (name) {
  i18nCache[name] = chrome.i18n.getMessage(name);
});

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
  }
});



document.addEventListener('DOMContentLoaded', function () {
  c.dest = document.getElementsByTagName('iframe')[0].contentWindow;
}, false);