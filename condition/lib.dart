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

#library('switchy_condition');

#import('dart:core');
#import('dart:uri');
#import('dart:json');

#import('../lang/lib.dart');
#import('../utils/code_writer.dart');
#import('shexp_utils.dart');

#source('condition.dart');

#source('const_condition.dart');

#source('host_condition.dart');
#source('host_wildcard_condition.dart');
#source('host_regex_condition.dart');
#source('host_levels_condition.dart');

#source('url_condition.dart');
#source('url_wildcard_condition.dart');
#source('url_regex_condition.dart');
#source('keyword_condition.dart');

#source('bypass_condition.dart');
#source('ip_condition.dart');
