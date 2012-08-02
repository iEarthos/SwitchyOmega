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
 * When this profile is applied, the proxy is detected by running the WPAD
 * script which can be downloaded at <http://wpad/wpad.dat>.
 */
class AutoDetectProfile extends PacProfile {
  final String profileType = 'AutoDetectProfile';
  final bool predefined = true;

  final String pacUrl = 'http://wpad/wpad.dat';

  AutoDetectProfile._private() : super('auto_detect') {
    this.color = ProfileColors.auto_detect;
  }

  static AutoDetectProfile _instance = null;
  factory AutoDetectProfile() {
    if (_instance != null)
      return _instance;
    else
      return _instance = new AutoDetectProfile._private();
  }
  
  factory AutoDetectProfile.fromPlain(Object p, [Object config])
    => new AutoDetectProfile();
}
