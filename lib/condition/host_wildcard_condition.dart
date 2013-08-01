part of switchy_condition;

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
 * Matches when the host matches the wildcard [pattern].
 * Magic happens to the [pattern], see
 * <https://github.com/FelisCatus/SwitchyOmega/wiki/Host-wildcard-condition>.
 */
class HostWildcardCondition extends HostCondition
    with PatternBasedCondition {
  final String conditionType = 'HostWildcardCondition';

  @observable String pattern;

  bool _magic_subdomain = false;
  RegExp _regex;
  CodeWriterRecorder _recorder;

  /**
   * Get the magical regex of this pattern. See
   * <https://github.com/FelisCatus/SwitchyOmega/wiki/Host-wildcard-condition>
   * for the magic.
   */
  String magicRegex() {
    if (pattern.startsWith('**.')) {
      return shExp2RegExp(pattern.substring(1), trimAsterisk: true);
    } else if (pattern.startsWith('*.')) {
      return shExp2RegExp(pattern.substring(2), trimAsterisk: true)
          .replaceFirst('^', r'(^|\.)');
    }

    return shExp2RegExp(pattern, trimAsterisk: true);
  }

  bool matchHost(String host) {
    if (_regex == null) _regex = new RegExp(magicRegex());

    return _regex.hasMatch(host);
  }

  void writeTo(CodeWriter w) {
    if (_recorder == null) {
      _recorder = new CodeWriterRecorder();
      _recorder.inner = w;

      // TODO(catus): use shExpCompile
      _recorder.inline(
          'new RegExp(${JSON.stringify(magicRegex())}).test(host)');
      // shExpCompile(_pattern, _recorder, target: 'host');

      _recorder.inner = null;
    } else {
      _recorder.replay(w);
    }
  }

  HostWildcardCondition([String pattern = '']) {
    this.pattern = pattern;
    observe(this as Observable, (_) {
      _regex = null;
      _recorder = null;
    });
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['pattern'] = this.pattern;
    return p;
  }


  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    this.pattern = p['pattern'];
  }

  factory HostWildcardCondition.fromPlain(Map<String, Object> p) {
    var c = new HostWildcardCondition(p['pattern']);
    c.loadPlain(p);
    return c;
  }
}
