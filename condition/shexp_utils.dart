#library('shexp_utils');
#import('dart:core');
#import('dart:json');

#import('../utils/code_writer.dart');

HashSet<int> _regExpMetaChars = null;

/**
 * The charCodes of all meta-chars which need escaping in regex.
 */
HashSet<int> get regExpMetaChars() {
  if (_regExpMetaChars == null)
    _regExpMetaChars = new HashSet.from(@'[\^$.|?*+(){}'.charCodes());
  return _regExpMetaChars;
}

/**
 * Compiles a wildcard [pattern] to a regular expression.
 * This function encodes [regExpMetaChars] in the [pattern].
 */
String shExp2RegExp(String pattern, [bool trimAsterisk = false]) {
  var codes = pattern.charCodes();
  var start = 0;
  var end = pattern.length;
  
  if (trimAsterisk) {
    while (start < end && codes[start] == 42) // '*'
      start++;
    while (start < end && codes[end - 1] == 42)
      end--;
    if (end - start == 1 && codes[start] == 42) return '';
  }
  
  StringBuffer sb = new StringBuffer();
  if (start == 0) sb.add('^');
  for (var i = start; i < end; i++) {
    switch (codes[i]) {
      case 42: // '*'
        sb.add('.*');
        break;
      case 63: // '?'
        sb.add('.');
        break;
      default:
        if (regExpMetaChars.contains(codes[i])) sb.add(@'\');
        sb.addCharCode(codes[i]);
        break;
    }
  }
  if (end == pattern.length) sb.add(@'$');
  
  return sb.toString();
}

/**
 * Compiles a wildcard expression to JavaScript and write the result to [w].
 * if [target] is not [:null:], the result is a bool expression on [target].
 * Otherwise, the result is a function which accepts a string as a param and
 * returns true if the param string matches the pattern.
 */
void shExpCompile(String pattern, CodeWriter w, [String target = null]) {
  // TODO(catus)
  throw new NotImplementedException();
}