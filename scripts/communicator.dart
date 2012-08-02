#library('communicator');

#import('dart:html');

typedef void CommunicatorCallback(Object value, [Function respond]);

class Communicator {
  Window dest;
  Window source;
  Map<String, Map<String, CommunicatorCallback>> _callback_maps;
  Map<String, List<CommunicatorCallback>> _action_handlers;
  
  Communicator([this.dest = null, this.source = null]) {
    if (this.source == null) {
      this.source = window;
    }
    _callback_maps = new Map<String, Map<String, CommunicatorCallback>>();
    _action_handlers = new Map<String, List<CommunicatorCallback>>();
    this.source.on.message.add(this._onmessage);
  }
  
  void _postMessage(Window dest, String action, Object value,
                    CommunicatorCallback callback, [String reply_to = null]) {
    String reqid;
    
    if (callback != null) {
      var map = this._callback_maps[action];
      if (map == null) {
        map = this._callback_maps[action] = new Map<String, CommunicatorCallback>();
      }
      do {
        reqid = Math.random().toString();
      } while (map[reqid] != null);
      map[reqid] = callback;
    }
    
    dest.postMessage({
      'action': action,
      'reqid': reqid,
      'reply_to': reply_to,
      'value': value
    }, '*');
  }
  
  CommunicatorCallback createResponder(MessageEvent e) {
    return (value, [callback]) {
      this._postMessage(e.source, e.data['action'], value, callback, e.data['reqid']);
    };
  }
  
  void _onmessage(MessageEvent e) {
    
    var reply_to = e.data['reply_to'];
    if (reply_to != null) {
      var map = this._callback_maps[e.data['action']];
      if (map != null) {
        var callback = map[reply_to];
        if (callback != null) {
          map.remove(reply_to);
          callback(e.data['value'], this.createResponder(e));
        }
      }
    } else {
      var callbacks = this._action_handlers[e.data['action']];
      if (callbacks != null) {
        var responder = this.createResponder(e);
        callbacks.forEach((cb) {
          cb(e.data['value'], responder);
        });
      }
    }
  }
  
  Communicator send(String action, Object value, CommunicatorCallback callback) {
    this._postMessage(this.dest, action, value, callback);
    
    return this;
  }
  
  Communicator on(action, CommunicatorCallback callback) {
    if (action is String) {
      var actionString = action; // CAST
      var callbacks = this._action_handlers[action];
      if (callbacks == null) {
        callbacks = this._action_handlers[action] = [];
      }
      callbacks.push(callback);
    } else {
      Map<String, CommunicatorCallback> actionMap = action; // CAST
      actionMap.forEach((a, cb) {
        this.on(a, cb)
      });
    }
    
    return this;
  }
}
