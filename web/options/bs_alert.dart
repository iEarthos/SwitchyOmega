import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:js';

@CustomTag('bs-alert')
class BsAlertElement extends PolymerElement {
  bool get applyAuthorStyles => true;

  @published bool success = true;
  @published bool shown = true;

  BsAlertElement.created() : super.created();

  void enteredView() {
    super.enteredView();
    this.on['alerthide'].listen((_) {
      shown = false;
    });
  }

  void ready() {
    context.callMethod('onShadowHostReady', [this]);
  }

  dynamic iif(bool test, dynamic trueValue, dynamic falseValue) {
    return test ? trueValue : falseValue;
  }
}