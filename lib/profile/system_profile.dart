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
 * This profile instructs the brower to use settings from the enviroment.
 */
class SystemProfile extends Profile {
  final String profileType = 'SystemProfile';
  final bool predefined = true;

  SystemProfile._private() : super('system') {
    this.color = ProfileColors.system;
  }

  static SystemProfile _instance = null;

  factory SystemProfile() {
    if (_instance != null) {
      return _instance;
    } else {
      return _instance = new SystemProfile._private();
    }
  }

  void loadPlain(Object p) {}

  factory SystemProfile.fromPlain(Object p)
    => new SystemProfile();
}
