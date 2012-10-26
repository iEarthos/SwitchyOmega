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

library code_writer;
import 'dart:core';

/**
 * A helper to emit code.
 */
abstract class CodeWriter {
  /**
   * Indent by one level. Returns [:this:].
   */
  CodeWriter indent();

  /**
   * Outdent by one level.
   */
  CodeWriter outdent();

  /**
   * Add [codeStr] to the code and then start a [newLine].
   * If at a line start, [codeStr] will be indented at the current level.
   * if [autoIndent] is true, [indent] and [outdent] will be automatically
   * called based on the content of [codeStr]. Returns [:this:].
   */
  CodeWriter code(String codeStr, [bool autoIndent]);

  /**
   * Add [codeStr] to the code without any indentation or formatting.
   * Returns [:this:].
   */
  CodeWriter raw(String codeStr);

  /**
   * Start a new line. New lines will be indented unless [raw] is called.
   * Returns [:this:].
   */
  CodeWriter newLine();

  /**
   * Write some code without starting a new line after [codeStr].
   * For [autoIndent], see the docs of [code]. Returns [:this:].
   */
  CodeWriter inline(String codeStr, [bool autoIndent]);

  /**
   * Returns all the stuff written to the code writer so far as a string.
   */
  String toString();

  factory CodeWriter() {
    return new WellFormattedCodeWriter();
  }
}

/**
 * A good code writer which emits well-formatted code.
 * [lineBreak]s and [indentStr] will be added to the code when needed.
 * It uses [StringBuffer] internally for better performance.
 */
class WellFormattedCodeWriter implements CodeWriter {
  StringBuffer _sb;
  int _indentCount = 0;

  /**
   * Added to the code before starting a [newLine].
   */
  String lineBreak = '\n';

  /**
   * Added to the beginning of every line.
   * It will be added twice if [indent]ed twice and so on.
   */
  String indentStr = '  ';

  /**
   * When the charCode of the last char in a line is in this set,
   * [indent] will be called automatically for the next line.
   * Note: [inline] will not trigger auto indentation,
   * since the line is not ended.
   */
  Set<int> indentingSymbols;

  /**
   * When the charCode of the first char in a line is in this set,
   * [outdent] will be called automatically before writing this line.
   * Both [code] and [inline] can trigger auto outdentation if the current
   * position is a line start.
   */
  Set<int> outdentingSymbols;

  String _currentIndent = '';

  WellFormattedCodeWriter() {
    _sb = new StringBuffer();
    indentingSymbols = new HashSet.from('({['.charCodes());
    outdentingSymbols = new HashSet.from(')}]'.charCodes());
  }

  CodeWriter indent() {
    _indentCount++;
    _currentIndent = '$_currentIndent$indentStr';
    return this;
  }

  CodeWriter outdent() {
    _indentCount--;
    _currentIndent = _currentIndent.substring(
      0, _currentIndent.length - indentStr.length);
    return this;
  }

  bool _lineStart = true;

  CodeWriter code(String codeStr, [bool autoIndent = true]) {
    if (_lineStart) {
      if (autoIndent && outdentingSymbols.contains(codeStr.charCodeAt(0))) {
        outdent();
      }
      _sb.add(_currentIndent);
    }
    _sb.add(codeStr).add(lineBreak);
    if (autoIndent &&
        indentingSymbols.contains(codeStr.charCodeAt(codeStr.length - 1))) {
      indent();
    }
    _lineStart = true;
    return this;
  }

  CodeWriter raw(String codeStr) {
    _sb.add(codeStr);
    return this;
  }

  CodeWriter newLine() {
    _sb.add(lineBreak);
    _lineStart = true;
    return this;
  }

  CodeWriter inline(String codeStr, [bool autoIndent = true]) {
    if (_lineStart) {
      if (autoIndent && outdentingSymbols.contains(codeStr.charCodeAt(0))) {
        outdent();
      }
      _sb.add(_currentIndent);
    }
    _sb.add(codeStr);
    _lineStart = false;
    return this;
  }

  String toString() => _sb.toString();
}

/**
 * This class records all method calls and can [replay] them when needed.
 * If a [inner] [CodeWriter] is set, the method calls are also passed to it.
 */
class CodeWriterRecorder implements CodeWriter {
  /**
   * This class will proxy method calls to the inner writer if not [:null:].
   */
  CodeWriter inner;

  List<_CodeWriterMethodCall> _tape;

  CodeWriterRecorder() {
    _tape = new List<_CodeWriterMethodCall>();
  }

  CodeWriter indent() {
    if (inner != null) inner.indent();
    _tape.add(const _CodeWriterMethodCall('indent'));
    return this;
  }

  CodeWriter outdent() {
    if (inner != null) inner.outdent();
    _tape.add(const _CodeWriterMethodCall('outdent'));
    return this;
  }

  CodeWriter code(String codeStr, [bool autoIndent = true]) {
    if (inner != null) inner.code(codeStr, autoIndent);
    _tape.add(new _CodeWriterMethodCall('code', codeStr, autoIndent));
    return this;
  }

  CodeWriter raw(String codeStr) {
    if (inner != null) inner.code(codeStr);
    _tape.add(new _CodeWriterMethodCall('raw', codeStr));
    return this;
  }

  CodeWriter newLine() {
    if (inner != null) inner.newLine();
    _tape.add(const _CodeWriterMethodCall('newLine'));
    return this;
  }

  CodeWriter inline(String codeStr, [bool autoIndent]) {
    if (inner != null) inner.inline(codeStr);
    _tape.add(new _CodeWriterMethodCall('inline', codeStr, autoIndent));
    return this;
  }

  /**
   * Returns [:inner.toString:] if inner is not null. Otherwise returns null.
   */
  String toString() {
    return inner != null ? inner.toString() : null;
  }

  /**
   * Replay all the method calls on this class to [w].
   * If [w] is null or omitted, actions will be replayed on [inner].
   * If both [w] and [inner] is null, nothing happens.
   * Returns [:this:].
   */
  CodeWriter replay([CodeWriter w = null]) {
    if (w == null) {
      if (inner == null) return this;
      w = inner;
    }
    for (var call in _tape) {
      switch (call.name) {
        case 'indent':
          w.indent();
          break;
        case 'outdent':
          w.outdent();
          break;
        case 'newLine':
          w.newLine();
          break;
        case 'raw':
          w.raw(call.codeStr);
          break;
        case 'inline':
          w.inline(call.codeStr, call.autoIndent);
          break;
        case 'code':
          w.code(call.codeStr, call.autoIndent);
          break;
      }
    }
    return this;
  }
}

class _CodeWriterMethodCall {
  final String name;
  final String codeStr;
  final bool autoIndent;

  const _CodeWriterMethodCall(this.name, [this.codeStr = null, this.autoIndent = null]);
}