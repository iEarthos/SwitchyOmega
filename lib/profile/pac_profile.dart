part of switchy_profile;

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
 * A PAC profile selects the proxy by running a [pacScript].
 * If [pacUrl] is not null, the script is downloaded from [pacUrl].
 */
class PacProfile extends ScriptProfile implements UpdatingProfile {
  String get profileType => 'PacProfile';

  @observable String pacUrl = '';

  @observable String pacScript = '';

  String toScript() => this.pacScript;

  String get updateUrl => pacUrl;

  void applyUpdate(String data) {
    this.pacScript = data;
  }

  /**
   * Write a wrapper function around the [pacScript].
   */
  void writeTo(CodeWriter w) {
    w.code('(function () {');

    w.newLine().raw(this.pacScript).newLine().newLine();

    w.code('return function (url, host) { return [ FindProxyForURL(url, host) ]; };');
    w.inline('})()');
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);

    if (pacUrl != null && pacUrl.length > 0) {
      p['pacUrl'] = this.pacUrl;
    }
    p['pacScript'] = this.pacScript;

    return p;
  }

  PacProfile(String name) : super(name) {
    this.changes.listen((records) {
      if (records.any((rec) => rec is PropertyChangeRecord &&
          rec.name == #pacUrl && rec.newValue != rec.oldValue &&
          rec.newValue != null && rec.newValue != '')) {
        this.pacScript = '';
      }
    });
  }

  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    var u = p['pacUrl'];
    if (u != null) {
      this.pacUrl = u;
    }

    var sub;
    sub = this.changes.listen((records) {
      pacScript = p['pacScript'];
      sub.cancel();
    });
  }

  factory PacProfile.fromPlain(Map<String, Object> p) {
    if (p['profileType'] == 'AutoDectProfile') {
      return new AutoDetectProfile.fromPlain(p);
    }
    var f = new PacProfile(p['name']);
    f.loadPlain(p);
    return f;
  }
}
