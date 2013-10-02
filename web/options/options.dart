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

library switchy_options;

import 'dart:html';
import 'dart:json' as JSON;
import 'dart:async';
import 'package:web_ui/web_ui.dart';
import 'package:crypto/crypto.dart';
import 'package:switchyomega/switchyomega.dart';
import 'package:switchyomega/html/converters.dart' as convert;
import 'package:switchyomega/browser/lib.dart';
import 'package:switchyomega/browser/message/lib.dart';
import 'package:switchyomega/communicator.dart';
import 'editors.dart';

@observable
List<Profile> modalCannotDeleteProfile_referring = toObservable([]);
@observable
Profile modalDeleteProfile_profile = null;

@observable
String modalRenameProfile_newName = null;
@observable
String modalRenameProfile_oldName = null;

@observable
Profile modalDeleteRule_profile = null;
@observable
Rule modalDeleteRule_rule = null;

@observable
Profile modalResetRules_profile = null;
@observable
Profile modalResetRules_resultProfile = null;

@observable
String modalNewProfile_name = '';

@observable
String currentProfileName = '';

void deleteProfile(Profile profile) {
  options.profiles.remove(profile);
  if (currentProfileName == profile.name) {
    currentProfileName = new DirectProfile().name;
  }
  if (options.startupProfileName == profile.name) {
    options.startupProfileName = null;
  }
  options.quickSwitchProfiles.remove(profile.name);

  if (profile is FixedProfile) {
    fixedProfileEditors.remove(profile);
  } else if (profile is SwitchProfile) {
    (profile as SwitchProfile).forEach((rule) => ruleEditors.remove(rule));
  }
}

void requestProfileDelete(Profile profile) {
  deliverChangesSync();
  var ref = profile is IncludableProfile ?
      options.profiles.referredBy(profile) : [];
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
    profile.bypassList.clear();
    profile.bypassList.addAll(bypassList.value.split('\n')
        .map((l) => l.trim()).where((l) => !l.isEmpty)
        .map((l) => new BypassCondition(l)));
    // Update the text in the textarea.
    bypassList.value = bypassListToText(profile.bypassList);
  });
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
  });
}

void moveRuleUp(SwitchProfile profile, Rule rule) {
  var index_old = profile.indexOf(rule);
  if (index_old > 0) {
    profile.removeAt(index_old);
    profile.insert(index_old - 1, rule);
  }
}

void moveRuleDown(SwitchProfile profile, Rule rule) {
  var index_old = profile.indexOf(rule);
  if (index_old < profile.length - 1) {
    profile.removeAt(index_old);
    profile.insert(index_old + 1, rule);
  }
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
}

List<Profile> validResultProfilesFor(InclusiveProfile profile) {
  return options.profiles.validResultProfilesFor(profile).toList();
}

void addRule(SwitchProfile profile) {
  var condition = new HostWildcardCondition('*.example.com');
  var profileName = profile.length > 0 ?
      profile.last.profileName : profile.defaultProfileName;

  profile.add(new Rule(condition, profileName));
}

void resetRules(SwitchProfile profile) {
  profile.forEach((rule) {
    rule.profileName = profile.defaultProfileName;
  });
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

Communicator safe = new Communicator(window.top);
Communicator js = new Communicator(window);
Browser browser = new MessageBrowser(safe);

@observable
StoredSwitchyOptions options = null;

List<String> profileTypes = ['FixedProfile',
                             'SwitchProfile',
                             'PacProfile',
                             'SwitchyRuleListProfile',
                             'AutoProxyRuleListProfile'];

Map<String, String> profileIcons = {
  'FixedProfile': 'icon-globe',
  'PacProfile': 'icon-tasks',
  'RulelistProfile': 'icon-list',
  'SwitchProfile': 'icon-retweet',
  'SwitchyRuleListProfile': 'icon-list',
  'AutoProxyRuleListProfile': 'icon-list'
};

Map<FixedProfile, FixedProfileEditor> fixedProfileEditors =
    new Map<FixedProfile, FixedProfileEditor>();

Map<Rule, RuleEditor> ruleEditors = new Map<Rule, RuleEditor>();

void exportPac() {
  var current = options.profiles[currentProfileName];
  if (current is InclusiveProfile) {
    js.send('file.saveAs', {
      'name': 'SwitchyOmega.pac',
      'content': current.toScript()
    });
  }
}

void exportOptions() {
  js.send('file.saveAs', {
    'name': 'SwitchyOmegaOptions.json',
    'content': JSON.stringify(options)
  });
}

void restoreOptions(String data) {
  StoredSwitchyOptions newOptions = null;

  data = data.trim();
  if (data[0] != '{') {
    Map<String, Object> json = null;
    try {
      data = new String.fromCharCodes(CryptoUtils.base64StringToBytes(data));
      json = JSON.parse(data);
    } catch (e) {

      query('#options-import-format-error').style.top = "0";
      return;
    }
    newOptions = upgradeOptions(json, browser.storage);
  } else {
    try {
      newOptions = new StoredSwitchyOptions.fromPlain(JSON.parse(data),
          browser.storage);
    } catch (e) {
      query('#options-import-format-error').style.top = "0";
      return;
    }
  }
  ChangeUnobserver unobserve;
  unobserve = observe(() => options, (_) {
    query('#options-import-success').style.top = "0";
    unobserve();
  });
  options = newOptions;
  options.storeAll();
}

void restoreLocal(FileUploadInputElement file) {
  if (file.files.length > 0 && file.files[0].name.length > 0) {
    var r = new FileReader();
    r.onLoad.listen((_) {
      restoreOptions(r.result as String);
    });
    r.readAsText(file.files[0]);
    file.value = "";
  }
}

void restoreOnline() {
  var button = query('#restore-online') as ButtonElement;
  button.disabled = true;
  var url = (query('#restore-url') as InputElement).value;
  browser.download(url).then((data) {
    restoreOptions(data);
  }).catchError((e) {
    query('#options-import-download-error').style.top = "0";
  }).whenComplete(() {
    button.disabled = false;
  });
}

void saveOptions(Event e) {
  e.preventDefault();
  safe.send('options.set', JSON.stringify(options), (_, [__]) {
    query('#options-save-success').style.top = "0";
  });
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
      case 'SwitchyRuleListProfile':
        p = new SwitchyRuleListProfile(modalNewProfile_name,
            new DirectProfile().name, new DirectProfile().name);
        break;
      case 'AutoProxyRuleListProfile':
        p = new AutoProxyRuleListProfile(modalNewProfile_name,
            new DirectProfile().name, new DirectProfile().name);
        break;
      default:
        throw new UnimplementedError();
    }
    if (p != null) {
      options.profiles.add(p);

      js.send('tab.set', '#profile-$modalNewProfile_name');
    }
    modalNewProfile_name = '';
  });
}

