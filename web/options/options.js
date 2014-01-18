/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS
 * file for details.
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
  /* jshint jquery: true */
  /* global chrome: false, Communicator: false, strings: false */
  /* global i18nDict: false, i18nTemplate: false */

  // Dart uses symbol $ in generated scripts.
  jQuery.noConflict();
  var $ = jQuery;

  // document.register is renamed to document.registerElement recently.
  document.register = document.register || document.registerElement;

  var storage = chrome.storage.local;

  var dart = new Communicator(window);

  var i18nCache = {};
  strings.forEach(function (name) {
    i18nCache[name] = chrome.i18n.getMessage(name);
  });
  var i18n = new i18nDict(i18nCache); // jshint ignore:line
  window.i18n = new i18nDict(i18nCache); // jshint ignore:line

  var MutationObserver = window.MutationObserver ||
    window.WebKitMutationObserver;
  var ob = new MutationObserver(function (mutations) {
    mutations.forEach(function (record) {
      switch (record.type) {
        case 'attributes':
          i18nTemplate.process(record.target, i18n);
          break;
        case 'childList':
          for (var i = 0; i < record.addedNodes.length; i++) {
            var ele = record.addedNodes[i];
            if (ele instanceof Element) {
              i18nTemplate.process(ele, i18n);
            }
          }
          break;
      }
    });
  });
  ob.observe(document, {
    childList: true,
    attributes: true,
    subtree: true
  });
  window.onShadowHostReady = function (shadowHost) {
    var shadowRoot = shadowHost.shadowRoot || shadowHost.webkitShadowRoot ||
        shadowHost.mozShadowRoot;
    // Use shadowHost in case that Shadow DOM is being polyfilled.
    shadowRoot = shadowRoot || shadowHost;
    i18nTemplate.process(shadowRoot, i18n);
    ob.observe(shadowRoot, {
      childList: true,
      attributes: true,
      subtree: true
    });
  };
  i18nTemplate.process(document, i18n);

  window.bsShowModal = function (modal) {
    modal = $(modal);
    if (!modal.data('bs-modal-handler')) {
      modal.on('hide', function () {
        modal[0].dispatchEvent(new CustomEvent('modalhide'));
      });
      modal.data('bs-modal-handler', 'installed');
    }
    modal.modal('show');
  };
  window.bsHideModal = function (modal) {
    $(modal).modal('hide');
  };

  var lastTab = location.hash || localStorage['options_last_tab'];
  var loadOptions = function (respond) {
    storage.get(null, function (items) {
      respond({
        'options': items,
        'tab': localStorage['options_last_tab'],
        'currentProfileName': localStorage['currentProfileName'] || 'direct'
      });
    });
  };

  dart.on({
    'options.init': function () {
      // Sortable
      var containers = $('.cycle-profile-container');
      containers.sortable({
        connectWith: '.cycle-profile-container',
        tolerance: 'pointer',
        axis: 'y',
        forceHelperSize: true,
        forcePlaceholderSize: true
      }).disableSelection();
      $('#cycle-enabled').sortable({
        update: function () {
          dart.send('quickswitch.update');
        }
      });
      containers.data('cycleSortable', 'true');

      // Memorize Tab
      $('#options-nav').on('shown', 'a[data-toggle="tab"]', function (e) {
        lastTab = e.target.getAttribute('href');
        localStorage['options_last_tab'] = lastTab;
      });

      // Restore options from local files.
      $('#restore-local').on('click', function () {
        $('#restore-local-file').click();
      });
    },
    'quickswitch.refresh': function () {
      var containers = $('.cycle-profile-container');
      if (containers.data('cycleSortable')) {
        containers.sortable('refresh');
      }
    },
    'tab.set': function (tabhref) {
      tabhref = tabhref || lastTab;
      var tabs = $('#options-nav a[data-toggle="tab"]');
      var tab = null;
      if (tabhref) {
        tabs.each(function (_, e) {
          if (e.getAttribute('href') === tabhref) {
            tab = $(e);
            lastTab = tabhref;
          }
        });
      }
      if (tab === null) {
        tab = tabs.first();
      }
      tab.tab('show');
    },
    'file.saveAs': function (data, reply) {
      /* global saveAs: false */
      saveAs(new Blob([data.content]), data.name);
      reply();
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
    'error.log': function (data) {
      window.onerror(data.message, data.url, data.line);
    },
    'options.get': function (data, respond) {
      loadOptions(respond);
    },
    'options.reset': function (data, respond) {
      chrome.runtime.sendMessage({
        action: 'options.reset'
      }, function () {
        loadOptions(respond);
      });
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
    }
  });

  $(document).ready(function () {
    // Conditions Sort
    var MutationObserver = window.MutationObserver ||
                           window.WebKitMutationObserver;
    new MutationObserver(function (mutations) {
      var handleConditions = function (_, e) {
        var tb = $(e);
        tb.disableSelection().sortable({
          handle: '.sort-bar',
          tolerance: 'pointer',
          axis: 'y',
          forceHelperSize: true,
          forcePlaceholderSize: true,
          containment: 'parent',
          start: function (e, ui) {
            ui.item.data('index-old', ui.item.index());
          },
          update: function (e, ui) {
            ui.item.attr('data-index-old', ui.item.data('index-old'));
            ui.item.attr('data-index-new', ui.item.index());
            var evt = document.createEvent('CustomEvent');
            evt.initCustomEvent('x-sort', true, false, null);
            ui.item[0].dispatchEvent(evt);

            ui.item.removeAttr('data-index-old');
            ui.item.removeAttr('data-index-new');
          }
        });
      };
      mutations.forEach(function (record) {
        switch (record.type) {
          case 'childList':
            for (var i = 0; i < record.addedNodes.length; i++) {
              if (record.addedNodes[i] instanceof Element) {
                $('.conditions', record.addedNodes[i]).each(handleConditions);
              }
            }
            break;
        }
      });
    }).observe(document, {
      childList: true,
      subtree: true
    });

    var fireInputAndChangeEvent = function (target) {
      var evt = document.createEvent('HTMLEvents');
      evt.initEvent('input', true, false);
      target.dispatchEvent(evt);

      evt = document.createEvent('HTMLEvents');
      evt.initEvent('change', true, true);
      target.dispatchEvent(evt);
    };

    // Click anywhere to close alert.
    $(document).on('click', function () {
      $('#alert')[0].dispatchEvent(new CustomEvent('alerthide'));
    });

    // Clear input
    $('body').on('click', '.clear-input', function (e) {
      var button = $(e.target).closest('.clear-input');
      var input = button.prev('input');
      if (button.hasClass('revert')) {
        input.val(input.attr('data-restore'));
        fireInputAndChangeEvent(input[0]);
        button.removeClass('revert');
        button.find('i').removeClass('icon-repeat').addClass('icon-remove');
      } else {
        var v = input.val();
        if (v) {
          input.attr('data-restore', v);
          input.val('');
          fireInputAndChangeEvent(input[0]);
          button.addClass('revert');
          button.find('i').removeClass('icon-remove').addClass('icon-repeat');
          var handler = function () {
            if (input.val()) {
              button.removeClass('revert');
              $('i', button).removeClass('icon-repeat').addClass('icon-remove');
              input.off(eventMap);
            }
          };
          var eventMap = {'change': handler, 'keyup': handler,
            'keydown': handler};
          input.on(eventMap);
        }
      }
    });
  });

})();
