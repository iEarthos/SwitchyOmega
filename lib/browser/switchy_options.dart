part of switchy_browser;

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
@observable
class SwitchyOptions extends Plainable {
  /**
   * The schemeVersion is increased every time the structure of the result of
   * [toPlain] changes.
   */
  static const schemaVersion = 0;

  bool confirmDeletion;

  bool refreshOnProfileChange;

  String startupProfileName;

  bool enableQuickSwitch;

  bool revertProxyChanges;

  /**
   * The interval (in minutes) between PAC or rule list updates.
   * A negative value disables automatic updating.
   */
  int downloadInterval;

  final List<String> quickSwitchProfiles = toObservable([]);

  final ProfileCollection profiles = new ProfileCollection();

  Profile getProfileByName(String name) {
    return profiles[name];
  }

  Object toPlain([Map<String, Object> p]) {
    if (p == null) p = new Map<String, Object>();
    p['confirmDeletion'] = confirmDeletion;
    p['refreshOnProfileChange'] = refreshOnProfileChange;
    p['startupProfileName'] = startupProfileName;
    p['enableQuickSwitch'] = enableQuickSwitch;
    p['revertProxyChanges'] = revertProxyChanges;
    p['downloadInterval'] = downloadInterval;

    p['quickSwitchProfiles'] = quickSwitchProfiles;

    var plainProfiles = new Map<String, Object>();
    profiles.forEach((p) {
      plainProfiles[p.name] = p.toPlain();
    });
    p['profiles'] = profiles.toPlain();

    p['schemaVersion'] = schemaVersion;
    return p;
  }

  void loadPlain(Map<String, Object> p) {
    var version = p['schemaVersion'] as int;
    if (version != schemaVersion) {
      throw new UnsupportedError('Unsupported schemeVersion: $version.');
    }
    confirmDeletion = p['confirmDeletion'];
    refreshOnProfileChange = p['refreshOnProfileChange'];
    startupProfileName = p['startupProfileName'];
    enableQuickSwitch = p['enableQuickSwitch'];
    revertProxyChanges = p['revertProxyChanges'];
    downloadInterval = p['downloadInterval'];

    quickSwitchProfiles.clear();
    quickSwitchProfiles.addAll(p['quickSwitchProfiles']);

    profiles.loadPlain(p['profiles']);
  }

  SwitchyOptions() {}

  SwitchyOptions.fromPlain(Object p) {
    this.loadPlain(p);
  }

  SwitchyOptions.defaults() {
    confirmDeletion = true;
    refreshOnProfileChange = true;
    startupProfileName = '';
    enableQuickSwitch = false;
    revertProxyChanges = false;
    downloadInterval = 24 * 60;

    quickSwitchProfiles.clear();
  }

}