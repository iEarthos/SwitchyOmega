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

'use strict';

function i18nDict(data) {
  this.data = data;
}

i18nDict.prototype.getValue = function (name) {
  if (!name) return '';
  var data = this.data;
  var result = data[name];
  if (typeof result === 'undefined') {
    console.error('Undefined i18n cache entry: ' + name);
    result = '<unknown>';
  }
  return result;
};

i18nDict.prototype.getString = function (name) {
  return this.getValue(name);
};
