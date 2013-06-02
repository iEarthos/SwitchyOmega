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
import 'package:switchyomega/html/converters.dart' as convert;
import 'package:switchyomega/html/lib.dart';
import 'editors.dart';

List<Profile> modalCannotDeleteProfile_referring = [];
Profile modalDeleteProfile_profile = null;

String modalRenameProfile_newName = null;
String modalRenameProfile_oldName = null;

Profile modalDeleteRule_profile = null;
Rule modalDeleteRule_rule = null;

Profile modalResetRules_profile = null;
Profile modalResetRules_resultProfile = null;

String modalNewProfile_name = '';

void deleteProfile(Profile profile) {
  options.profiles.remove(profile);
  if (options.currentProfileName == profile.name) {
    options.currentProfileName = new DirectProfile().name;
  }
  if (options.startupProfileName == profile.name) {
    options.startupProfileName = null;
  }
  options.quickSwitchProfiles.remove(profile.name);

  if (profile is FixedProfile) {
    fixedProfileEditors.remove(profile);
  } else if (profile is SwitchProfile) {
    profile.forEach((rule) => ruleEditors.remove(rule));
  }

  watchers.dispatch();
}

void requestProfileDelete(Profile profile) {
  var ref = options.profiles.referredBy(profile);
  if (!ref.isEmpty) {
    // Cannot delete profile.
    modalCannotDeleteProfile_referring = ref.toList();
    js.send('modal.profile.cannotDelete', null, (_, [reply]) {
      // Modal closed.
      modalCannotDeleteProfile_referring = [];
    });
  } else {
    modalDeleteProfile_profile = profile;
    js.send('modal.profile.delete', null, (action, [reply]) {
      if (action == 'delete') {
        deleteProfile(profile);
        js.send('tab.set');
      }
      modalDeleteProfile_profile = null;
    });
  }
}

void requestProfileRename(Profile profile) {
  modalRenameProfile_newName = modalRenameProfile_oldName = profile.name;
  js.send('modal.profile.rename', null, (action, [reply]) {
    if (action == 'rename') {
      if (modalRenameProfile_newName != modalRenameProfile_oldName) {
        options.profiles.renameProfile(modalRenameProfile_oldName,
            modalRenameProfile_newName);
        watchers.dispatch();
        js.send('tab.set', '#profile-$modalRenameProfile_newName');
      }
    }
    modalRenameProfile_newName = modalRenameProfile_oldName = null;
  });
}

bool modalRenameProfile_isValid() {
  if (modalRenameProfile_newName == modalRenameProfile_oldName) return true;
  if (modalRenameProfile_newName.isEmpty) return false;
  if (options.profiles[modalRenameProfile_newName] != null) return false;
  return true;
}

bool modalNewProfile_isValid() {
  if (modalNewProfile_name.isEmpty) return false;
  if (options.profiles[modalNewProfile_name] != null) return false;
  return true;
}

String bypassListToText(List<BypassCondition> list) =>
    list.map((b) => b.pattern).join('\n');

void handleFixedServerUI() {
  dynamicEvent('change', '.bypass-list',  (e, TextAreaElement bypassList) {
    var profile_name = closestElement(bypassList, '.tab-pane')
        .attributes['data-profile'];
    var profile = options.profiles[profile_name] as FixedProfile;
    profile.bypassList = bypassList.value.split('\n')
        .map((l) => l.trim()).where((l) => !l.isEmpty)
        .map((l) => new BypassCondition(l))
        .toList();
    // Update the text in the textarea.
    bypassList.value = bypassListToText(profile.bypassList);
  });
}

void handlePacScriptsUI() {
//  dynamicEvent('change', '.pac-url',  (e, InputElement pacUrl) {
//    pacUrl.dispatchEvent(new Event('input'));
//  });
}

void handleSwitchProfileUI() {
  new EventStreamProvider('x-sort').forTarget(document).listen((Event e) {
    var target = e.target as Element;
    var profile_name = closestElement(target, '.tab-pane')
        .attributes['data-profile'];
    var profile = options.profiles[profile_name] as SwitchProfile;
    var index_old = int.parse(target.attributes['data-index-old']);
    var index_new = int.parse(target.attributes['data-index-new']);
    var rule = profile.removeAt(index_old);
    profile.insert(index_new, rule);
    watchers.dispatch();
  });
}

void moveRuleUp(SwitchProfile profile, Rule rule) {
  var index_old = profile.indexOf(rule);
  if (index_old > 0) {
    profile.removeAt(index_old);
    profile.insert(index_old - 1, rule);
  }
  watchers.dispatch();
}

void moveRuleDown(SwitchProfile profile, Rule rule) {
  var index_old = profile.indexOf(rule);
  if (index_old < profile.length - 1) {
    profile.removeAt(index_old);
    profile.insert(index_old + 1, rule);
  }
  watchers.dispatch();
}

