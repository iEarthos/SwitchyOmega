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
class SwitchyOptions extends Plainable with Observable {
  /**
   * The schemeVersion is increased every time the structure of the result of
   * [toPlain] changes.
   */
  static const schemaVersion = 1;

  @observable bool confirmDeletion;

  @observable bool refreshOnProfileChange;

  @observable String startupProfileName;

  @observable bool enableQuickSwitch;

  @observable bool revertProxyChanges;

  /**
   * The interval (in minutes) between PAC or rule list updates.
   * A negative value disables automatic updating.
   */
  @observable int downloadInterval;

  final ObservableList<String> quickSwitchProfiles = toObservable([]);

  final ProfileCollection profiles = new ProfileCollection();

  Profile getProfileByName(String name) {
    return profiles[name];
  }

  Object toPlain([Map<String, Object> p]) {
    p = profiles.toPlain(p);
    p['-confirmDeletion'] = confirmDeletion;
    p['-refreshOnProfileChange'] = refreshOnProfileChange;
    p['-startupProfileName'] = startupProfileName;
    p['-enableQuickSwitch'] = enableQuickSwitch;
    p['-revertProxyChanges'] = revertProxyChanges;
    p['-downloadInterval'] = downloadInterval;

    p['-quickSwitchProfiles'] = quickSwitchProfiles;

    p['schemaVersion'] = schemaVersion;
    return p;
  }

  void loadPlain(Map<String, Object> p) {
    var version = p['schemaVersion'] as int;
    if (version != schemaVersion) {
      throw new UnsupportedError('Unsupported schemeVersion: $version.');
    }
    confirmDeletion = p['-confirmDeletion'];
    refreshOnProfileChange = p['-refreshOnProfileChange'];
    startupProfileName = p['-startupProfileName'];
    enableQuickSwitch = p['-enableQuickSwitch'];
    revertProxyChanges = p['-revertProxyChanges'];
    downloadInterval = p['-downloadInterval'];

    quickSwitchProfiles.clear();
    quickSwitchProfiles.addAll(p['-quickSwitchProfiles']);

    profiles.loadPlain(p);
  }

  SwitchyOptions() {
    confirmDeletion = true;
    refreshOnProfileChange = true;
    startupProfileName = '';
    enableQuickSwitch = false;
    revertProxyChanges = false;
    downloadInterval = 24 * 60;
  }

  SwitchyOptions.fromPlain(Object p) {
    this.loadPlain(p);
  }

}

class StoredSwitchyOptions extends SwitchyOptions {
  static const schemaVersion = SwitchyOptions.schemaVersion;

  BrowserStorage storage;
  final Map<Profile, StreamSubscription<List<ChangeRecord>>> _subs = {};
  final List<StreamSubscription<List<ChangeRecord>>> _syncObservers = [];
  final Completer _readyCompleter = new Completer();
  Future get ready => _readyCompleter.future;
  Map<String, String> _revisionLock = {};

  StoredSwitchyOptions(this.storage) : super() {
    _readyCompleter.complete();
  }

  StoredSwitchyOptions.fromPlain(Map<String, Object> data, this.storage) {
    try {
      this.loadPlain(data);
    } catch (ex) {
      _readyCompleter.completeError(ex);
      throw ex;
    }
    this.startSyncing();
    _readyCompleter.complete();
  }

  StoredSwitchyOptions.loadFrom(this.storage) {
    this.storage.get(null).then((data) {
      try {
        this.loadPlain(data);
      } catch (ex) {
        _readyCompleter.completeError(ex);
      }
      this.startSyncing();
      _readyCompleter.complete();
    });
  }

