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

library switchy_options;

import 'dart:html';
import 'dart:json' as JSON;
import 'package:switchyomega/browser/lib.dart';
import 'package:switchyomega/browser/message/lib.dart';
import 'package:switchyomega/communicator.dart';
import 'package:switchyomega/condition/lib.dart';
import 'package:switchyomega/lang/lib.dart';
import 'package:switchyomega/profile/lib.dart';
import 'package:web_ui/watcher.dart' as watchers;
import '../html/converters.dart' as convert;
import '../html/lib.dart';
import 'editors.dart';

String bypassListToText(List<BypassCondition> list) =>
  list.mappedBy((b) => b.pattern).join('\n');

void handleFixedServerUI() {
  dynamicEvent('change', '.bypass-list',  (e, TextAreaElement bypassList) {
    var profile_name = closestElement(bypassList, '.tab-pane')
        .attributes['data-profile'];
    var profile = options.profiles[profile_name] as FixedProfile;
    profile.bypassList = bypassList.value.split('\n')
        .mappedBy((l) => l.trim()).where((l) => !l.isEmpty)
        .mappedBy((l) => new BypassCondition(l))
        .toList();
    // Update the text in the textarea.
    bypassList.value = bypassListToText(profile.bypassList);
  });
}

void handlePacScriptsUI() {
  dynamicEvent('change', '.pac-url',  (e, InputElement pacUrl) {
    var pacScript = closestElement(pacUrl, '.tab-pane').query('.pac-script');
    if (pacUrl.value != '') {
      pacScript.attributes['disabled'] = 'disabled';
    } else {
      pacScript.attributes.remove('disabled');
    }
  });
}

void handleRulelistUI() {
  dynamicEvent('change', '.rule-list-url',  (e, InputElement rulelistUrl) {
    var rulelistText = closestElement(rulelistUrl, '.tab-pane').query('.rule-list-text');
    if (rulelistUrl.value != '') {
      rulelistText.attributes['disabled'] = 'disabled';
    } else {
      rulelistText.attributes.remove('disabled');
    }
  });
}

Communicator c = new Communicator(window.top);
Communicator js = new Communicator(window);
ObservableSwitchyOptions options = null;

Map<String, String> profileIcons = {
  'FixedProfile': 'icon-globe',
  'PacProfile': 'icon-tasks',
  'RulelistProfile': 'icon-list',
  'SwitchProfile': 'icon-retweet'
};

Map<FixedProfile, FixedProfileEditor> fixedProfileEditors =
    new Map<FixedProfile, FixedProfileEditor>();

Map<Rule, RuleEditor> ruleEditors = new Map<Rule, RuleEditor>();

// This is only for testing.
void exportPac() {
  ProfileCollection col = new ProfileCollection();
  col.addAll(options.profiles.values);
  var auto = col.getProfileByName('auto') as InclusiveProfile;
  print(auto.toScript());
}

void main() {
  c.send('options.get', null, (Map<String, Object> o, [Function respond]) {
    options = new ObservableSwitchyOptions.fromPlain(o);

    watchers.dispatch();

    // Setting select.value by binding will not have any effect
    // at the moment because the selects are empty.
    // The templating engine set select.value before iterating its
    // options, and the data list binding script (which works by
    // MutationObserver) is invoked even later. Both are too late.
    // We must add the options manually and then set the value again.
    window.requestLayoutFrame(() {
      queryAll('select[data-later-value]').forEach((SelectElement s) {
        if (s.nodes.length == 0) {
          // In case that the datalist binding script has not been invoked.
          var id = s.attributes[autoBindToDataListAttrName];
          var options = queryAll('#$id option');
          s.nodes.addAll(options.mappedBy((n) => n.clone(true)));
        }
        s.value = s.attributes['data-later-value'];
      });
    });

    queryAll('[data-workaround-id]').forEach((e) {
      e.id = e.attributes['data-workaround-id'];
    });
    js.send('options.init');
  });

  handleFixedServerUI();
  handlePacScriptsUI();
  handleRulelistUI();
  autoBindToDataList(document.documentElement);
}

