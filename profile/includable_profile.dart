/**
 * A [IncludableProfile] can be used as a result profile of [InclusiveProfile].
 * It can be converted to a JavaScript expression using [writeTo].
 */
abstract class IncludableProfile extends Profile {
  /**
   * Convert this profile to an JavaScript expression which can be used in PAC
   * scripts and write the result to a [CodeWriter]. 
  */
  abstract void writeTo(CodeWriter w);
  
  String _scriptName;
  void set name(String value) {
    _name = value;
    _scriptName = null;
  }
  
  /**
   * This prefix is appended to the script name.
   */
  static final magicPrefix = 'switchy_';
  
  /**
   * Get a quoted and escaped JavaScript string from this profile's [name].
   * This method converts all non-ascii chars to its unicode escaped form.
   * It also prepend a [magicPrefix] to the name to prevent name clashes.
   */
  String getScriptName() {
    if (_scriptName != null) return _scriptName;
    StringBuffer sb = new StringBuffer();
    for (var c in JSON.stringify('$magicPrefix$name').charCodes()) {
      if (c < 128) {
        sb.addCharCode(c);
      } else {
        sb.add(@'\u');
        var hex = c.toRadixString(16);
        // Fill to 4 digits
        for (var i = hex.length; i < 4; i++) {
          sb.add('0');
        }
        sb.add(hex);
      }
    }
    return _scriptName = sb.toString();
  }
  
  IncludableProfile(String name) : super(name);
}
