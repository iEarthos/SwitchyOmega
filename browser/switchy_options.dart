
abstract class SwitchyOptions extends Plainable {
  bool get confirmDeletion;
  void set confirmDeletion(bool value);
  
  bool get refreshOnProfileChange;
  void set refreshOnProfileChange(bool value);
  
  String get startupProfileName;
  void set startupProfileName(String value);
  
  bool get enableQuickSwitch;
  void set enableQuickSwitch(bool value);
  
  bool get revertProxyChanges;
  void set revertProxyChanges(bool value);
  
  List<String> get quickSwitchProfiles;
  
  Map<String, Profile> _profiles;
  Map<String, Profile> get profiles => _profiles;
  
  Profile getProfileByName(String name) {
    return profiles[name];
  }
  
  String get currentProfileName;
  set currentProfileName(String value);
  
  Object toPlain([Map<String, Object> p]) {
    p['confirmDeletion'] = confirmDeletion;
    p['refreshOnProfileChange'] = refreshOnProfileChange;
    p['startupProfileName'] = startupProfileName;
    p['enableQuickSwitch'] = enableQuickSwitch;
    p['revertProxyChanges'] = revertProxyChanges;
    
    p['quickSwitchProfiles'] = quickSwitchProfiles;
    p['profiles'] = _profiles.getValues().map((p) => p.toPlain());
    
    p['currentProfileName'] = currentProfileName;
  }
  
  void loadPlain(Map<String, Object> p) {
    currentProfileName = p['currentProfileName'];
    refreshOnProfileChange = p['refreshOnProfileChange'];
    startupProfileName = p['startupProfileName'];
    enableQuickSwitch = p['enableQuickSwitch'];
    revertProxyChanges = p['revertProxyChanges'];
    
    quickSwitchProfiles = p['quickSwitchProfiles'];
    _profiles = new Map<String, Profile>();
    for (var pp in p['profiles'] as List<Map<String, Object>>) {
      _profiles[pp['name']] = new Profile.fromPlain(pp);
    }
    
    currentProfileName = p['currentProfileName'];
  }
  
  SwitchyOptions();
  
  SwitchyOptions.fromPlain(Object p) {
    this.loadPlain(p);
  }
}