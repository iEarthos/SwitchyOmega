/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

library shexp_utils;
import 'dart:core';
import 'package:json/json.dart';
import '../code_writer.dart';


Set<int> _regExpMetaChars = null;

/**
 * The codeUnits of all meta-chars which need escaping in regex.
 */
Set<int> get regExpMetaChars {
  if (_regExpMetaChars == null) {
    _regExpMetaChars = new Set.from(r'[\^$.|?*+(){}'.codeUnits);
  }
  return _regExpMetaChars;
}

/**
 * Compiles a wildcard [pattern] to a regular expression.
 * This function encodes [regExpMetaChars] in the [pattern].
 */
String shExp2RegExp(String pattern, {bool trimAsterisk : false}) {
  var codes = pattern.codeUnits;
  var start = 0;
  var end = pattern.length;

  if (trimAsterisk) {
    while (start < end && codes[start] == 42) { // '*'
      start++;
    }
    while (start < end && codes[end - 1] == 42) {
      end--;
    }
    if (end - start == 1 && codes[start] == 42) return '';
  }

  StringBuffer sb = new StringBuffer();
  if (start == 0) sb.write('^');
  for (var i = start; i < end; i++) {
    switch (codes[i]) {
      case 42: // '*'
        sb.write('.*');
        break;
      case 63: // '?'
        sb.write('.');
        break;
      default:
        if (regExpMetaChars.contains(codes[i])) sb.write(r'\');
        sb.writeCharCode(codes[i]);
        break;
    }
  }
  if (end == pattern.length) sb.write(r'$');

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
  throw new UnimplementedError();
}