part of switchy_browser_message;

/**
 * A [MessageBrowser] sends browser requests via a [Communicator], then the
 * requested actions are performed at its target.
 */
class MessageBrowser extends Browser {
  Communicator _c;
  MessageStorage _storage;

  MessageBrowser([Communicator c = null]) {
    if (c == null) {
      this._c = new Communicator();
    } else {
      this._c = c;
    }
    this._storage = new MessageStorage(this._c);
  }

  MessageStorage get storage => _storage;

  /**
   * Transform the [profile] to a plain and browser-friendly structure, then
   * send it via the [Communicator].
   * The data strcture is based on Chromium Extensions Proxy API
   * <https://developer.chrome.com/extensions/proxy.html>, but I don't
   * mean to block other browsers. The target can transform the data
   * structure to whatever format the browser likes after receiving it.
   */
  Future applyProfile(Profile profile) {
    var completer = new Completer();

    Map<String, Object> data = {};

    if (profile is SystemProfile) {
      data['mode'] = 'system';
    } else if (profile is DirectProfile) {
      data['mode'] = 'direct';
    } else if (profile is AutoDetectProfile) {
      data['mode'] = 'auto_detect';
    } else if (profile is FixedProfile) {
      data['mode'] = 'fixed_servers';
      data['rules'] = (profile as FixedProfile).toPlain();
    } else if (profile is PacProfile) {
      data['mode'] = 'pac_script';
      data['pacScript'] = { 'url': (profile as PacProfile).pacUrl };
    } else if (profile is ScriptProfile) {
      data['mode'] = 'pac_script';
      data['pacScript'] = { 'data': (profile as ScriptProfile).toScript() };
    } else {
      throw new UnsupportedError(profile.profileType);
    }

    _c.send('proxy.apply', data, (_) {
      completer.complete(null);
    });

    return completer.future;
  }
}

/**
 * A [MessageStorage] stores and retives values via a [Communicator].
 */
class MessageStorage extends AsyncStorage {
  Communicator _c;

  MessageStorage([Communicator c = null]) {
    if (c == null) {
      this._c = new Communicator();
    } else {
      this._c = c;
    }
  }

  Future<Map<String, Object>> retive(List<String> names) {
    var completer = new Completer<Map<String, Object>>();
    _c.send('storage.retive', names, (Map<String, Object> map) {
      completer.complete(map);
    });
    return completer.future;
  }

  Future put(Map<String, Object> map) {
    var completer = new Completer();
    _c.send('storage.put', map, (_) {
      completer.complete(null);
    });
    return completer.future;
  }

  Future remove(List<String> names) {
    var completer = new Completer();
    _c.send('storage.remove', names, (_) {
      completer.complete(null);
    });
    return completer.future;
  }
}