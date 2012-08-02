'use strict';
// Forbid direct view on this page
if (window.top === window) {
  location.href = location.href.replace(".html", "_safe.html");
}

var c = new Communicator(window.top);

// Get memorized tabs
var isDocReady = false;
var showTabInner = function (hash) {
  $('#options-nav a[href="' + hash + '"]').tab('show');
};
var showTab = function (hash) {
  if (isDocReady) {
    showTabInner(hash);
  } else {
    $(document).ready(function () {
      showTabInner(hash);
    });
  }
};

if (location.hash) {
  showTab(location.hash);
  location.hash = '';
} else {
  c.send('tab.get', null, function (hash) {
    if (hash) {
      showTab(hash);
    }
  });
}

var i18n = null;
c.send('i18n.cache', null, function (cache) {
  i18n = new i18nDict(cache);
  document.addEventListener('DOMNodeInserted', function (e) {
    if (e.target instanceof Element) {
      i18nTemplate.process(e.target, i18n);
    }
  }, false);
  i18nTemplate.process(document, i18n);
});

$(document).ready(function () {
  isDocReady = true;
  // Sortable
  var containers = $('.cycle-profile-container');
  containers.sortable({
    connectWith: '.cycle-profile-container',
    change: function () {
      // onFieldModified(false);
    }
  }).disableSelection();
  var quickSwitch = $('#quick-switch');
  quickSwitch.change(function () {
    if (quickSwitch[0].checked) {
      containers.sortable('enable');
      $('#quick-switch-settings').slideDown();
    } else {
      containers.sortable('disable');
      $('#quick-switch-settings').slideUp();
    }
  })
  
  // Memorize Tab
  $('#options-nav a[data-toggle="tab"]').on('shown', function (e) {
    var tabHash = e.target.getAttribute('href');
    c.send('tab.set', tabHash);
  });
});