Map<String, Object> optionsBackup = null;

void handleActionsUI() {
  js.on('options.undo', (String type, [Function respond]) {
    var o = optionsBackup;
    optionsBackup = {
                     'options': options.toJson(),
                     'currentProfileName': currentProfileName,
                     'tab': null
    };
    ChangeUnobserver unobserve;
    unobserve = observe(() => options, (_) {
      js.send('tab.set', o['tab']);
      query('#options-undo-success').style.top = "0";
      unobserve();
    });
    options = new StoredSwitchyOptions.fromPlain(o['options'],
        browser.storage);
    options.storeAll();

    currentProfileName = o['currentProfileName'];
  });

  js.on('options.reset', (String type, [Function respond]) {
    safe.send('options.reset', null,
        (Map<String, Object> o, [Function respond]) {
      ChangeUnobserver unobserve;
      unobserve = observe(() => options, (_) {
        js.send('tab.set', o['tab']);
        query('#options-reset-success').style.top = "0";
        unobserve();
      });
      options = new StoredSwitchyOptions.fromPlain(o['options'],
          browser.storage);
      currentProfileName = o['currentProfileName'];
    });
  });
}

@observable List<Profile> quickSwitchDisabledProfiles = [];

void handleQuickSwitchUI() {
  js.on('quickswitch.update', (String type, [Function respond]) {
    options.quickSwitchProfiles.clear();
    options.quickSwitchProfiles.addAll(
        queryAll('#cycle-enabled li .profile-name').map((e) => e.text));
  });
  var refresh = (_) {
      var set = new Set<String>.from(options.profiles.map((p) => p.name));
      set.removeAll(options.quickSwitchProfiles);
      quickSwitchDisabledProfiles = set.map(options.getProfileByName)
          .toList(growable: false);
      js.send('quickswitch.refresh');
  };
  observe(() => options.quickSwitchProfiles, refresh);
  observe(() => options.profiles, refresh);
  refresh(null);
}

void downloadProfileNow(UpdatingProfile p, Event e) {
  var button = e.target as ButtonElement;
  button.disabled = true;
  browser.download(p.updateUrl).then((data) {
    p.applyUpdate(data);
    query('#options-profile-download-success').style.top = "0";
  }).catchError((e) {
    query('#options-profile-download-error').style.top = "0";
  }).whenComplete(() {
    button.disabled = false;
    safe.send('options.set', JSON.stringify(options));
  });
}

void main() {
  safe.send('options.get', null, (Map<String, Object> o, [Function respond]) {
    optionsBackup = o;
    ChangeUnobserver unobserve;
    unobserve = observe(() => options, (_) {
      js.send('tab.set', o['tab']);
      handleQuickSwitchUI();
      unobserve();
    });

    observe(() => options, (_) {
      if (options != null) {
        js.send('options.init');
        js.send('tab.set');
      }
    });

    options = new StoredSwitchyOptions.fromPlain(o['options'],
        browser.storage);
    currentProfileName = o['currentProfileName'];
  });

  handleActionsUI();
  handleNewProfileUI();
  handleFixedServerUI();
  handleSwitchProfileUI();
  autoBindToDataList(document.documentElement);
}