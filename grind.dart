import 'package:grinder/grinder.dart';
import 'package:yaml/yaml.dart';

void main([List<String> args]) {
  //defineTask('init', taskFunction: init);
  defineTask('setup', taskFunction: setup);
  //defineTask('compile', taskFunction: compile, depends: ['init']);
  //defineTask('deploy', taskFunction: deploy, depends: ['compile']);
  //defineTask('docs', taskFunction: deploy, depends: ['init']);
  //defineTask('all', depends: ['deploy', 'docs']);

  startGrinder(args);
}

List<String> _entryPoints = null;
List<String> get entryPoints {
  if (_entryPoints == null) {
    var doc = loadYaml(getFile('pubspec.yaml').readAsStringSync());
    _entryPoints = doc['transformers'][0]['polymer']['entry_points'];
  }
  return _entryPoints;
}

void setup(GrinderContext context) {
  if (sdkDir == null) {
    context.fail("Error: DART_SDK environment variable is not set.");
  }
  new PubTools().install(context);
  print(entryPoints);
}
