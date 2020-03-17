import 'dart:io';
import 'package:path/path.dart' as path;

class ConfigException implements Exception {
  String _message;

  ConfigException(this._message);

  @override
  String toString() => _message;
}

class ConfigDiff {
  Directory src;
  Directory dest;
  // files that are in the src but missing from the destination
  // Could also be an entire directory - in which case we do not
  // further recurse down the directory tree.
  List<String> _missingFiles = [];
  // files that are in the destination, but not in the source.
  // not implemented. Do we need this? Yes - if the
  // destination is an export and contains extra files, we need to copy them..
  List<String> _extraFiles = [];

  ConfigDiff(this.src, this.dest);

  Future<void> findDiffs() async {
    [src, dest].forEach((dir) {
      if (!dir.existsSync()) {
        throw ConfigException(
            '${dir.path} is not a directory or does not exist');
      }
    });

    // Find all files in src missing from destination
    _missingFiles = await _walkDir(src, dest);
    // Find all files in dest missing from source
    _extraFiles = await _walkDir(dest, src);
  }

  // reversing the directories will give you the
  Future<List<String>> _walkDir(Directory s, Directory d) async {
    List<String> _missing = [];

    //print("Compare directories ${s.path} to ${d.path}");

    await s.list(recursive: false).forEach((fse) async {
      print("process $fse");
      if (fse is File) {
        var base = path.basename(fse.path);
        var p2 = File(path.join(d.path, base));
        var p2Exists = await p2.exists();
        if (!p2Exists) {
          _missing.add(p2.path);
        }
      } else if (fse is Directory) {
        var base = path.basename(fse.path);
        var dir2 = Directory(path.join(d.path, base));
        //print("** Directory! base=$base dir2=$dir2");
        var dir2Exists = await dir2.exists();
        if (!dir2Exists) {
          _missing.add(fse.path);
        } else {
          var l = await _walkDir(fse, dir2);
          _missing.addAll(l);
        }
      } else {
        throw ConfigException("File Type ${fse} not handled");
      }
    });
    return _missing;
  }

  // https://gist.github.com/thosakwe/681056e86673e73c4710cfbdfd2523a8
  static Future<void> copyDirectory(
      Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory = Directory(
            path.join(destination.absolute.path, path.basename(entity.path)));
        await newDirectory.create();
        await copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity
            .copy(path.join(destination.path, path.basename(entity.path)));
      }
    }
  }

  String toString() =>
      'ConfigDiff($src,$dest, \nmissing=$_missingFiles\nextra=$_extraFiles)';
}
