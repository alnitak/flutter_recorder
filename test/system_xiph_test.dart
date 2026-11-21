@TestOn('linux || mac-os')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks/hooks.dart';

import '../hook/build.dart' as hook;

// Requires pkg-config and the Ogg/Opus/SpeexDSP development packages
// (Linux distribution packages, or Homebrew/MacPorts on macOS).
void main() {
  final os = Platform.isMacOS ? 'macos' : 'linux';
  var hasSystemXiph = false;
  try {
    hasSystemXiph =
        Process.runSync('pkg-config', [
          '--exists',
          'ogg',
          'opus',
          'speexdsp',
        ]).exitCode ==
        0;
  } on ProcessException {
    // The default prebuilt build does not require pkg-config.
  }
  test(
    'system Xiph hook builds a loadable library without vendored assets',
    () async {
      await testCodeBuildHook(
        mainMethod: hook.main,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'${os}_use_system_xiph': true},
            basePath: Directory.current.uri,
          ),
        ),
        check: (input, output) {
          final asset = output.assets.code.single;
          expect(
            output.dependencies.any((file) => file.path.contains('$os/libs/')),
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
    skip: hasSystemXiph
        ? null
        : 'Requires pkg-config and Ogg/Opus/SpeexDSP development packages',
  );
}
