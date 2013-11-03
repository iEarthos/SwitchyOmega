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

library switchy_condition;

import 'dart:core';
import 'package:json/json.dart' as JSON;
import 'package:web_ui/observe/observable.dart';
import '../code_writer.dart';
import '../lang/lib.dart';
import 'shexp_utils.dart';

part 'condition.dart';

part 'const_condition.dart';

part 'host_condition.dart';
part 'host_wildcard_condition.dart';
part 'host_regex_condition.dart';
part 'host_levels_condition.dart';

part 'url_condition.dart';
part 'url_wildcard_condition.dart';
part 'url_regex_condition.dart';
part 'keyword_condition.dart';

part 'bypass_condition.dart';
part 'ip_condition.dart';
