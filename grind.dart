import 'package:grinder/grinder.dart';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

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
  new PubTools().get(context);

  if (FileSystemEntity.isLinkSync('web/packages')) {
    new Link('web/packages').deleteSync();
  }
  var destDir = getDir('web/packages')..createSync();
  for (FileSystemEntity entity in getDir('packages').listSync()) {
    if (FileSystemEntity.identicalSync(entity.resolveSymbolicLinksSync(),
          getDir('lib').absolute.path)) {
      if (FileSystemEntity.isLinkSync(entity.path)) {
        entity = new Link(entity.path);
      } else {
        continue;
      }
    }
    if (entity is Directory) {
      copyDirectory(entity, joinDir(destDir, [fileName(entity)]));
    } else if (entity is File) {
      copyFile(entity, destDir);
    } else if (entity is Link) {
      var linkFile = new Link(path.join(destDir.path, fileName(entity)));
      var target = entity.targetSync();

      if (path.isRelative(target)) {
        target = path.relative(path.join('packages', target),
            from: destDir.path);
      }

      if (!FileSystemEntity.isLinkSync(linkFile.path) ||
          !FileSystemEntity.isDirectorySync(linkFile.targetSync()) ||
          FileSystemEntity.identicalSync(linkFile.targetSync(), target)) {
        if (FileSystemEntity.typeSync(linkFile.path, followLinks: false) !=
            FileSystemEntityType.NOT_FOUND) {
          linkFile.deleteSync(recursive: true);
        }
        linkFile.createSync(target);
      }
    }
  }

  var packagesDir = getDir('web/packages');

  for (FileSystemEntity entity in getDir('web').listSync(
        recursive: true, followLinks: false)) {
    if (entity is Link && fileName(entity) == 'packages') {
      entity.updateSync(path.relative(packagesDir.path,
            from: entity.parent.path));
    }
  }
}
