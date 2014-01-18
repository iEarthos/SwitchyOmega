import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:js';
import 'package:switchyomega/switchyomega.dart';
import 'options_utils.dart';

@CustomTag('sw-profile-editor')
class SwProfileEditorElement extends PolymerElement with SwitchyOptionsUtils {
  bool get applyAuthorStyles => true;
  @published Profile profile = null;
  @published List<String> resultProfiles = null;

  SwProfileEditorElement.created() : super.created();

  void enteredView() {
    super.enteredView();
    context.callMethod('onShadowHostReady', [this]);
  }

  @reflectable
  void dispatchInput(event, detail, target) {
    target.dispatchEvent(new Event('input'));
  }

  @reflectable bool get isRuleList => profile is RuleListProfile;

  @reflectable bool get isInclusiveProfile => profile is InclusiveProfile;
}