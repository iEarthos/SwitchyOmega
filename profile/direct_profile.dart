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
 * When this profile is applied, no proxy should be used.
 */
class DirectProfile extends IncludableProfile {
  final String profileType = 'DirectProfile';
  final bool predefined = true;
  
  void writeTo(CodeWriter w) {
    w.inline("['DIRECT']");
  }

  DirectProfile._private() : super('direct') {
    this.color = ProfileColors.direct;
  }

  static DirectProfile _instance = null;
  factory DirectProfile() {
    if (_instance != null)
      return _instance;
    else
      return _instance = new DirectProfile._private();
  }
  
  factory DirectProfile.fromPlain(Object p, [Object config]) 
    => new DirectProfile();
}