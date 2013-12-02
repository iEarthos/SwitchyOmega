import 'dart:io';
import 'package:polymer/builder.dart' as polymer;
import 'package:grinder/grinder.dart';
import 'grind.dart' show entryPoints;

List<String> main_args;
void main([List<String> args = const []]) {
  main_args = args;
  new Grinder()
    ..addTask(new GrinderTask('setup', taskFunction: setup))
    ..addTask(new GrinderTask('lint', taskFunction: lint, depends: ['setup']))
    ..start(['lint']);
}

void setup(GrinderContext context) {
  runDartScript(context, 'grind.dart', arguments: ['setup']);
}

void lint(GrinderContext context) {
  polymer.lint(options: polymer.parseOptions(main_args),
      entryPoints: entryPoints);
}
