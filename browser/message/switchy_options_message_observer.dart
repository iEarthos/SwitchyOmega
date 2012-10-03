
class SwitchyOptionsMessageObserver extends SwitchyOptionsObserver {
  Communicator _c;
  
  MessageBrowser([Communicator c = null]) {
    if (c == null) {
      this._c = new Communicator();
    } else {
      this._c = c;
    }
  }
  
  void optionModified(String optionName, Object value) {
    _c.send('options.change', { 
      'name': optionName,
      'value': value
    });
  }
  
  void profileAddedOrChanged(Profile profile) {
    _c.send('profile.update', profile.toPlain());
  }
  
  void profileRemoved(String name) {
    _c.send('profile.remove', name);
  }
}
