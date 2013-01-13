part of switchy_condition;

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
 * Matches when the url matches the wildcard [pattern].
 */
class UrlWildcardCondition extends UrlCondition {
  final String conditionType = 'UrlWildcardCondition';

  String _pattern;
  String get pattern => _pattern;
  void set pattern(String value) {
    _pattern = value;
    _regex = null;
    _recorder = null;
  }

  RegExp _regex;
  CodeWriterRecorder _recorder;

  bool matchUrl(String url, scheme) {
    if (_regex == null) _regex = new RegExp(shExp2RegExp(_pattern, trimAsterisk: true));
    return _regex.hasMatch(url);
  }

  static final schemeOnlyPattern = new RegExp(r'^(\w+)://\*$');

  void writeTo(CodeWriter w) {
    if (_recorder == null) {
      _recorder = new CodeWriterRecorder();
      _recorder.inner = w;

      Match m;
      if ((m = schemeOnlyPattern.firstMatch(_pattern)) != null) {
        _recorder.inline('scheme === ${JSON.stringify(m[1])}');
      } else {
        // TODO(catus): use shExpCompile
        var regex = shExp2RegExp(_pattern, trimAsterisk: true);
        w.inline('new RegExp(${JSON.stringify(regex)}).test(url)');
        // shExpCompile(_pattern, _recorder, target: 'url');
      }
      _recorder.inner = null;
    } else {
      _recorder.replay(w);
    }
  }

  UrlWildcardCondition([String pattern = '']) {
    this._pattern = pattern;
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

  factory UrlWildcardCondition.fromPlain(Map<String, Object> p) {
    var c = new UrlWildcardCondition(p['pattern']);
    c.loadPlain(p);
    return c;
  }
}
