part of switchy_profile;

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

/**
 * A [IncludableProfile] can be used as a result profile of [InclusiveProfile].
 * It can be converted to a JavaScript expression using [writeTo].
 */
abstract class IncludableProfile extends Profile {
  /**
   * Convert this profile to an JavaScript expression which can be used in PAC
   * scripts and write the result to a [CodeWriter].
  */
  void writeTo(CodeWriter w);

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
    for (var c in JSON.stringify('$magicPrefix$name').codeUnits) {
      if (c < 128) {
        sb.writeCharCode(c);
      } else {
        sb.write(r'\u');
        var hex = c.toRadixString(16);
        // Fill to 4 digits
        for (var i = hex.length; i < 4; i++) {
          sb.write('0');
        }
        sb.write(hex);
      }
    }
    return _scriptName = sb.toString();
  }

  IncludableProfile(String name) : super(name);
}
