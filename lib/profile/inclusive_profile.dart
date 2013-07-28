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
 * A [InclusiveProfile] can include one or more [IncludableProfiles].
 * It can be converted to a complete PAC script using [toScript].
 */
abstract class InclusiveProfile extends ScriptProfile {
  InclusiveProfile(String name) : super(name);

  ProfileTracker _tracker;
  /**
   * Set the tracker that tracks this profile and result profiles. This method
   * calls [initTracker] before the tracker is changed.
   * Having a non-null tracker is required for reference-related methods like
   * [toScript].
   * Setting [tracker] to [:null:] disables reference-related methods.
   */
  void set tracker(ProfileTracker value) {
    if (_tracker != value && value != null) {
      initTracker(value);
    }
    _tracker = value;
  }

  ProfileTracker get tracker => _tracker;

  /**
   * Get all direct result profiles of this profile. Requires [tracker].
   */
  Iterable<Profile> getProfileNames() => tracker.directReferences(this);

  /**
   * Returns true if [name] is a direct or indirect result of this profile.
   * Requires [tracker].
   */
  bool hasReferenceTo(String name) {
    if (tracker == null) {
      throw new StateError('A non-null tracker is required for this method.');
    }
    return tracker.hasReferenceToName(this, name);
  }

  /**
   * Returns all direct or indirect result of this profile. Requires [tracker].
   */
  Iterable<IncludableProfile> allReferences() {
    if (tracker == null) {
      throw new StateError('A non-null tracker is required for this method.');
    }
    return tracker.allReferences(this);
  }

  /**
   * Convert this profile to a complete PAC script with all included profiles.
   * Requires [tracker].
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
    for (var profile in allReferences()) {
      w.inline('${profile.getScriptName()} : ');
      profile.writeTo(w);
      w.code(',');
    }

    // Write this profile
    w.inline('${this.getScriptName()} : ');
    this.writeTo(w);
    w.newLine();
  }

  /**
   * Select one result profile according to the params and return its name.
   * Implementation of this method should not rely on the [tracker].
   */
  String choose(String url, String host, String scheme, DateTime datetime);

  /**
   * This method will be called when setting [tracker]. When implemented, this
   * method should add all direct references to the [tracker].
   */
  void initTracker(ProfileTracker tracker);

  /**
   * This method will be called when renaming profile [oldName] to [newName].
   * When implemented, this method should update the name of result profiles.
   */
  void renameProfile(String oldName, String newName);
}

/**
 * A [Rule] is a combination of a [condition] and a [profileName].
 */
class Rule extends Plainable {
  Condition condition;

  String _profileName;
  String get profileName => _profileName;
  set profileName(String value) {
    String old = _profileName;
    _profileName = value;
    if (onProfileNameChange != null && old != value) {
      onProfileNameChange(this, old);
    }
  }

  /**
   * When [profileName] is changed, this function will be called.
   */
  Function onProfileNameChange = null;

  Map<String, Object> toPlain([Map<String, Object> p]) {
    if (p == null) p = new Map<String, Object>();

    p['condition'] = this.condition.toPlain();
    p['profileName'] = this.profileName;

    return p;
  }

  void loadPlain(Map<String, Object> p) {
    this.condition = new Condition.fromPlain(p['condition']);
    this._profileName = p['profileName'];
  }

  Rule.fromPlain(Map<String, Object> p) {
    this.loadPlain(p);
  }

  Rule(this.condition, this._profileName);
}

/**
 * A [RuleProfileNameChangeCallback] is called when the profileName of the
 * [rule] is changed from [oldProfileName] to [:rule.profileName:].
 */
typedef void RuleProfileNameChangeCallback(Rule rule, String oldProfileName);
