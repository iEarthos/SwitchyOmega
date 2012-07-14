/**
 * This profile instructs the brower to use settings from the enviroment.
 */
class SystemProfile extends Profile {
  final String profileType = 'SystemProfile';
  final bool predefined = true;

  SystemProfile._private() : super('system') {
    this.color = ProfileColors.system;
  }

  static SystemProfile _instance = null;

  factory SystemProfile() {
    if (_instance != null)
      return _instance;
    else
      return _instance = new SystemProfile._private();
  }
  
  factory SystemProfile.fromPlain(Object p, [Object config])
    => new SystemProfile();
}
