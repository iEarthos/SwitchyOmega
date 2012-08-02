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
 * A profile is a proxy mode that can be applied manually or automatically.
 */
abstract class Profile extends Plainable implements Hashable {
  String _name;
  /** The name of the profile. This is used as a key. */
  String get name() => _name;
  void set name(String value) {
    _name = value;
  }

  /** When overridden in derived classes, return the profile type. */
  abstract String get profileType();

  /**
    Colors can help to tell profiles from each other.
    If this profile includes other profiles, [color] should be null.
  */
  String color;

  /**
    Whether this profile is a predefined profile.
    This can be overridden to prevent this profile from being deleted or changed.
  */
  bool get predefined() => false;

  /** Simply return the hash code of [name]. */
  int hashCode() {
    return this.name.hashCode();
  }
  
  /** Create a [name]d profile. */
  Profile(String name, [this.color = ProfileColors.profile_default]) {
    this.name = name;
  }
  
  Map<String, Object> toPlain([Map<String, Object> p, Object config]) {
    if (p == null) p = new Map<String, Object>();
    p['name'] = this.name;
    p['profileType'] = this.profileType;
    p['color'] = this.color;
    
    return p;
  }
  
  factory Profile.fromPlain(Map<String, Object> p, [Object config]) {
    switch (p['profileType']) {
      case 'AutoDetectProfile':
        return new AutoDetectProfile.fromPlain(p, config);      
      case 'DirectProfile':
        return new DirectProfile.fromPlain(p, config);
      case 'FixedProfile':
        return new FixedProfile.fromPlain(p, config);
      case 'PacProfile':
        return new PacProfile.fromPlain(p, config);
      case 'RuleListProfile':
        // TODO
      case 'SwitchProfile':
        return new SwitchProfile.fromPlain(p, config);
      case 'SystemProfile':
        return new SystemProfile.fromPlain(p, config);
      default:
        throw new UnsupportedOperationException(
          'profileType = "${p['profileType']}"');
    }
  }
}

/**
  A static class that holds color constants for some profiles.
*/
class ProfileColors {
  static final profile_default = '#0000cc';
  static final auto_detect = '#00cccc';
  static final system = '#aaaaaa';
  static final direct = '#aaaaaa';
}