  void startSyncing() {
    Observable.dirtyCheck();
    _syncObservers.add(this.changes.listen((List<ChangeRecord> changes) {
      var items = new Map<String, Object>();
      changes.forEach((record) {
        items['-' + record.key] = record.newValue;
      });
      storage.set(items);
    }));

    _syncObservers.add(this.quickSwitchProfiles.changes.listen((_) {
      storage.set({'-quickSwitchProfiles': this.quickSwitchProfiles});
    }));

    var observeProfile = (_, Profile profile) {
      _subs[profile] = profile.changes.listen((records) {
        if (this.profiles.contains(profile)) {
          if (records.any(
              (c) => c is! PropertyChangeRecord || c.name != #revision)) {
            if (profile.revision == null ||
                _revisionLock[profile.name] != profile.revision) {
              profile.revision =
                  new DateTime.now().millisecondsSinceEpoch.toRadixString(16);
              var key = '+' + profile.name;
              var value = profile;
              value = value.toPlain();
              var items = {};
              items[key] = value;
              storage.set(items);
            }
          }
        }
      });
    };

    profiles.forEach(observeProfile);

    _syncObservers.add(this.profiles.changes.listen((changes) {
      var items = new Map<String, Object>();
      changes.forEach((rec) {
        if (rec is MapChangeRecord && (rec.isInsert || !rec.isRemove)) {
            var value = rec.newValue as Profile;
            var key = value.name;
            value = value.toPlain();
            items['+' + key] = value;
        }
        if (rec is MapChangeRecord && rec.isRemove) {
            items['+' + rec.oldValue.name] = null;
        }
        if (rec is MapChangeRecord && (rec.isRemove || !rec.isInsert)) {
          _subs[rec.oldValue].cancel();
        }
        if (rec is MapChangeRecord && (rec.isInsert || !rec.isRemove)) {
          observeProfile(null, rec.newValue);
        }
      });
      var removed = new List<String>();
      items.forEach((key, value) {
        if (value == null) removed.add(key);
      });
      removed.forEach((key) {
        items.remove(key);
      });
      storage.set(items);
      storage.remove(removed);
    }));
  }

  void stopSyncing() {
    _syncObservers.forEach((sub) => sub.cancel());
    _syncObservers.clear();
    _subs.forEach((_, sub) => sub.cancel());
    _subs.clear();
    _onUpdate = null;
  }

  Future storeAll() {
    for (var p in profiles) {
      p.revision = new DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    }
    var items = this.toPlain();
    return storage.remove(null).then((_) => storage.set(items));
  }

  Stream<BrowserStorageChangeRecord> _onUpdate;

  Stream<BrowserStorageChangeRecord> get onUpdate {
    if (_onUpdate == null) {
      Stream<BrowserStorageChangeRecord> onUpdate = null;
      _onUpdate = storage.onChange.where((record) {
        if (_onUpdate != onUpdate) return false;
        switch (record.key[0]) {
          case '-':
            if (record.newValue != record.oldValue &&
                record.newValue != null && record.oldValue != null) {
              switch (record.key) {
                case '-confirmDeletion':
                  confirmDeletion = record.newValue;
                  break;
                case '-refreshOnProfileChange':
                  refreshOnProfileChange = record.newValue;
                  break;
                case '-startupProfileName':
                  startupProfileName = record.newValue;
                  break;
                case '-enableQuickSwitch':
                  enableQuickSwitch = record.newValue;
                  break;
                case '-revertProxyChanges':
                  revertProxyChanges = record.newValue;
                  break;
                case '-downloadInterval':
                  downloadInterval = record.newValue;
                  break;
                case '-quickSwitchProfiles':
                  quickSwitchProfiles.clear();
                  quickSwitchProfiles.addAll(record.newValue);
                  break;
              }
              return true;
            }
            break;
          case '+':
            if (record.newValue != record.oldValue) {
              try {
                if (record.newValue == null) {
                  print('Remove: ${record.key}');
                  profiles.forceRemove(record.key.substring(1));
                } else if (record.oldValue == null) {
                  print('Add: ${record.key}: ${JSON.stringify(record.newValue)}');
                  profiles.add(new Profile.fromPlain(record.newValue));
                } else {
                  print('Update:From: ${record.key}: ${JSON.stringify(record.oldValue)}');
                  print('Update:To:   ${record.key}: ${JSON.stringify(record.newValue)}');
                  var rev = record.newValue['revision'];
                  var profile = profiles.getProfileByName(
                      record.key.substring(1));
                  if (profile != null &&
                      (profile.revision == null ||
                      profile.revision.length <= rev.length &&
                      profile.revision.compareTo(rev) < 0)) {
                    var name = record.key.substring(1);
                    Observable.dirtyCheck();
                    _revisionLock[name] = rev;
                    profiles.getProfileByName(name).loadPlain(record.newValue);
                    Observable.dirtyCheck();
                    _revisionLock.remove(name);
                  }
                }
              } catch (ex) {
                print(ex);
                // Force reload of all profiles.
                stopSyncing();
                this.storage.get(null).then((data) {
                    profiles.loadPlain(data);
                    startSyncing();
                    _onUpdate = onUpdate;
                });
                return false;
              }
              return true;
            }
            break;
        }
        return false;
      });
      onUpdate = _onUpdate;
    }
    return _onUpdate;
  }
}
