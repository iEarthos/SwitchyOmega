library switchy_background;

import 'dart:html';
import 'dart:json' as JSON;
import 'package:web_ui/web_ui.dart';
import 'package:switchyomega/switchyomega.dart';
import 'package:switchyomega/browser/lib.dart';
import 'package:switchyomega/browser/message/lib.dart';
import 'package:switchyomega/communicator.dart';

part 'upgrade.dart';

Communicator safe = new Communicator(window.top);
Browser browser = new MessageBrowser(safe);

@observable SwitchyOptions options;
@observable Profile currentProfile;

void updateProxy(details) {
  // TODO(catus)
}

void applyProfile(String name) {
  currentProfile = options.getProfileByName(name);
  browser.applyProfile(currentProfile);
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

const String directDetails = 'DIRECT';

String getProfileDetails(Profile p, String url) {
  var uri = Uri.parse(url);
  switch (p.profileType) {
    case 'FixedProfile':
      var proxy = (p as FixedProfile).getProxyFor(url, uri.host, uri.scheme);
      return proxy == null ? directDetails : proxy.toPacResult();
    case 'DirectProfile':
      return directDetails;
    case 'PacProfile':
    case 'AutoDetectProfile':
      var url = (p as PacProfile).pacUrl;
      if (url != null && url.isNotEmpty) {
        return 'PAC Script: ' + url;
      }
      return 'PAC Script';
    default:
      return '(${p.profileType})';
  }
}

void main() {
  safe.send('options.get', null, (Map<String, Object> o, [Function respond]) {
    if (o['options'] == null) {
      if (o['oldOptions'] != null) {
        options = upgradeOptions(o['oldOptions']);
      } else {
        options = new SwitchyOptions.defaults();
      }
      safe.send('options.set', JSON.stringify(options));
    } else {
      var version =
          (o['options'] as Map<String, String>)['schemaVersion'] as int;
      if (version < SwitchyOptions.schemaVersion) {
        options = upgradeOptions(o['options']);
        safe.send('options.set', JSON.stringify(options));
      } else if (version > SwitchyOptions.schemaVersion) {
        // TODO(catus): Show warnings for newer schemaVersions.
      } else {
        options = new SwitchyOptions.fromPlain(o['options']);
      }
    }
    safe.send('background.init');
    if (options.startupProfileName.isNotEmpty) {
      applyProfile(options.startupProfileName);
    } else if (o['currentProfileName'] != null) {
      applyProfile(o['currentProfileName']);
    } else {
      applyProfile(new DirectProfile().name);
    }
  });

  safe.on({
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
        safe.send('options.set', JSON.stringify(options));
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
        var color = result.color;
        var details = getProfileDetails(result, url);
        if (details == directDetails) color = ProfileColors.direct;
        respond({
          'name': result.name,
          'color': color,
          'details': details
        });
      }
    }
  });

  safe.send('proxy.listen');
  safe.send('proxy.get', null, (proxy, [_]) {
    updateProxy({
      'value': proxy,
      'levelOfControl': 'controllable_by_this_extension'
    });
  });
}
