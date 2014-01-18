import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:js';
import 'package:switchyomega/switchyomega.dart';
import 'options_utils.dart';

@CustomTag('sw-options-nav')
class SwOptionsNavElement extends PolymerElement with SwitchyOptionsUtils {
  bool get applyAuthorStyles => true;
  @published ProfileCollection profiles = null;

  SwOptionsNavElement.created() : super.created();

  void enteredView() {
    super.enteredView();
    context.callMethod('onShadowHostReady', [this]);
  }

}