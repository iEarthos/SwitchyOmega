/**
 * When this profile is applied, no proxy should be used.
 */
class DirectProfile extends IncludableProfile {
  final String profileType = 'DirectProfile';
  final bool predefined = true;
  
  void writeTo(CodeWriter w) {
    w.inline("['DIRECT']");
  }

  DirectProfile._private() : super('direct') {
    this.color = ProfileColors.direct;
  }

  static DirectProfile _instance = null;
  factory DirectProfile() {
    if (_instance != null)
      return _instance;
    else
      return _instance = new DirectProfile._private();
  }
  
  factory DirectProfile.fromPlain(Object p, [Object config]) 
    => new DirectProfile();
}