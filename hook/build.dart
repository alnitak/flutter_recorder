// Build hook for flutter_recorder.
//
// Compiles the recorder engine and the plugin sources in `src/` into
// `libflutter_recorder` for the target OS/architecture, linking the
// prebuilt Xiph libraries checked into this repo (see `xiph/`).
//
// Web is not covered by hooks; the emscripten build in `web/` is unchanged.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// The asset id is `package:flutter_recorder/src/flutter_recorder.h`, matching
/// the `asset-id` in `ffigen.yaml` used by the generated `@Native` bindings.
const _assetName = 'src/flutter_recorder.h';
const _libName = 'flutter_recorder_plugin';

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

/// Collects the plugin sources (paths relative to [packageRoot]) for
/// [targetOS].
List<String> collectSources(Uri packageRoot, OS targetOS) {
  final rootPath = packageRoot.toFilePath().replaceAll(r'\', '/');
  final isApple = targetOS == OS.macOS || targetOS == OS.iOS;
  final sources = <String>[];

  void addDir(
    String rel, {
    bool recursive = false,
    List<String> extensions = const ['.cpp'],
    bool Function(String path)? exclude,
  }) {
    final dir = Directory.fromUri(packageRoot.resolve('src/$rel'));
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: recursive)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!extensions.any(path.endsWith)) continue;
      if (exclude?.call(path) ?? false) continue;
      final relPath = path.startsWith(rootPath)
          ? path.substring(rootPath.length)
          : path;
      sources.add(relPath.startsWith('/') ? relPath.substring(1) : relPath);
    }
  }

  // Core plugin sources.
  // On Apple, miniaudio.cpp is compiled via flutter_recorder_miniaudio_objc.mm.
  addDir(
    '',
    exclude: (p) =>
        isApple &&
        (p.endsWith('/miniaudio.cpp') ||
            p.endsWith('/flutter_recorder_miniaudio_objc.mm')),
  );
  addDir('pffft/', extensions: const ['.c', '.cpp']);
  addDir('filters/');

  return sources..sort();
}

final _androidAbi = {
  Architecture.arm: 'armeabi-v7a',
  Architecture.arm64: 'arm64-v8a',
  Architecture.ia32: 'x86',
  Architecture.x64: 'x86_64',
};

/// How the prebuilt Xiph libraries are linked for one target.
final class XiphLink {
  XiphLink._({
    required this.libraries,
    required this.libraryDirectories,
    required this.includeDirs,
    required this.bundledAssets,
    required this.dependencies,
  });

  factory XiphLink.empty() => XiphLink._(
    libraries: const [],
    libraryDirectories: const [],
    includeDirs: const [],
    bundledAssets: const [],
    dependencies: const [],
  );

  factory XiphLink.forTarget(BuildInput input) {
    final code = input.config.code;
    final os = code.targetOS;
    final packageRoot = input.packageRoot;
    final packageName = input.packageName;

    switch (os) {
      case OS.macOS:
        const dir = 'macos/libs';
        const libs = ['fr_ogg', 'fr_opus', 'fr_speexdsp'];
        return XiphLink._(
          libraries: libs,
          libraryDirectories: [packageRoot.resolve(dir).toFilePath()],
          includeDirs: const ['macos/include'],
          bundledAssets: const [],
          dependencies: [
            for (final lib in libs) packageRoot.resolve('$dir/lib$lib.a'),
          ],
        );

      case OS.iOS:
        final slice = switch (code.iOS.targetSdk) {
          IOSSdk.iPhoneSimulator => 'ios-arm64_x86_64-simulator',
          _ => 'ios-arm64',
        };
        const libs = ['ogg', 'opus', 'speexdsp'];
        return XiphLink._(
          libraries: libs,
          libraryDirectories: [
            for (final lib in libs)
              packageRoot
                  .resolve('ios/Frameworks/$lib.xcframework/$slice')
                  .toFilePath(),
          ],
          includeDirs: const ['ios/include'],
          bundledAssets: const [],
          dependencies: [
            for (final lib in libs)
              packageRoot.resolve(
                'ios/Frameworks/$lib.xcframework/$slice/lib$lib.a',
              ),
          ],
        );

      case OS.android:
        final abi = _androidAbi[code.targetArchitecture];
        if (abi == null) {
          throw UnsupportedError(
            'Unsupported Android architecture: ${code.targetArchitecture}',
          );
        }
        final dir = 'android/libs/$abi';
        const libs = ['fr_ogg', 'fr_opus', 'fr_speexdsp'];
        return XiphLink._(
          libraries: libs,
          libraryDirectories: [packageRoot.resolve(dir).toFilePath()],
          includeDirs: const ['android/include'],
          bundledAssets: [
            for (final lib in libs)
              CodeAsset(
                package: packageName,
                name: 'xiph/$abi/lib$lib.so',
                linkMode: DynamicLoadingBundled(),
                file: packageRoot.resolve('$dir/lib$lib.so'),
              ),
          ],
          dependencies: [
            for (final lib in libs) packageRoot.resolve('$dir/lib$lib.so'),
          ],
        );

      case OS.windows:
        const dir = 'windows/libs';
        const libs = ['fr_ogg', 'fr_opus', 'fr_speexdsp'];
        return XiphLink._(
          libraries: libs,
          libraryDirectories: [packageRoot.resolve(dir).toFilePath()],
          includeDirs: const ['windows/include'],
          bundledAssets: [
            for (final lib in libs)
              CodeAsset(
                package: packageName,
                name: 'xiph/$lib.dll',
                linkMode: DynamicLoadingBundled(),
                file: packageRoot.resolve('$dir/$lib.dll'),
              ),
          ],
          dependencies: [
            for (final lib in libs) ...[
              packageRoot.resolve('$dir/$lib.lib'),
              packageRoot.resolve('$dir/$lib.dll'),
            ],
          ],
        );

      case OS.linux:
        const dir = 'linux/libs';
        const libs = ['ogg', 'opus', 'speexdsp'];
        return XiphLink._(
          libraries: libs,
          libraryDirectories: [packageRoot.resolve(dir).toFilePath()],
          includeDirs: const ['linux/include'],
          bundledAssets: const [],
          dependencies: [
            for (final lib in libs) packageRoot.resolve('$dir/lib$lib.so'),
          ],
        );

      default:
        throw UnsupportedError('Unsupported target OS: $os');
    }
  }

  /// Library names passed to the linker (`-l<name>`).
  final List<String> libraries;

  /// Directories searched for [libraries]. Absolute paths.
  final List<String> libraryDirectories;

  /// Xiph header directories, relative to the package root.
  final List<String> includeDirs;

  /// Extra code assets to bundle (prebuilt shared libraries).
  final List<CodeAsset> bundledAssets;

  /// Prebuilt files consumed by the build, for cache invalidation.
  final List<Uri> dependencies;
}
