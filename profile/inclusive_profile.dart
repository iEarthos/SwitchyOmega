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
   * Returns true if [p] is a result profile of this profile. Otherwise, false.
   */
  abstract bool containsProfile(IncludableProfile p);
  
  /**
   * Get all result profiles of this profile.
   */
  abstract List<IncludableProfile> getProfiles();
  
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
    for (var p in this.getProfiles()) {
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
   * Select one result profile according to the params.
   */
  abstract Profile choose(String url, String host, String scheme, Date datetime);
  
  InclusiveProfile(String name) : super(name);
}

typedef Profile ProfileResolver(String name); 

class Rule extends Plainable {
  Condition condition;
  IncludableProfile profile;
  
  /**
   * [:config['profileNameOnly']:] can be set to true for writing
   * [profile.name] as profileName instead of the whole profile.
   */
  Map<String, Object> toPlain([Map<String, Object> p, Map<String, Object> config]) {
    if (p == null) p = new Map<String, Object>();
    
    p['condition'] = this.condition.toPlain(null, config);
    
    if (config != null && config['profileNameOnly'] != null) {
      p['profileName'] = this.profile.name;
    } else {
      p['profile'] = this.profile.toPlain(null, config);
    }
    
    return p;
  }
  
  /**
   * If [:p['profileName']:] is used instead of [:p['profile']:],
   * [:config['profileResolver']:] must be set to a [ProfileResolver].
   */
  Rule.fromPlain(Map<String, Object> p, [Map<String, Object> config]) {
    this.condition = new Condition.fromPlain(p['condition']);
    
    var prof = p['profile'];
    if (prof != null) {
      this.profile = new Profile.fromPlain(prof, config);
    } else {
      ProfileResolver resolver = config['profileResolver']; // CAST
      this.profile = resolver(p['profileName']);
    }
  }
  
  Rule(this.condition, this.profile);
}