part of switchy_browser;


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
  }

  ObservableSwitchyOptions([
      SwitchyOptionsObserver observer = const SwitchyOptionsEmptyObserver()])
      : this._observer = observer { }

  bool _confirmDelection;

  bool get confirmDeletion => _confirmDelection;
  void set confirmDeletion(bool value) {
    if (_confirmDelection != value) {
      _confirmDelection = value;
      if (observer != null) observer.optionModified('confirmDeletion', value);
    }
  }

  bool _refreshOnProfileChange;
  bool get refreshOnProfileChange => _refreshOnProfileChange;
  void set refreshOnProfileChange(bool value) {
    if (_refreshOnProfileChange != value) {
      _refreshOnProfileChange = value;
      if (observer != null)
        observer.optionModified('refreshOnProfileChange', value);
    }
  }

  String _startupProfileName;
  String get startupProfileName => _startupProfileName;
  void set startupProfileName(String value) {
    if (_startupProfileName != value) {
      _startupProfileName = value;
      if (observer != null)
        observer.optionModified('startupProfileName', value);
    }
  }

  bool _enableQuickSwitch;
  bool get enableQuickSwitch => _enableQuickSwitch;
  void set enableQuickSwitch(bool value) {
    if (_enableQuickSwitch != value) {
      _enableQuickSwitch = value;
      if (observer != null)
        observer.optionModified('enableQuickSwitch', value);
    }
  }

  bool _revertProxyChanges;
  bool get revertProxyChanges => _revertProxyChanges;
  void set revertProxyChanges(bool value) {
    if (_revertProxyChanges != value) {
      _revertProxyChanges = value;
      if (observer != null)
        observer.optionModified('revertProxyChanges', value);
    }
  }

  List<String> _quickSwitchProfiles;
  List<String> get quickSwitchProfiles => _quickSwitchProfiles;
  void set quickSwitchProfiles(List<String> value) {
    if (_quickSwitchProfiles != value) {
      _quickSwitchProfiles = value;
      if (observer != null)
        observer.optionModified('quickSwitchProfiles', value);
    }
  }

  String _currentProfileName;
  String get currentProfileName => _currentProfileName;
  void set currentProfileName(String value) {
    if (_currentProfileName != value) {
      _currentProfileName = value;
      if (observer != null)
        observer.optionModified('currentProfileName', value);
    }
  }

  void loadPlain(Map<String, Object> p) {
    _quickSwitchProfiles = new List<String>();
    super.loadPlain(p);
  }

  ObservableSwitchyOptions.fromPlain(Object p) {
    this.loadPlain(p);
  }

  ObservableSwitchyOptions.defaults() : super.defaults() {
    _quickSwitchProfiles = new List<String>();
  }
}