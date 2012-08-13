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

'use strict';
var i18nCache = {};
strings.forEach(function (name) {
  i18nCache[name] = chrome.i18n.getMessage(name);
});

var i18n = new i18nDict(i18nCache);
document.addEventListener('DOMNodeInserted', function (e) {
  if (e.target instanceof Element) {
    i18nTemplate.process(e.target, i18n);
  }
}, false);
i18nTemplate.process(document, i18n);

var isDocReady = false;

$(document).ready(function () {
  isDocReady = true;
  $('.nav-pills > li > a[href="#"]').click(function () {
    var li = $(this).parent();
    li.addClass('active');
    li.siblings().removeClass('active'); return false; 
  });
});
