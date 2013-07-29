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

library switchy_profile;

import 'dart:collection';
import 'dart:core';
import 'dart:json' as JSON;
import '../code_writer.dart';
import '../condition/lib.dart';
import '../lang/lib.dart';

part 'profile.dart';

part 'includable_profile.dart';
part 'script_profile.dart';
part 'inclusive_profile.dart';

part 'direct_profile.dart';
part 'system_profile.dart';
part 'autodetect_profile.dart';
part 'fixed_profile.dart';
part 'pac_profile.dart';
part 'switch_profile.dart';
part 'rule_list_profile.dart';
part 'switchy_rule_list_profile.dart';
part 'autoproxy_rule_list_profile.dart';

part 'profile_tracker.dart';
part 'profile_collection.dart';