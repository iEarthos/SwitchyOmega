/*!
 * Copyright (C) 2012-2013, The SwitchyOmega Authors. Please see the AUTHORS
 * file for details.
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

library switchy_options_utils;

import 'package:switchyomega/html/lib.dart' as h;
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:polymer_expressions/filter.dart';
import 'package:polymer/polymer.dart';
import 'dart:html';

class SwitchyOptionsUtils {
  static final Map<String, String> static_conditionTypesDisplay = const {
      'HostWildcardCondition': 'condition_hostWildcard',
      'HostRegexCondition': 'condition_hostRegex',
      'HostLevelsCondition': 'condition_hostLevels',
      'UrlWildcardCondition': 'condition_urlWildcard',
      'UrlRegexCondition': 'condition_urlRegex',
      'KeywordCondition': 'condition_keyword',
      'AlwaysCondition': 'condition_always',
      'NeverCondition': 'condition_never'
  };

  @reflectable
  final Map<String, String> conditionTypesDisplay =
      static_conditionTypesDisplay;

  @reflectable
  final List<String> conditionTypes =
      static_conditionTypesDisplay.keys.toList();

  static final Map<String, String> static_profileIcons = const {
      'FixedProfile': 'icon-globe',
      'PacProfile': 'icon-tasks',
      'RulelistProfile': 'icon-list',
      'SwitchProfile': 'icon-retweet',
      'SwitchyRuleListProfile': 'icon-list',
      'AutoProxyRuleListProfile': 'icon-list'
  };

  @reflectable
  final Map<String, String> profileIcons = static_profileIcons;

  @reflectable
  final List<String> profileTypes = const ['FixedProfile',
                                           'SwitchProfile',
                                           'PacProfile',
                                           'SwitchyRuleListProfile',
                                           'AutoProxyRuleListProfile'];


  PolymerExpressions syntax = new PolymerExpressionsWithEventDelegate(
      globals: {'int2str': new Int2StringTransformer()});

  @reflectable
  String cssSafeId(String identifier) => h.cssSafeId(identifier);

  /** Returns [def] if [test] == null. Otherwise [test]. */
  @reflectable
  dynamic ifNull(dynamic test, dynamic def) {
    return test == null ? def : test;
  }

  @reflectable
  dynamic iif(bool test, dynamic trueValue, dynamic falseValue) {
    return test ? trueValue : falseValue;
  }
}

class Int2StringTransformer extends Transformer<String, int> {
  String forward(int v) => v.toString();
  int reverse(String t) => int.parse(t);
}

class PolymerExpressionsWithEventDelegate extends PolymerExpressions {
  PolymerExpressionsWithEventDelegate({Map<String, Object> globals})
      : super(globals: globals);

  prepareBinding(String path, name, node) =>
      Polymer.prepareBinding(path, name, node, super.prepareBinding);
}