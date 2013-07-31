part of switchy_html;

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
 * Special chars in CSS that needs to be escaped when used in identifiers.
 */
Set<int> cssSpecialChars = new Set.from(
    (r'!"' r"#$%&'()*+,./:;<=>?@[\]^`{|}~" ' \t\n\v\f\r').codeUnits);

/**
 * Special chars in CSS that needs to be escaped when used at the beginning of
 * identifiers.
 */
Set<int> cssSpecialLeadingChars = new Set.from('0123456789_-'.codeUnits);

/**
 * Escape [identifier] so that it can be used safely in CSS selectors.
 */
String cssEscape(String identifier) {
  return _cssTransform(identifier, false);
}

/**
 * Transform [identifier] into an ID that does not require any escaping.
 * The transformed ID will use underscores and hex to represent special chars.
 * (Example: "abc@#$def" gets transformed into "abc_40_23_24_def".)
 * Note that underscores in identifiers are only valid in CSS >= 2.
 */
String cssSafeId(String identifier) {
  return _cssTransform(identifier, true);
}

String _cssTransform(String identifier, bool underscore) {
  StringBuffer result = new StringBuffer();
  bool leading = true;
  bool combine = false;
  for (var unit in identifier.codeUnits) {
    if ((leading && cssSpecialLeadingChars.contains(unit)) ||
        cssSpecialChars.contains(unit) ||
        (underscore && unit == '_'.codeUnitAt(0))) {
      if (underscore) {
        // Underscore transformation.
        if (!combine) result.write(r'_');
        result.write(unit.toRadixString(16));
        result.write('_');
        combine = true;
      } else {
        // Unicode escape.
        result.write(r'\');
        result.write(unit.toRadixString(16));
        result.write(' ');
      }
    } else {
      result.writeCharCode(unit);
      combine = false;
    }
    leading = false;
  }
  return result.toString();
}