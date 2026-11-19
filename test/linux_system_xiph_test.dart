@TestOn('linux')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks/hooks.dart';

import '../hook/build.dart' as hook;

// Requires pkg-config and the Ogg/Opus/SpeexDSP development packages.
void main() {
  test(
    'system Xiph hook builds a loadable library without vendored assets',
    () async {
      await testCodeBuildHook(
        mainMethod: hook.main,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'linux_use_system_xiph': true},
            basePath: Directory.current.uri,
          ),
        ),
        check: (input, output) {
          final asset = output.assets.code.single;
          expect(
            output.dependencies.any(
              (file) => file.path.contains('linux/libs/'),
            ),
            isFalse,
          );
          expect(
            output.dependencies.where((file) => file.path.endsWith('.pc')),
            hasLength(3),
          );
          final library = DynamicLibrary.open(asset.file!.toFilePath());
          final initialized = library
              .lookupFunction<Int32 Function(), int Function()>(
                'flutter_recorder_isInited',
              );
          expect(initialized(), 0);
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
