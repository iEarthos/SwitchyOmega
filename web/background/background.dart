library switchy_background;

import 'dart:html';
import 'dart:json' as JSON;
import 'package:web_ui/web_ui.dart';
import 'package:switchyomega/switchyomega.dart';
import 'package:switchyomega/browser/lib.dart';
import 'package:switchyomega/browser/message/lib.dart';
import 'package:switchyomega/communicator.dart';

part 'upgrade.dart';

Communicator c = new Communicator(window.top);

@observable SwitchyOptions options;
@observable Profile currentProfile;

void updateProxy(details) {
  // TODO(catus)
}

void applyProfile(String name) {
  var profile = options.getProfileByName(name);
  var possibleResults = [];
  if (profile is SwitchProfile) {
    possibleResults = options.profiles.validResultProfilesFor(profile).map(
        (p) => p.name).toList();
  }

  currentProfile = profile;

  c.send('proxy.set', {
    'profileName': profile.name,
    'color': profile.color,
    'inclusive': profile is InclusiveProfile,
    'switch': profile is SwitchProfile,
    'possibleResults': possibleResults,
    'config': null // TODO(catus)
  });
}

Profile resolveProfile(Profile p, String url) {
  var uri = Uri.parse(url);
  var date = new DateTime.now();
  while (p != null) {
    if (p is InclusiveProfile) {
      p = p.tracker.getProfileByName(
          (p as InclusiveProfile).choose(url, uri.host, uri.scheme, date));
    } else {
      return p;
    }
  }
}


void main() {
  c.send('options.get', null, (Map<String, Object> o, [Function respond]) {
    if (o['options'] == null) {
      if (o['oldOptions'] != null) {
        options = upgradeOptions(o['oldOptions']);
      } else {
        options = new SwitchyOptions.defaults();
      }
      c.send('options.set', JSON.stringify(options));
    } else {
      var version =
          (o['options'] as Map<String, String>)['schemaVersion'] as int;
      if (version < SwitchyOptions.schemaVersion) {
        options = upgradeOptions(o['options']);
        c.send('options.set', JSON.stringify(options));
      } else if (version > SwitchyOptions.schemaVersion) {
        // TODO(catus): Show warnings for newer schemaVersions.
      } else {
        options = new SwitchyOptions.fromPlain(o['options']);
      }
    }
    c.send('background.init');
    if (options.startupProfileName.isNotEmpty) {
      applyProfile(options.startupProfileName);
    } else if (o['currentProfileName'] != null) {
      applyProfile(o['currentProfileName']);
    } else {
      applyProfile(new DirectProfile().name);
    }
  });

  c.on({
    'proxy.onchange': (details, [_]) {
      updateProxy(details);
    },
    'options.update': (plain, [_]) {
      options = new SwitchyOptions.fromPlain(plain);
      applyProfile(currentProfile.name);
    },
    'profile.apply': (name, [_]) {
      applyProfile(name);
    },
    'condition.add': (Map<String, String> data, [_]) {
      var profile = options.getProfileByName(data['profile']);
      if (profile is SwitchProfile) {
        var plainCondition = {
                              'conditionType': data['type'],
                              'pattern': data['details']
        };
        profile.insert(0, new Rule(new Condition.fromPlain(plainCondition),
            data['result']));
        c.send('options.set', JSON.stringify(options));
        if (profile.name == currentProfile.name || (
            currentProfile is InclusiveProfile &&
            options.profiles.hasReference(currentProfile, profile))) {
          applyProfile(currentProfile.name);
        }
      }
    },
    'tempRules.add': (details, [_]) {
      // TODO(catus)
    },
    'profile.match': (url, [respond]) {
      if (currentProfile is InclusiveProfile) {
        var result = resolveProfile(currentProfile, url);
        respond({'name': result.name, 'color': result.color});
      }
    }
  });

  c.send('proxy.listen');
  c.send('proxy.get', null, (proxy, [_]) {
    updateProxy({
      'value': proxy,
      'levelOfControl': 'controllable_by_this_extension'
    });
  });
}
