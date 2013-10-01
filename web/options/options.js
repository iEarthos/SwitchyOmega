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
  // Forbid direct view on this page
  if (window.top === window) {
    location.href = location.href.replace(".html", "_safe.html");
  }

  // Dart uses symbol $ in generated scripts.
  jQuery.noConflict();
  var $ = jQuery;

  var c = new Communicator(window.top);
  var dart = new Communicator(window);

  var i18n = null;
  c.send('i18n.cache', null, function (cache) {
    i18n = new i18nDict(cache);
    var MutationObserver = window.MutationObserver ||
                           window.WebKitMutationObserver;
    new MutationObserver(function (mutations) {
      mutations.forEach(function (record) {
        switch (record.type) {
          case 'attributes':
            i18nTemplate.process(record.target, i18n);
            break;
          case 'childList':
            for (var i = 0; i < record.addedNodes.length; i++) {
              if (record.addedNodes[i] instanceof Element) {
                i18nTemplate.process(record.addedNodes[i], i18n);
              }
            }
            break;
        }
      });
    }).observe(document, {
        childList: true,
        attributes: true,
        subtree: true
    });
    i18nTemplate.process(document, i18n);
  });

  var lastTab = null;

  c.on({
    'options.init': function () {
      // Sortable
      var containers = $('.cycle-profile-container');
      containers.sortable({
        connectWith: '.cycle-profile-container',
        tolerance: 'pointer',
        axis: 'y',
        forceHelperSize: true,
        forcePlaceholderSize: true,
        update: function () {
          dart.send('quickswitch.update');
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
      });
      $('#quick-switch').change();

      // Memorize Tab
      $('#options-nav').on('shown', 'a[data-toggle="tab"]', function (e) {
        lastTab = e.target.getAttribute('href');
        c.send('tab.set', lastTab);
      });

      // Restore options from local files.
      $('#restore-local').on('click', function (e) {
        $('#restore-local-file').click();
      });
    },
    'quickswitch.refresh': function () {
      $('.cycle-profile-container').sortable('refresh');
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
    'modal.profile.delete': function (_, reply) {
      var modal = $('#modal-profile-delete');
      var button = $('#profile-delete-confirm');
      var on_click = function () {
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('delete');
      };
      var on_hidden = function () {
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('dismiss');
      };
      button.on('click', on_click);
      modal.on('hidden', on_hidden);
      modal.modal();
    },
    'modal.profile.cannotDelete': function (_, reply) {
      var modal = $('#modal-profile-cannot-delete');
      var on_hidden = function () {
        modal.off('hidden', on_hidden);
        reply();
      };
      modal.on('hidden', on_hidden);
      modal.modal();
    },
    'modal.profile.rename': function (_, reply) {
      var modal = $('#modal-profile-rename');
      var button = $('#profile-rename-save');
      var on_click = function () {
        if (button.is('.disabled')) {
          return false;
        }
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('rename');
      };
      var on_hidden = function () {
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('dismiss');
      };
      button.on('click', on_click);
      modal.on('hidden', on_hidden);
      modal.modal();
    },
    'modal.rule.delete': function (_, reply) {
      var modal = $('#modal-rule-delete');
      var button = $('#rule-delete-confirm');
      var on_click = function () {
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('delete');
      };
      var on_hidden = function () {
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('dismiss');
      };
      button.on('click', on_click);
      modal.on('hidden', on_hidden);
      modal.modal();
    },
    'modal.rule.reset': function (_, reply) {
      var modal = $('#modal-rule-reset');
      var button = $('#rule-reset-confirm');
      var on_click = function () {
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('reset');
      };
      var on_hidden = function () {
        modal.off('hidden', on_hidden);
        button.off('click', on_click);
        reply('dismiss');
      };
      button.on('click', on_click);
      modal.on('hidden', on_hidden);
      modal.modal();
    },
    'file.saveAs': function (data, reply) {
      saveAs(new Blob([data.content]), data.name);
    }
  });

  $(document).ready(function () {
    // Conditions Sort
    var MutationObserver = window.MutationObserver ||
                           window.WebKitMutationObserver;
    new MutationObserver(function (mutations) {
      mutations.forEach(function (record) {
        switch (record.type) {
          case 'childList':
            for (var i = 0; i < record.addedNodes.length; i++) {
              if (record.addedNodes[i] instanceof Element) {
                $('.conditions', record.addedNodes[i]).each(function (_, e) {
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
                      ui.item.attr('data-index-old',
                          ui.item.data('index-old'));
                      ui.item.attr('data-index-new', ui.item.index());

                      var evt = document.createEvent('CustomEvent');
                      evt.initCustomEvent('x-sort', true, false, null);
                      ui.item[0].dispatchEvent(evt);

                      ui.item.removeAttr('data-index-old');
                      ui.item.removeAttr('data-index-new');
                    }
                  });
                });
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

    // Create new profiles
    $('body').on('click', '#profile-new-create', function (e) {
      if ($('#profile-new-create').is('.disabled')) return;
      var type = $('input[name="profile-new-type"]:checked').val();
      dart.send('profile.create', type);
    });

    // Undo changes
    $('body').on('click', '#undo-changes-confirm', function (e) {
      dart.send('options.undo', null);
    });

    // Reset options
    $('body').on('click', '#reset-options-confirm', function (e) {
      if ($('#reset-options-confirm').is('.disabled')) return;
      dart.send('options.reset', null);
    });

    // Click anywhere to close alert.
    $(document).on('click', function (e) {
      $('.alert').css('top', '-100%');
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
              button.find('i').removeClass('icon-repeat').addClass('icon-remove');
              input.off(eventMap);
            }
          };
          var eventMap = {'change': handler, 'keyup': handler, 'keydown': handler};
          input.on(eventMap);
        }
      }
    });
  });

})();
