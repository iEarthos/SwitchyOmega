import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:js';
import 'dart:async';
import 'package:switchyomega/html/lib.dart';

@CustomTag('bs-modal')
class BsModalElement extends PolymerElement {
  bool get applyAuthorStyles => true;

  @published bool shown = true;
  @published Function validator = () => true;
  @published String confirmBtnClass = '';
  @published String confirmBtnText = '';
  @published String confirmBtnI18n = '';
  @observable String result = '';

  BsModalElement.created() : super.created();

  void enteredView() {
    super.enteredView();
    context.callMethod('onShadowHostReady', [this]);
    this.shadowRoot.on['click'].listen((e) {
      var result = closestElement(e.target, '[data-modal-result]');
      if (result != null) {
        this.result = result.attributes['data-modal-result'];
      }
      var dismiss = closestElement(e.target, '[data-dismiss="modal"]');
      if (dismiss != null) {
        context.callMethod('bsHideModal', [this]);
      }
    });
  }

  void show([Function callback = null]) {
    result = null;
    context.callMethod('bsShowModal', [this]);
    if (callback != null) {
      StreamSubscription sub;
      sub = this.on['modalhide'].listen((e) {
        if (sub != null) {
          callback(result);
          sub.cancel();
          sub = null;
        }
      });
    }
  }

  dynamic iif(bool test, dynamic trueValue, dynamic falseValue) {
    return test ? trueValue : falseValue;
  }
}