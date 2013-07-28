part of switchy_browser;

@observable
class SwitchyOptions extends Plainable {
  bool confirmDeletion;

  bool refreshOnProfileChange;

  String startupProfileName;

  bool enableQuickSwitch;

  bool revertProxyChanges;

  final List<String> quickSwitchProfiles = toObservable([]);

  final ProfileCollection profiles = new ProfileCollection();

  final List<Profile> profilesAsList = toObservable([]);

  void notifyProfilesChange() {
    profilesAsList.clear();
    profilesAsList.addAll(profiles);
  }

  Profile getProfileByName(String name) {
    return profiles[name];
  }

  String currentProfileName;

  Object toPlain([Map<String, Object> p]) {
    if (p == null) p = new Map<String, Object>();
    p['confirmDeletion'] = confirmDeletion;
    p['refreshOnProfileChange'] = refreshOnProfileChange;
    p['startupProfileName'] = startupProfileName;
    p['enableQuickSwitch'] = enableQuickSwitch;
    p['revertProxyChanges'] = revertProxyChanges;

    p['quickSwitchProfiles'] = quickSwitchProfiles;

    var plainProfiles = new Map<String, Object>();
    profiles.forEach((p) {
      plainProfiles[p.name] = p.toPlain();
    });
    p['profiles'] = profiles.toPlain();

    p['currentProfileName'] = currentProfileName;

    return p;
  }

  void loadPlain(Map<String, Object> p) {
    currentProfileName = p['currentProfileName'];
    confirmDeletion = p['confirmDeletion'];
    refreshOnProfileChange = p['refreshOnProfileChange'];
    startupProfileName = p['startupProfileName'];
    enableQuickSwitch = p['enableQuickSwitch'];
    revertProxyChanges = p['revertProxyChanges'];

    quickSwitchProfiles.clear();
    quickSwitchProfiles.addAll(p['quickSwitchProfiles']);

    profiles.loadPlain(p['profiles']);

    currentProfileName = p['currentProfileName'];
    profilesAsList.clear();
    profilesAsList.addAll(profiles);
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

    quickSwitchProfiles.clear();
  }

}