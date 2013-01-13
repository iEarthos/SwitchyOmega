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
import "package:switchyomega/browser/lib.dart";
import "package:switchyomega/browser/message/lib.dart";
import "package:switchyomega/communicator.dart";

void handleFixedServerUI() {
  dynamicEvent('change', '.use-same-proxy',  (e, InputElement check) {
    var proxies = closestElement(check, '.fixed-servers').queryAll('.proxy-for-scheme');
    if (check.checked) {
      proxies.forEach((p) { p.style.display = 'none'; });
    } else {
      proxies.forEach((p) { p.style.display = 'table-row'; });
    }
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
ObservableSwitchyOptions options = null;

void main() {
  c.send('options.get', null, (Map<String, Object> o, [Function respond]) {
    options = new ObservableSwitchyOptions.fromPlain(o);
  });

  handleFixedServerUI();
  handlePacScriptsUI();
  handleRulelistUI();
  autoBindToDataList(document.documentElement);
}

