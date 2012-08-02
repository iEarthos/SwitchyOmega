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

#library('switchy_profile');

#import('dart:core');
#import('dart:json');

#import('../lang/lib.dart');
#import('../utils/code_writer.dart');
#import('../condition/lib.dart');

#source('profile.dart');

#source('includable_profile.dart');
#source('script_profile.dart');
#source('inclusive_profile.dart');

#source('direct_profile.dart');
#source('system_profile.dart');
#source('autodetect_profile.dart');
#source('fixed_profile.dart');
#source('pac_profile.dart');
#source('switch_profile.dart');
#source('rule_list_profile.dart');

#source('profile_collection.dart');
