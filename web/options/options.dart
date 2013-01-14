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
import 'dart:json';
import '../html/lib.dart';
import "package:switchyomega/profile/lib.dart";
import "package:switchyomega/browser/lib.dart";
import "package:switchyomega/browser/message/lib.dart";
import "package:switchyomega/communicator.dart";
import 'package:web_ui/watcher.dart' as watchers;

void handleFixedServerUI() {
  
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
ObservableSwitchyOptions options = null;

Map<String, String> profileIcons = {
  'FixedProfile': 'icon-globe',
  'PacProfile': 'icon-tasks',
  'RulelistProfile': 'icon-list',
  'SwitchProfile': 'icon-retweet'
};

bool isSameProxyUsed(FixedProfile profile) {
  return profile.proxyForHttp == null &&
      profile.proxyForHttps == null && 
      profile.proxyForFtp == null;
}

List<Map<String, Object>> proxySchemesOf(FixedProfile profile) {
  return [
    { 'name': 'HTTP', 'proxy': profile.proxyForHttp },
    { 'name': 'HTTPS', 'proxy': profile.proxyForHttps },
    { 'name': 'FTP', 'proxy': profile.proxyForFtp }
  ];
}

String test = "fail";

void main() {
  c.send('options.get', null, (Map<String, Object> o, [Function respond]) {
    options = new ObservableSwitchyOptions.fromPlain(o);
    watchers.dispatch();
    queryAll('[data-workaround-id]').forEach((e) {
      e.id = e.attributes['data-workaround-id'];
    });
  });

  handleFixedServerUI();
  handlePacScriptsUI();
  handleRulelistUI();
  autoBindToDataList(document.documentElement);
}

