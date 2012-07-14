/**
 * A [ScriptProfile] applies a PAC script when in effect.
 */
abstract class ScriptProfile extends IncludableProfile {
  /**
   * Get the PAC script of this profile.
   */
  abstract String toScript();
  
  ScriptProfile(String name) : super(name);
}
