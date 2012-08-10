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

typedef void DynamicEventCallback(Event e, Element matchedNode);

Map<String, Map<String, List<DynamicEventCallback>>> _dynamicEventHandlers = null;
void dynamicEvent(String name, String selector, DynamicEventCallback listener) {
  if (_dynamicEventHandlers == null) {
    _dynamicEventHandlers = new Map<String, Map<String, List<DynamicEventCallback>>>();
  }
  var h = _dynamicEventHandlers[name];
  List<DynamicEventCallback> l = null;
  if (h == null) {
    h = _dynamicEventHandlers[name] = new Map<String, List<DynamicEventCallback>>();
    document.on[name].add(function (e) {
      for (var cur = e.target; 
           cur != e.currentTarget;
           cur = ifNull(cur.parent, e.currentTarget)) {
        if (cur is Element) {
          _dynamicEventHandlers[e.type].forEach((selector, handlers) {
            if (cur.matchesSelector(selector)) {
              handlers.forEach((handler) { handler(e, cur); });
            }
          });
        }
      }
    });
  } else {
    l = h[selector];
  }
  if (l == null) {
    l = h[selector] = new List<DynamicEventCallback>();
  }
  l.add(listener);
}
