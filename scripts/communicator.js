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

var Communicator = function (win, self) {
  this.dest = win;
  this._callback_maps = {};
  this._action_handlers = {};
  this.source = self || window;
  this.source.addEventListener('message', this._onmessage.bind(this), false);
};

Communicator.prototype._postMessage = function (dest, action, value, callback, reply_to) {
  var reqid = null;
  
  if (callback) {
    var map = this._callback_maps[action];
    if (!map) {
      map = this._callback_maps[action] = {};
    }
    do {
      reqid = Math.random();
    } while (map[reqid]);
    map[reqid] = callback;
  }
  
  dest.postMessage({
    'action': action,
    'reqid': reqid,
    'reply_to': reply_to,
    'value': value
  }, '*');
}

Communicator.prototype.createResponder = function (e) {
  var that = this;
  return function (value, callback) {
    that._postMessage(e.source, e.data.action, value, callback, e.data.reqid)
  };
};

Communicator.prototype._onmessage = function (e) {
  if (e.data.reply_to) {
    var map = this._callback_maps[e.data.action];
    if (map) {
      var callback = map[e.data.reply_to];
      if (callback) {
        delete map[e.data.reply_to];
        callback(e.data.value, this.createResponder(e));
      }
    }
  } else {
    var callbacks = this._action_handlers[e.data.action];
    if (callbacks) {
      var responder = this.createResponder(e);
      callbacks.forEach(function (cb) {
        cb(e.data.value, responder);
      });
    }
  }
};

Communicator.prototype.send = function (action, value, callback) {
  this._postMessage(this.dest, action, value, callback);
  
  return this;
};

// Alt signature: .on({ 'action1': callback1, 'action2': callback2 });
Communicator.prototype.on = function (action, callback) {
  if (typeof action === 'object') {
    for (var a in action) {
      if (action.hasOwnProperty(a)) {
        this.on(a, action[a])
      }
    }
  } else {
    var callbacks = this._action_handlers[action];
    if (!callbacks) {
      callbacks = this._action_handlers[action] = [];
    }
    callbacks.push(callback);
  }
  
  return this;
};