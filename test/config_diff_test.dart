import 'package:config_diff/config_diff.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'package:path/path.dart' as path;


// test directories / path
final srcDir1 =   Directory('test/data/config1');
final srcDir2 =   Directory('test/data/config2');
final srcDir3 =   Directory('test/data/config3');

final extraFile = path.join(srcDir3.path,'extrafile.txt');

void main() {

  /// copy the files in config1 to prep for testing
  setUp( () async {

    try {
      // delete any old test data
      [srcDir2,srcDir3].forEach((dir) {
        if( dir.existsSync() ) {
          dir.deleteSync(recursive: true);
        }
      });

      // create the directories.
      [srcDir2,srcDir3].forEach( (dir) => dir.createSync());

      // make dir 2 a copy of dir 1
      await ConfigDiff.copyDirectory(srcDir1, srcDir2);

      // create an extra file in in srcDir3
      File(extraFile).writeAsStringSync('Hello World');

    }
    catch(e) {
      print("Setup exception $e");
      fail("Test setup failed");
    }

  });




  test('basic config tests', () async {
    var c= ConfigDiff(Directory('./foo'), Directory('./bar'));

    // test that a bogus directory compare does not work
    expect( () => c.findDiffs(), throwsA(TypeMatcher<ConfigException>()));

//    c = ConfigDiff(srcDir1,srcDir2);
//    await c.walk();

    c = ConfigDiff(srcDir1,srcDir3);
    await c.findDiffs();
    print('Config Diff = $c');

  });
}
