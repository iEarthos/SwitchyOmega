import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:js';
import 'package:switchyomega/switchyomega.dart';
import 'package:switchyomega/condition/shexp_utils.dart';
import 'package:polymer_expressions/polymer_expressions.dart';
import 'options_utils.dart';

@CustomTag('sw-rule-editor')
class SwRuleEditorElement extends TableRowElement
    with Polymer, Observable, SwitchyOptionsUtils {
  bool get applyAuthorStyles => true;
  @published Rule rule = null;
  @published Profile profile = null;
  @published List<String> resultProfiles = null;

  SwRuleEditorElement.created() : super.created() {
    polymerCreated();
  }

  void enteredView() {
    super.enteredView();
    context.callMethod('onShadowHostReady', [this]);

    if (rule.condition is RegexCondition) {
      _regex = (rule.condition as PatternBasedCondition).pattern;
    } else if (rule.condition is PatternBasedCondition) {
      _pattern = (rule.condition as PatternBasedCondition).pattern;
    } else {
      _pattern = '';
    }
  }

  void requestRemoveRule(event, detail, target) {
    dispatchEvent(new CustomEvent('removerule', detail: rule));
  }

  @reflectable
  bool get isPatternBasedCondition => rule.condition is PatternBasedCondition;

  void _setPattern() {
    if (rule.condition is RegexCondition) {
      (rule.condition as RegexCondition).pattern = _regex;
    } else if (rule.condition is PatternBasedCondition) {
      (rule.condition as PatternBasedCondition).pattern = _pattern;
    }
  }

  static String convertPattern(PatternBasedCondition from, String toType) {
    if (toType.contains('Regex')) {
      String regex = null;
      if (from is HostWildcardCondition) {
        regex = from.magicRegex();
        if (toType == 'UrlRegexCondition') {
          var host = regex.replaceFirst(r'(^|\.)', r'([^/.]+\.)*')
              .replaceAll(r'$', '/');
          regex = '://$host';
        }
        return regex;
      } else if (from is KeywordCondition) {
        return shExp2RegExp('*${from.pattern}*', trimAsterisk: true);
      } else if (from is UrlWildcardCondition) {
        regex = from.convert2Regex();
      }
      if (from is UrlWildcardCondition || from is UrlRegexCondition &&
          toType == 'HostRegexCondition') {
        // Try to parse URL regex like ".*://HOST_PART/.*"
        var r = new RegExp(r'^(\.\*)?://(.*)/(\.\*)?$');
        var match = r.firstMatch(from.pattern);
        if (match != null) {
          return match[2];
        }
      }
      return regex;
    } else {
      if (from is HostWildcardCondition &&
          toType == 'UrlWildcardCondition') {
        // Well, not exactly when pattern contain wildcards.
        return '*://${from.pattern}/*';
      } else if (from is UrlWildcardCondition &&
          toType == 'HostWildcardCondition') {
        // Try to parse host wildcard like "*://HOST_PART/*"
        var r = new RegExp(r'^\*://(.*)/\*$');
        var match = r.firstMatch(from.pattern);
        if (match != null) {
          return match[1];
        }
      } else if (from is KeywordCondition) {
        return '*${from.pattern}*';
      } else if (toType == 'KeywordCondition') {
        if (from is RegexCondition) {
          // Try to parse regex like ".*KEYWORD.*"
          var r = new RegExp(
              r'^(\.\*)?([^\[\\\^\$\.\|\?\*\+\(\)\{\}]*)(\.\*)?$');
          var match = r.firstMatch(from.pattern);
          if (match != null) {
            return match[2];
          }
        } else {
          // Try to parse wildcard like "*KEYWORD*"
          var r = new RegExp(r'^\*([^\*\?]*)\*$');
          var match = r.firstMatch(from.pattern);
          if (match != null) {
            return match[1];
          }
        }
      }
    }
    return null;
  }

  @observable
  String get conditionType => rule.condition.conditionType;

  void set conditionType(String value) {
    var converted_pattern = '';
    // Try converting some known conditions.
    if (rule.condition is PatternBasedCondition) {
      converted_pattern = ifNull(convertPattern(
          rule.condition as PatternBasedCondition,
          value), '');
    }

    var old_type = rule.condition.conditionType;
    rule.condition = new Condition.fromPlain({
      'conditionType': value,
      'pattern': converted_pattern
    });

    if (converted_pattern.length > 0) {
      if (rule.condition is RegexCondition) {
        _regex = converted_pattern;
      } else {
        _pattern = converted_pattern;
      }
    } else {
      // Keep the pattern so that the user can edit it.
      if (rule.condition is RegexCondition) {
        _pattern = _pattern.length > 0 ? _pattern : _regex;
      } else if (rule.condition is PatternBasedCondition) {
        _regex = _regex.length > 0 ? _regex : _pattern;
      }
    }
    if (rule.condition is HostLevelsCondition) {
      var cond = rule.condition as HostLevelsCondition;
      cond.minValue = cond.maxValue = 1;
    }
    this.notifyPropertyChange(#conditionType, old_type,
        rule.condition.conditionType);
    this.notifyPropertyChange(#isPatternBasedCondition, null,
        isPatternBasedCondition);
    this.notifyPropertyChange(#pattern, null, pattern);
    _setPattern();
  }

  String _pattern = '';
  String _regex = '';

  @reflectable
  String get pattern {
    if (rule.condition is RegexCondition) return _regex;
    if (rule.condition is PatternBasedCondition) return _pattern;
    return '';
  }

  void set pattern(String value) {
    if (rule.condition is RegexCondition) {
      _regex = value;
      _pattern = '';
    } else {
      _pattern = value;
      _regex = '';
    }
    _setPattern();
  }
}