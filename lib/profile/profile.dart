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
 * A profile is a proxy mode that can be applied manually or automatically.
 */
@observable
abstract class Profile extends Plainable {
  /** The name of the profile. This is used as a key. */
  String name;

  /** When overridden in derived classes, return the profile type. */
  String get profileType;

  /**
    Colors can help to tell profiles from each other.
    If this profile includes other profiles, [color] should be null.
  */
  String color;

  /**
    Whether this profile is a predefined profile.
    This can be overridden to prevent this profile from being deleted or changed.
  */
  bool get predefined => false;

  /** Create a [name]d profile. */
  Profile(String name, [this.color = null]) {
    if (this.color == null) this.color = ProfileColors.profile_default;
    this.name = name;
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    if (p == null) p = new Map<String, Object>();
    p['name'] = this.name;
    p['profileType'] = this.profileType;
    p['color'] = this.color;

    return p;
  }

  void loadPlain(Map<String, Object> p) {
    this.name = p['name'];
    this.color = p['color'];
  }

  factory Profile.fromPlain(Map<String, Object> p) {
    Profile profile = null;
    switch (p['profileType']) {
      case 'AutoDetectProfile':
        profile = new AutoDetectProfile.fromPlain(p);
        break;
      case 'DirectProfile':
        profile = new DirectProfile.fromPlain(p);
        break;
      case 'FixedProfile':
        profile = new FixedProfile.fromPlain(p);
        break;
      case 'PacProfile':
        profile = new PacProfile.fromPlain(p);
        break;
      case 'SwitchyRuleListProfile':
      case 'AutoProxyRuleListProfile':
        profile = new RuleListProfile.fromPlain(p);
        break;
      case 'SwitchProfile':
        profile = new SwitchProfile.fromPlain(p);
        break;
      case 'SystemProfile':
        profile = new SystemProfile.fromPlain(p);
        break;
      default:
        throw new UnsupportedError(
          'profileType = "${p['profileType']}"');
    }
    return profile;
  }
}

/**
  A static class that holds color constants for some profiles.
*/
class ProfileColors {
  static const String profile_default = '#99ccee';
  static const String auto_detect = '#00cccc';
  static const String system = '#aaaaaa';
  static const String direct = '#aaaaaa';
}

