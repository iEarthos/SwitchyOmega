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

library communicator;

import 'dart:html';
import 'dart:json' as JSON;
import 'dart:math';

typedef void CommunicatorCallback(Object value, [Function respond]);

class Communicator {
  WindowBase dest;
  Window source;
  Map<String, Map<String, CommunicatorCallback>> _callback_maps;
  Map<String, List<CommunicatorCallback>> _action_handlers;
  Random _random = new Random();

  Communicator([this.dest = null, this.source = null]) {
    if (this.source == null) {
      this.source = window;
    }
    _callback_maps = new Map<String, Map<String, CommunicatorCallback>>();
    _action_handlers = new Map<String, List<CommunicatorCallback>>();
    this.source.onMessage.listen(this._onmessage);
  }

  void _postMessage(WindowBase destWin, String action, Object value,
                    CommunicatorCallback callback, [String reply_to = null]) {
    String reqid;

    if (callback != null) {
      var map = this._callback_maps[action];
      if (map == null) {
        map = this._callback_maps[action] = new Map<String, CommunicatorCallback>();
      }
      do {
        reqid = _random.nextDouble().toString();
      } while (map[reqid] != null);
      map[reqid] = callback;
    }

    destWin.postMessage(JSON.stringify({
      'action': action,
      'reqid': reqid,
      'reply_to': reply_to,
      'value': value
    }), '*');
  }

  static void _doNothing(Object value, [Function respond]) {}

  CommunicatorCallback createResponder(WindowBase source, String action, String reqid) {
    if (reqid != null) {
      return (Object value, [Function respond]) {
        this._postMessage(source, action, value, respond, reqid);
      };
    } else {
      return _doNothing;
    }
  }

  void _onmessage(MessageEvent e) {
    var data = JSON.parse(e.data) as Map<String, Object>;
    var reply_to = data['reply_to'];
    if (reply_to != null) {
      var map = this._callback_maps[data['action']];
      if (map != null) {
        var callback = map[reply_to];
        if (callback != null) {
          map.remove(reply_to);
          callback(data['value'],
              this.createResponder(e.source, data['action'], data['reqid']));
        }
      }
    } else {
      var callbacks = this._action_handlers[data['action']];
      if (callbacks != null) {
        var responder = this.createResponder(
            e.source, data['action'], data['reqid']);
        callbacks.forEach((cb) {
          cb(data['value'], responder);
        });
      }
    }
  }

  Communicator send(String action, [Object value, CommunicatorCallback callback]) {
    this._postMessage(this.dest, action, value, callback);

    return this;
  }

  Communicator on(action, CommunicatorCallback callback) {
    if (action is String) {
      var actionString = action as String;
      var callbacks = this._action_handlers[action];
      if (callbacks == null) {
        callbacks = this._action_handlers[action] = [];
      }
      callbacks.add(callback);
    } else {
      var actionMap = action as Map<String, CommunicatorCallback>;
      actionMap.forEach((a, cb) {
        this.on(a, cb);
      });
    }

    return this;
  }
}
