part of switchy_profile;

/*!
 * Copyright (C) 2012, The SwitchyOmega Authors. Please see the AUTHORS file
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
 * A [InclusiveProfile] can include one or more [IncludableProfiles].
 * It can be converted to a complete PAC script using [toScript].
 */
abstract class InclusiveProfile extends ScriptProfile {
  /**
   * Returns true if this profile has a result profile which name is [name].
   * Otherwise, false.
   */
  bool containsProfileName(String name);

  /** A function that find profiles by their names. */
  ProfileResolver getProfileByName;

  /**
   * Get the names of all result profiles of this profile.
   */
  List<String> getProfileNames();

  Map<String, IncludableProfile> getAllReferences() {
    var s = new HashMap<String, IncludableProfile>();
    var queue = new List<String>.from(getProfileNames());
    while (queue.length > 0) {
      var p = getProfileByName(queue[0]);
      queue.removeRange(0, 1);
      s[p.name] = p;
      if (p is InclusiveProfile) {
        for (var pp in (p as InclusiveProfile).getProfileNames()) {
          var circ = s[pp];
          if (circ != null || pp == this.name) {
            throw new CircularReferenceException(p, ifNull(circ, this));
          }
          queue.add(pp);
        }
      }
    }
    return s;
  }

  /**
   * Convert this profile to a complete PAC script with all included profiles.
   */
  String toScript([bool pretty = true]) {
    var w = new WellFormattedCodeWriter();
    if (!pretty) {
      w.indentStr = '';
      w.lineBreak = '';
    }

    w.code("var SwitchyOmega = {")
       .code("FindProxyForURL : function (url, host) {")
         .code("'use strict';")
         .code("var scheme = url.substr(0, url.indexOf(':'));")
         .code("var p = ${this.getScriptName()};")
         .code("do {")
           .code("p = SwitchyOmega.profiles[p];")
           .code("if (typeof (p) === 'function') p = p(url, host, scheme);")
         .code("} while (typeof (p) === 'string');")
         .code("return p.join(';');")
       .code("},")
       .code("profiles : {");
    _writeAllProfilesTo(w);
      w.code("}")
     .code("};")
     .newLine()
     .code("var FindProxyForURL = SwitchyOmega.FindProxyForURL;");

    return w.toString();
  }

  void _writeAllProfilesTo(CodeWriter w) {
    // Write all included profiles
    for (var p in getAllReferences().getValues()) {
      w.inline('${p.getScriptName()} : ');
      p.writeTo(w);
      w.code(',');
    }

    // Write this profile
    w.inline('${this.getScriptName()} : ');
    this.writeTo(w);
    w.newLine();
  }

  /**
   * Select one result profile according to the params and return its name.
   */
  String choose(String url, String host, String scheme, Date datetime);

  InclusiveProfile(String name, this.getProfileByName) : super(name);
}

typedef Profile ProfileResolver(String name);

/**
 * Thrown when a circular reference of two [InclusiveProfile]s is detected.
 */
class CircularReferenceException implements Exception {
  final InclusiveProfile parent;
  final InclusiveProfile result;

  CircularReferenceException(this.parent, this.result);

  String toString() => 'Profile "${result.name}" cannot be configured as a '
                       'result profile of Profile "${parent.name}", because it'
                       'references Profile "${parent.name}", directly or indirectly.';
}

class Rule extends Plainable {
  Condition condition;
  String profileName;

  Map<String, Object> toPlain([Map<String, Object> p]) {
    if (p == null) p = new Map<String, Object>();

    p['condition'] = this.condition.toPlain();
    p['profileName'] = this.profileName;

    return p;
  }

  void loadPlain(Map<String, Object> p) {
    this.condition = new Condition.fromPlain(p['condition']);
    this.profileName = p['profileName'];
  }

  Rule.fromPlain(Map<String, Object> p) {
    this.loadPlain(p);
  }

  Rule(this.condition, this.profileName);
}
