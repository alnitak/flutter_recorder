// Build hook for flutter_recorder.
//
// Compiles the recorder engine and the plugin sources in `src/` into
// `libflutter_recorder` for the target OS/architecture, linking the
// prebuilt Xiph libraries checked into this repo (see `xiph/`).
//
// Web is not covered by hooks; the emscripten build in `web/` is unchanged.

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

import 'sources.dart';
import 'xiph.dart';

/// The asset id is `package:flutter_recorder/src/flutter_recorder.h`, matching
/// the `asset-id` in `ffigen.yaml` used by the generated `@Native` bindings.
const _assetName = 'src/flutter_recorder.h';
const _libName = 'flutter_recorder';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final code = input.config.code;
    final os = code.targetOS;
    final arch = code.targetArchitecture;
    final isApple = os == OS.macOS || os == OS.iOS;

    final xiph = XiphLink.forTarget(input);

    final defines = <String, String?>{
      'FLUTTER_PLUGIN_IMPL': null,
      // Comment out this line for debugging native code.
      // 'NDEBUG': null,
      'MA_NO_PULSEAUDIO': null,
      '_REENTRANT': '1',
      if (isApple) ...{'WITH_COREAUDIO': null, 'MA_NO_RUNTIME_LINKING': '1'},
      if (os == OS.linux) 'WITH_ALSA': null,
      if (os == OS.windows) ...{
        'NOMINMAX': null,
        '_CRT_SECURE_NO_WARNINGS': null,
      },
    };

    final flags = <String>[
      if (os != OS.windows) '-fvisibility=hidden',
      // For debugging:
      if (os == OS.windows) ...['/Od', '/Zi', '/EHsc'] else ...['-O0', '-g'],
      // For production / default:
      // if (os == OS.windows) ...['/Ox', '/EHsc'] else '-O3',
      if (os == OS.android) ...[
        '-ffast-math',
        '-funroll-loops',
        '-fomit-frame-pointer',
        '-ffunction-sections',
        '-fdata-sections',
        '-Wl,--gc-sections',
        // Support Android 15 16k page size.
        '-Wl,-z,max-page-size=16384',
        if (arch == Architecture.arm) '-mfpu=neon',
        if (arch == Architecture.ia32 || arch == Architecture.x64) ...[
          '-msse2',
          '-msse3',
        ],
      ],
      if (isApple || os == OS.linux) '-Wno-vla',
      if (os == OS.linux && arch == Architecture.x64) ...['-msse2', '-msse3'],
    ];

    final includes = ['src', 'src/pffft', ...xiph.includeDirs];

    // Workaround for miniaudio's ma_ios_notification_handler symbol conflict.
    final forcedIncludes = [if (isApple) 'ios/miniaudio_objc_prefix.h'];

    // On Apple, miniaudio.h pulls in AVFoundation Objective-C headers, so the
    // miniaudio implementation is built separately as an Objective-C++ static
    // library and linked into the plugin library below.
    if (isApple) {
      final objcBuilder = CBuilder.library(
        name: 'flutter_recorder_miniaudio_objc',
        language: Language.objectiveC,
        std: 'c++17',
        linkModePreference: LinkModePreference.static,
        sources: const ['src/flutter_recorder_miniaudio_objc.mm'],
        includes: includes,
        forcedIncludes: forcedIncludes,
        defines: defines,
        flags: flags,
      );
      await objcBuilder.run(input: input, output: output);
    }

    final builder = CBuilder.library(
      name: _libName,
      assetName: _assetName,
      language: Language.cpp,
      std: 'c++17',
      sources: collectSources(input.packageRoot, os),
      includes: includes,
      forcedIncludes: forcedIncludes,
      defines: defines,
      flags: flags,
      cppLinkStdLib: os == OS.android ? 'c++_static' : null,
      frameworks: isApple
          ? const ['Foundation', 'AudioToolbox', 'AVFAudio', 'CoreAudio']
          : const [],
      libraries: [
        ...xiph.libraries,
        if (isApple) 'flutter_recorder_miniaudio_objc',
        if (os == OS.android) ...['log', 'android'],
        if (os == OS.linux) 'asound',
      ],
      libraryDirectories: [if (isApple) '.', ...xiph.libraryDirectories],
    );
    await builder.run(input: input, output: output);

    // Bundle prebuilt shared Xiph libraries where needed.
    for (final asset in xiph.bundledAssets) {
      output.assets.code.add(asset);
    }
    for (final dependency in xiph.dependencies) {
      output.dependencies.add(dependency);
    }
  });
}
