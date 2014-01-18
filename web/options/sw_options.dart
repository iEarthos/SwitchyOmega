import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:js';
import 'dart:async';
import 'package:json/json.dart' as JSON;
import 'package:crypto/crypto.dart';
import 'package:switchyomega/switchyomega.dart';
import 'package:switchyomega/communicator.dart';
import 'options_utils.dart';

@CustomTag('sw-options')
class SwOptionsElement extends PolymerElement with SwitchyOptionsUtils {
  bool get applyAuthorStyles => true;

  @published StoredSwitchyOptions options = null;

  SwOptionsElement.created() : super.created();

  Communicator safe = new Communicator(window.top);

  Communicator js = new Communicator(window);

  Browser _browser;
  Browser get browser {
    if (_browser == null) _browser = new MessageBrowser(safe);
    return _browser;
  }

  @observable String currentProfileName = '';

  void ready() {
    Communicator js = new Communicator(window);
    js.send('options.get', null, (o, [_]) {
      options = new StoredSwitchyOptions.fromPlain(o['options'],
          browser.storage);
      js.send('options.init');
      handleQuickSwitchUI();
      currentProfileName = o['currentProfileName'];
      js.send('tab.set', o['tab']);
    });
  }

  void enteredView() {
    super.enteredView();
    context.callMethod('onShadowHostReady', [this]);
  }

  @reflectable List<String> validResultProfilesFor(Profile profile) {
    if (profile is InclusiveProfile) {
      return options.profiles.validResultProfilesFor(profile)
          .map((p) => p.name).toList();
    } else {
      return const [];
    }
  }

  @observable List<String> quickSwitchEnabledProfiles = [];
  @observable List<Profile> quickSwitchDisabledProfiles = [];

  void handleQuickSwitchUI() {
    js.on('quickswitch.update', (String type, [Function respond]) {
      options.quickSwitchProfiles.clear();
      options.quickSwitchProfiles.addAll(
          querySelectorAll('#cycle-enabled li .profile-name')
          .map((e) => e.text));
    });
    var refresh = (_) {
      var set = new Set<String>.from(options.profiles.keys);
      set.removeAll(options.quickSwitchProfiles);
      quickSwitchDisabledProfiles = set.map(options.getProfileByName)
          .where((p) => p != null).toList(growable: false);
      js.send('quickswitch.refresh');
    };
    quickSwitchEnabledProfiles = options.quickSwitchProfiles.toList();
    options.quickSwitchProfiles.changes.listen(refresh);
    options.profiles.changes.listen(refresh);
    refresh(null);
  }

  @reflectable void exportPac(_, __, ___) {
    var current = options.profiles[currentProfileName];
    if (current is ScriptProfile) {
      js.send('file.saveAs', {
        'name': 'SwitchyOmega.pac',
        'content': current.toScript()
      });
    } else {
      alertSuccess = false;
      alertShown = true;
      alertI18n = '';
    }
  }

  @reflectable void exportOptions(_, __, ___) {
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

        querySelector('#options-import-format-error').style.top = "0";
        return;
      }
      newOptions = upgradeOptions(json, browser.storage);
    } else {
      try {
        newOptions = new StoredSwitchyOptions.fromPlain(JSON.parse(data),
            browser.storage);
      } catch (e) {
        querySelector('#options-import-format-error').style.top = "0";
        return;
      }
    }
    StreamSubscription sub;
    sub = options.changes.listen((_) {
      querySelector('#options-import-success').style.top = "0";
      sub.cancel();
    });
    options = newOptions;
    options.storeAll();
  }

  void restoreLocal(_, __, FileUploadInputElement file) {
    if (file.files.length > 0 && file.files[0].name.length > 0) {
      var r = new FileReader();
      r.onLoad.listen((_) {
        restoreOptions(r.result as String);
      });
      r.readAsText(file.files[0]);
      file.value = "";
    }
  }

  @reflectable void restoreOnline(_, __, ___) {
    var button = querySelector('#restore-online') as ButtonElement;
    button.disabled = true;
    var url = (querySelector('#restore-url') as InputElement).value;
    browser.download(url).then((data) {
      restoreOptions(data);
    }).catchError((e) {
      querySelector('#options-import-download-error').style.top = "0";
    }).whenComplete(() {
      button.disabled = false;
    });
  }

  @reflectable void saveOptions(Event e, _, __) {
    e.preventDefault();
    safe.send('options.set', JSON.stringify(options), (_, [__]) {
      querySelector('#options-save-success').style.top = "0";
    });
  }

  @observable String modalRenameProfile_newName;

  @reflectable bool modalRenameProfile_isValid() => true;

  @observable Profile modalDeleteProfile_profile;
  @observable List<Profile> modalCannotDeleteProfile_referring;

  @observable Rule modalDeleteRule_rule;

  @reflectable
  bool get modalDeleteRule_rule_condition_is_PatternBasedCondition =>
      modalDeleteRule_rule.condition is PatternBasedCondition;

  @reflectable
  bool get modalDeleteRule_rule_condition_is_HostLevelsCondition =>
      modalDeleteRule_rule.condition is HostLevelsCondition;

  @observable Profile modalResetRules_resultProfile;

  @observable String modalNewProfile_name;

  @reflectable bool modalNewProfile_isValid() => true;

  @observable bool alertSuccess = true;

  @observable String alertI18n = 'options_profileNameConflict';

  @observable bool alertShown = false;
}
