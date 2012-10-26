
abstract class SwitchyOptionsObserver {
  void optionModified(String optionName, Object value);
  
  void profileAddedOrChanged(Profile profile);
  void profileRemoved(String name);
}

class SwitchyOptionsEmptyObserver implements SwitchyOptionsObserver {
  void optionModified(String optionName, Object value) {}
  
  void profileAddedOrChanged(Profile profile) {}
  void profileRemoved(String name) {}
  
  const SwitchyOptionsEmptyObserver();
}

class ObservableSwitchyOptions extends SwitchyOptions {
  
  SwitchyOptionsObserver _observer;
  SwitchyOptionsObserver get observer => _observer;
  void set observer(SwitchyOptionsObserver value) {
    _observer = value;
    (profiles as ObservableProfileMap).observer = _observer;
  }
  
  ObservableSwitchyOptions([
      SwitchyOptionsObserver observer = const SwitchyOptionsEmptyObserver()])
      : this._observer = observer {
        this._profiles = new ObservableProfileMap(observer);
      }
  
  bool _confirmDelection;
  
  bool get confirmDeletion => _confirmDelection;
  void set confirmDeletion(bool value) {
    if (_confirmDelection != value) {
      _confirmDelection = value;
      observer.optionModified('confirmDeletion', value);
    }
  }
  
  bool _refreshOnProfileChange;
  bool get refreshOnProfileChange => _refreshOnProfileChange;
  void set refreshOnProfileChange(bool value) {
    if (_refreshOnProfileChange != value) {
      _refreshOnProfileChange = value;
      observer.optionModified('refreshOnProfileChange', value);
    }
  }

  String _startupProfileName;
  String get startupProfileName => _startupProfileName;
  void set startupProfileName(String value) {
    if (_startupProfileName != value) {
      _startupProfileName = value;
      observer.optionModified('startupProfileName', value);
    }
  }
  
  bool _enableQuickSwitch;
  bool get enableQuickSwitch => _enableQuickSwitch;
  void set enableQuickSwitch(bool value) {
    if (_enableQuickSwitch != value) {
      _enableQuickSwitch = value;
      observer.optionModified('enableQuickSwitch', value);
    }
  }
  
  bool _revertProxyChanges;
  bool get revertProxyChanges => _revertProxyChanges;
  void set revertProxyChanges(bool value) {
    if (_revertProxyChanges != value) {
      _revertProxyChanges = value;
      observer.optionModified('revertProxyChanges', value);
    }
  }
  
  List<String> _quickSwitchProfiles;
  List<String> get quickSwitchProfiles => _quickSwitchProfiles;
  void set quickSwitchProfiles(List<String> value) {
    if (_quickSwitchProfiles != value) {
      _quickSwitchProfiles = value;
      observer.optionModified('quickSwitchProfiles', value);
    }
  }
  
  String _currentProfileName;
  String get currentProfileName => _currentProfileName;
  void set currentProfileName(String value) {
    if (_currentProfileName != value) {
      _currentProfileName = value;
      observer.optionModified('currentProfileName', value);
    }
  }
  
  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    this._profiles = new ObservableProfileMap(observer, this._profiles);
  }
  
  ObservableSwitchyOptions.fromPlain(Object p) {
    this.loadPlain(p);
  }
  
  ObservableSwitchyOptions.defaults() : super.defaults() {
    
  }
}

class ObservableProfileMap implements Map<String, Profile> {
  Map<String, Profile> _inner;
  SwitchyOptionsObserver observer;
  
  ObservableProfileMap(this.observer, [Map<String, Profile> inner]) {
    if (inner == null) {
      _inner = new Map<String, Profile>();
    } else {
      _inner = inner;
    }
  }

  void clear() {
    var keys = _inner.getKeys();
    _inner.clear();
    keys.forEach((k) {
      observer.profileRemoved(k);
    });
  }

  bool containsKey(String key) {
    return _inner.containsKey(key);
  }

  bool containsValue(Profile value) {
    return _inner.containsValue(value);
  }

  void forEach(void f(String key, Profile value)) {
    _inner.forEach(f);
  }

  Collection<String> getKeys() {
    return _inner.getKeys();
  }

  Collection<Profile> getValues() {
    return _inner.getValues();
  }

  bool isEmpty() {
    return _inner.isEmpty();
  }

  int get length() {
    return _inner.length;
  }

  void operator []=(String key, Profile value) {
    _inner[key] = value;
    observer.profileAddedOrChanged(value);
  }

  Profile operator [](String key) {
    return _inner[key];
  }

  Profile putIfAbsent(String key, Profile ifAbsent()) {
    var profile = _inner[key];
    if (profile == null) {
      profile = _inner[key] = ifAbsent();
      observer.profileAddedOrChanged(profile);
    }
    return profile;
  }

  Profile remove(String key) {
    var profile = _inner.remove(key);
    observer.profileRemoved(key);
    return profile;
  }
}
