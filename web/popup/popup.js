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

  var i18n = new i18nDict(i18nCache);
  document.addEventListener('DOMNodeInserted', function (e) {
    if (e.target instanceof Element) {
      i18nTemplate.process(e.target, i18n);
    }
  }, false);

  var isDocReady = false;
  var options = null;
  var currentDomain = null;
  var currentProfile = null;
  var profileIcons = {
    'FixedProfile': 'icon-globe',
    'PacProfile': 'icon-tasks',
    'RulelistProfile': 'icon-list',
    'SwitchProfile': 'icon-retweet',
    'SwitchyRuleListProfile': 'icon-list',
    'AutoProxyRuleListProfile': 'icon-list'
  };

  $(document).ready(function () {
    isDocReady = true;
    i18nTemplate.process(document, i18n);
    $(document).on('click', '.profile a', function (e) {
      e.preventDefault();
      chrome.runtime.sendMessage({
        action: 'profile.apply',
        data: $(e.target).data('name')
      });
      window.close();
    });
    $(document).on('click', '#temp-rule-profiles a', function (e) {
      e.preventDefault();
      chrome.runtime.sendMessage({
        action: 'tempRules.add',
        data: {
          name: $(e.target).data('name'),
          domain: currentDomain
        }
      });
      window.close();
    });

    $('#add-condition').click(function () {
      $('.nav').hide();
    var profile = options['profiles'][options['currentProfileName']];
      $('#condition-form .profile-color').css('background',
          currentProfile.color);
      $('#condition-form .profile-name').text(currentProfile.name);

      var currentDomainEscaped = currentDomain.replace('.', '\\.');
      var conditionSuggestion = {
        'HostWildcardCondition': '*.' + currentDomain,
        'HostRegexCondition': '(^|\\.)' + currentDomainEscaped + '$',
        'UrlWildcardCondition': '*://*.' + currentDomain + '/*',
        'UrlRegexCondition':
            '://([^/.]+\\.)*' + currentDomainEscaped + '/',
        'KeywordCondition': currentDomain
      };

      if (localStorage['popup_conditionType'] == null) {
        localStorage['popup_conditionType'] = 'HostWildcardCondition';
      }
      $('#condition-type').change(function (e) {
        $('#condition-details').val(conditionSuggestion[e.target.value]);
        localStorage['popup_conditionType'] = e.target.value;
      });
      $('#condition-type').val(localStorage['popup_conditionType']);
      $('#condition-type').change();

      var conditionResult = $('#condition-result');
      // TODO(catus): Use possible result profiles for conditionResult.
      options['profiles'].forEach(function (profile) {
        var option = $('<option/>');
        option.text(profile.name);
        conditionResult.append(option);
      });

      $('#condition-form').show();

      $('#condition-cancel').click(function () {
        window.close();
      });
      $('#condition-ok').click(function () {
        chrome.runtime.sendMessage({
          action: 'condition.add',
          data: {
            profile: currentProfile.name,
            type: $('#condition-type').val(),
            details: $('#condition-details').val(),
            result: $('#condition-result').val()
          }
        });
        window.close();
      });

    });

    options = JSON.parse(localStorage['options']);
    currentDomain = localStorage['currentDomain'];

    switch (options['currentProfileName']) {
      case 'direct':
      case 'system':
      case 'autodetect':
        $('#profile-' + options['currentProfileName']).addClass('active');
        break;
    }

    var pos = $('#profiles-divider');
    var tempProfiles = $('#temp-rule-profiles');
    options['profiles'].forEach(function (profile) {
      var a = $('<a/>');
      a.attr('href', '#');
      a.text(profile.name);
      var i = $('<i/>');
      i.addClass(profileIcons[profile.profileType]);
      a.prepend(i);
      var li = $('<li/>');
      li.addClass('profile');
      li.append(a);
      li.data('name', profile.name);
      if (profile.name === options['currentProfileName']) {
        li.addClass('active');
        if (profile.profileType === 'SwitchProfile' && currentDomain != null) {
          $('#current-domain').text(currentDomain);
        } else {
          $('.show-switch').hide();
        }
        currentProfile = profile;
      }
      li.insertAfter(pos);
      pos = li;
      // TODO(catus): Use possible result profiles for tempProfiles.
      tempProfiles.append(li.clone());
    });
  });
})();
