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
 * Matches when the number of dots in the host is within the range
 * [minValue](inclusive) ~ [maxValue](inclusive).
 */
class HostLevelsCondition extends HostCondition {
  final String conditionType = 'HostLevelsCondition';

  /** Cache the charCode of '.' for greater speed. */
  static final int dotCharCode = 46;

  @observable int maxValue = 0;
  @observable int minValue = 0;

  bool matchHost(String host) {
    int dotCount = 0;
    for (var i = 0; i < host.length; i++) {
      if (host.codeUnitAt(i) == dotCharCode) {
        dotCount++;
        if (dotCount > maxValue) return false;
      }
    }
    return dotCount >= minValue;
  }

  void writeTo(CodeWriter w) {
    if (maxValue == minValue) {
      w.inline("host.split('.').length - 1 === $minValue");
    } else {
      w.inline('(function (a) { return a >= $minValue && a <= $maxValue; })'
             "(host.split('.').length - 1)");
    }
  }

  HostLevelsCondition([this.minValue = 0, this.maxValue = 0]) {
    this.changes.listen((_) {
      if (maxValue < minValue) {
        maxValue = minValue;
      }
    });
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['minValue'] = this.minValue;
    p['maxValue'] = this.maxValue;
    return p;
  }


  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    this.minValue = p['minValue'];
    this.maxValue = p['maxValue'];
  }

  factory HostLevelsCondition.fromPlain(Map<String, Object> p) {
    var c = new HostLevelsCondition(p['minValue'], p['maxValue']);
    c.loadPlain(p);
    return c;
  }
}