void requestRemoveRule(SwitchProfile profile, Rule rule) {
  if (options.confirmDeletion) {
    modalDeleteRule_profile = profile;
    modalDeleteRule_rule = rule;
    js.send('modal.rule.delete', null, (action, [reply]) {
      if (action == 'delete') {
        removeRule(profile, rule);
      }
      modalDeleteRule_profile = null;
      modalDeleteRule_rule = null;
    });
  } else {
    removeRule(profile, rule);
  }
}

void removeRule(SwitchProfile profile, Rule rule) {
  profile.remove(rule);
  ruleEditors.remove(rule);
  watchers.dispatch();
}

List<Profile> validResultProfilesFor(InclusiveProfile profile) {
  return options.profiles.where((p) {
    if (p == profile || p is! IncludableProfile) return false;
    if (p is InclusiveProfile) if (p.hasReferenceTo(profile.name)) return false;
    return true;
  }).toList();
}

void addRule(SwitchProfile profile) {
  var condition = new HostWildcardCondition('*.example.com');
  var profileName = profile.length > 0 ?
      profile.last.profileName : profile.defaultProfileName;

  profile.add(new Rule(condition, profileName));
  watchers.dispatch();
}

void resetRules(SwitchProfile profile) {
  profile.forEach((rule) {
    rule.profileName = profile.defaultProfileName;
  });
  watchers.dispatch();
}

void requestResetRules(SwitchProfile profile) {
  modalResetRules_profile = profile;
  modalResetRules_resultProfile = options.profiles[profile.defaultProfileName];
  js.send('modal.rule.reset', null, (action, [reply]) {
    if (action == 'reset') {
      resetRules(profile);
    }
    modalResetRules_profile = null;
    modalResetRules_resultProfile = null;
  });
}

void handleRulelistUI() {

}

Communicator c = new Communicator(window.top);
Communicator js = new Communicator(window);
ObservableSwitchyOptions options = null;

List<String> profileTypes = ['FixedProfile',
                             'SwitchProfile',
                             'PacProfile',
                             'RulelistProfile'];

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
  var auto = options.profiles['auto'] as InclusiveProfile;
  print(auto.toScript());
}

String idBindingWorkaroundAttrName = 'data-workaround-id';

void idBindingWorkaround() {
  document.queryAll('[$idBindingWorkaroundAttrName]').forEach(
      (target) {
        bindToDataList(target);
      });

  MutationObserver ob = new MutationObserver(
      (List<MutationRecord> mutations, MutationObserver _) {
        mutations.forEach((MutationRecord record) {
          switch (record.type) {
            case 'attributes':
              var e = record.target as Element;
              e.id = e.attributes[idBindingWorkaroundAttrName];
              break;
            case 'childList':
              record.addedNodes.forEach((el) {
                if (el is Element) {
                  el.queryAll('[$idBindingWorkaroundAttrName]').forEach(
                      (Element e) {
                        e.id = e.attributes[idBindingWorkaroundAttrName];
                      });
                }
              });
              break;
          }
        });
      });
  ob.observe(document.documentElement,
      childList: true,
      attributes: true,
      subtree: true,
      attributeFilter: [idBindingWorkaroundAttrName]);
}

void handleNewProfileUI() {
  js.on('profile.create', (String type, [Function respond]) {
    Profile p = null;
    switch (type) {
      case 'FixedProfile':
        p = new FixedProfile(modalNewProfile_name);
        break;
      case 'PacProfile':
        p = new PacProfile(modalNewProfile_name);
        break;
      case 'SwitchProfile':
        p = new SwitchProfile(modalNewProfile_name, new DirectProfile().name);
        break;
      case 'RulelistProfile':
        throw new UnimplementedError();
    }
    if (p != null) {
      options.profiles.add(p);
      watchers.dispatch();
      js.send('tab.set', '#profile-$modalNewProfile_name');
    }
    modalNewProfile_name = '';
  });
}

void main() {
  idBindingWorkaround();
  c.send('options.get', null, (Map<String, Object> o, [Function respond]) {
    options = new ObservableSwitchyOptions.fromPlain(o['options']);
    watchers.dispatch();

    var lastActiveTab = o['tab'];
    var navs = queryAll('#options-nav a[data-toggle="tab"]');
    var nav = navs.firstWhere((e) => e.attributes['href'] == lastActiveTab,
        orElse: () => navs.first);
    closestElement(nav, 'li').classes.add('active');
    var tab = query(nav.attributes['href']);
    if (tab == null && nav.attributes['href'][0] == '#') {
      var id = nav.attributes['href'].substring(1);
      tab = query('[$idBindingWorkaroundAttrName="$id"]');
    }
    tab.classes.add('active');

    js.send('options.init');
  });

  handleFixedServerUI();
  handlePacScriptsUI();
  handleSwitchProfileUI();
  handleRulelistUI();
  autoBindToDataList(document.documentElement);

  handleNewProfileUI();
}

