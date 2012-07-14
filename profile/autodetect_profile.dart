/**
 * When this profile is applied, the proxy is detected by running the WPAD
 * script which can be downloaded at <http://wpad/wpad.dat>.
 */
class AutoDetectProfile extends PacProfile {
  final String profileType = 'AutoDetectProfile';
  final bool predefined = true;

  final String pacUrl = 'http://wpad/wpad.dat';

  AutoDetectProfile._private() : super('auto_detect') {
    this.color = ProfileColors.auto_detect;
  }

  static AutoDetectProfile _instance = null;
  factory AutoDetectProfile() {
    if (_instance != null)
      return _instance;
    else
      return _instance = new AutoDetectProfile._private();
  }
  
  factory AutoDetectProfile.fromPlain(Object p, [Object config])
    => new AutoDetectProfile();
}
