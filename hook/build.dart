// Build hook for flutter_recorder.
//
// Compiles the recorder engine and the plugin sources in `src/` into
// `libflutter_recorder` for the target OS/architecture, linking the
// prebuilt Xiph libraries checked into this repo (see `xiph/`).
//
// Web is not covered by hooks; the emscripten build in `web/` is unchanged.
//
// Configuration (in the *root app* pubspec.yaml):
//
// hooks:
//   user_defines:
//     flutter_recorder:
//       linux_use_system_xiph: true   # link the distribution's Xiph libs
//       macos_use_system_xiph: true   # link Homebrew/MacPorts Xiph libs
//       windows_use_system_xiph: true # link vcpkg Xiph libs
//
// `<os>_use_system_libs` is accepted as an alias of `<os>_use_system_xiph`,
// and `use_system_xiph_libs` as a Linux-only alias, matching flutter_soloud.

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
      'NDEBUG': null,
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
      // if (os == OS.windows) ...['/Od', '/Zi', '/EHsc'] else ...['-O0', '-g'],
      // For production / default:
      if (os == OS.windows) ...['/Ox', '/EHsc'] else '-O3',
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
      if (os != OS.windows) '-Wno-vla',
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

    if (_useSystemXiph(input, os)) {
      return XiphLink.system(os, code.targetArchitecture);
    }

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
        // The prebuilts carry an `fr_` prefix in both file name and SONAME so
        // they cannot collide with other plugins bundling the Xiph libraries
        // (such as flutter_soloud): bundled code assets must have unique file
        // names across all packages of an app.
        const libs = ['fr_ogg', 'fr_opus', 'fr_speexdsp'];
        // Bundled by SONAME, which is what the plugin library asks for at
        // runtime.
        const runtimeLibs = [
          'libfr_ogg.so.0',
          'libfr_opus.so.0',
          'libfr_speexdsp.so',
        ];
        return XiphLink._(
          libraries: libs,
          libraryDirectories: [packageRoot.resolve(dir).toFilePath()],
          includeDirs: const ['linux/include'],
          bundledAssets: [
            for (final file in runtimeLibs)
              CodeAsset(
                package: packageName,
                name: 'xiph/$file',
                linkMode: DynamicLoadingBundled(),
                file: packageRoot.resolve('$dir/$file'),
              ),
          ],
          dependencies: [
            for (final lib in libs) packageRoot.resolve('$dir/lib$lib.so'),
            for (final file in runtimeLibs) packageRoot.resolve('$dir/$file'),
          ],
        );

      default:
        throw UnsupportedError('Unsupported target OS: $os');
    }
  }

  /// Links the build environment's own Ogg, Opus and SpeexDSP libraries on
  /// desktop targets, without bundling anything: the libraries must also be
  /// available wherever the application runs.
  ///
  /// They are located with `pkg-config` on Linux, `pkg-config` and then the
  /// Homebrew/MacPorts prefixes on macOS, and vcpkg on Windows.
  factory XiphLink.system(OS os, Architecture arch) {
    final directories = <String>{};
    final includes = <String>{};
    final dependencies = <Uri>[];

    for (final library in _systemLibs) {
      final header = _systemHeaders[library]!;
      final candidates = _systemCandidates(library, os, arch);
      _SystemLibrary? found;
      for (final candidate in candidates) {
        if (!File('${candidate.includeDir}/$header').existsSync()) continue;
        final file = _systemLibraryFile(candidate.libDir, library, os);
        if (file == null) continue;
        found = (candidate: candidate, file: file);
        break;
      }
      if (found == null) {
        final searched = candidates.isEmpty
            ? 'pkg-config is not installed or does not know "$library".'
            : [
                'Searched (include | lib):',
                for (final c in candidates) '  ${c.includeDir} | ${c.libDir}',
              ].join('\n');
        throw BuildError(
          message:
              '[flutter_recorder] Cannot find the system "$library" library '
              '(header `$header`) for ${os.name} ${arch.name}.\n'
              '${_systemInstallHint(os, arch)}\n'
              '$searched\n'
              'Remove the `${os.name}_use_system_xiph` user define to use '
              'the prebuilt libraries shipped with flutter_recorder instead.',
        );
      }

      final file = found.file;
      if (os == OS.macOS) _checkMacOSSlice(file, library, arch);

      directories.add(found.candidate.libDir);
      includes.add(found.candidate.includeDir);
      // Track the metadata, the linker file and the versioned file it points
      // to, so upgrading the system libraries invalidates the hook.
      final pcFile = found.candidate.pcFile;
      if (pcFile != null) dependencies.add(pcFile);
      dependencies.add(file.uri);
      try {
        final resolved = file.resolveSymbolicLinksSync();
        if (resolved != file.path) dependencies.add(File(resolved).uri);
      } on FileSystemException {
        // Keep the unresolved path only.
      }
    }

    return XiphLink._(
      libraries: _systemLibs,
      libraryDirectories: directories.toList(),
      includeDirs: includes.toList(),
      bundledAssets: const [],
      dependencies: dependencies,
    );
  }

  /// Library names passed to the linker (`-l<name>`).
  final List<String> libraries;

  /// Directories searched for [libraries]. Absolute paths.
  final List<String> libraryDirectories;

  /// Xiph header directories, relative to the package root or absolute for
  /// system libraries.
  final List<String> includeDirs;

  /// Extra code assets to bundle (prebuilt shared libraries).
  final List<CodeAsset> bundledAssets;

  /// Prebuilt files consumed by the build, for cache invalidation.
  final List<Uri> dependencies;
}

/// System library names, as known to pkg-config, the linker and vcpkg.
const _systemLibs = ['ogg', 'opus', 'speexdsp'];

/// A header of each system library, relative to its include directory, in the
/// form the sources include it.
const _systemHeaders = {
  'ogg': 'ogg/ogg.h',
  'opus': 'opus/opus.h',
  'speexdsp': 'speex/speex_echo.h',
};

/// A place where a system library may be installed.
typedef _SystemCandidate = ({String includeDir, String libDir, Uri? pcFile});

typedef _SystemLibrary = ({_SystemCandidate candidate, File file});

/// Whether the app asked for the system Xiph libraries on [os].
///
/// Only desktop targets support it. Throws a [BuildError] when a user define
/// is not a boolean, instead of silently ignoring it.
bool _useSystemXiph(BuildInput input, OS os) {
  if (os != OS.linux && os != OS.macOS && os != OS.windows) return false;
  final keys = [
    '${os.name}_use_system_xiph',
    '${os.name}_use_system_libs',
    if (os == OS.linux) 'use_system_xiph_libs',
  ];
  bool? result;
  for (final key in keys) {
    // Every key is parsed, so a typo in a lower-priority alias is reported.
    final value = _boolDefine(input, key);
    result ??= value;
  }
  return result ?? false;
}

bool? _boolDefine(BuildInput input, String key) {
  final value = input.userDefines[key];
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true' || '1':
        return true;
      case 'false' || '0':
        return false;
    }
  }
  throw BuildError(
    message:
        '[flutter_recorder] Invalid value `$value` for '
        '`hooks.user_defines.flutter_recorder.$key` in pubspec.yaml: '
        'expected `true` or `false`.',
  );
}

/// Where [library] may be installed on [os], most specific first.
List<_SystemCandidate> _systemCandidates(
  String library,
  OS os,
  Architecture arch,
) {
  final candidates = <_SystemCandidate>[];

  if (os != OS.windows) {
    final libDir = _pkgConfigVariable(library, 'libdir');
    final includeDir = _pkgConfigVariable(library, 'includedir');
    final pcDir = _pkgConfigVariable(library, 'pcfiledir');
    if (libDir != null && includeDir != null) {
      candidates.add((
        includeDir: includeDir,
        libDir: libDir,
        pcFile: pcDir == null ? null : File('$pcDir/$library.pc').uri,
      ));
    }
  }

  if (os == OS.macOS) {
    // Homebrew (Apple Silicon, Intel) and MacPorts.
    for (final prefix in const ['/opt/homebrew', '/usr/local', '/opt/local']) {
      candidates.add((
        includeDir: '$prefix/include',
        libDir: '$prefix/lib',
        pcFile: null,
      ));
    }
  } else if (os == OS.windows) {
    final environment = Platform.environment;
    final triplet =
        environment['VCPKG_DEFAULT_TRIPLET'] ??
        switch (arch) {
          Architecture.arm64 => 'arm64-windows',
          Architecture.ia32 => 'x86-windows',
          _ => 'x64-windows',
        };
    final roots = <String>{
      if (environment['VCPKG_ROOT'] case final root? when root.isNotEmpty) root,
      r'C:\vcpkg',
      r'C:\tools\vcpkg',
    };
    for (final root in roots) {
      candidates.add((
        includeDir: '$root\\installed\\$triplet\\include',
        libDir: '$root\\installed\\$triplet\\lib',
        pcFile: null,
      ));
    }
  }

  return candidates;
}

/// The value of a pkg-config variable of [library], or null when pkg-config
/// is not installed or does not know the library.
String? _pkgConfigVariable(String library, String name) {
  try {
    final result = Process.runSync('pkg-config', ['--variable=$name', library]);
    final value = (result.stdout as String).trim();
    return result.exitCode == 0 && value.isNotEmpty ? value : null;
  } on ProcessException {
    return null;
  }
}

/// The file the linker picks for [library] in [directory], if any.
File? _systemLibraryFile(String directory, String library, OS os) {
  final names = switch (os) {
    OS.windows => ['$library.lib'],
    OS.macOS => ['lib$library.dylib', 'lib$library.a'],
    _ => ['lib$library.so', 'lib$library.a'],
  };
  final separator = os == OS.windows ? r'\' : '/';
  for (final name in names) {
    final file = File('$directory$separator$name');
    if (file.existsSync()) return file;
  }
  return null;
}

/// Fails early, with an actionable message, when a macOS system library has
/// no slice for [arch]: Homebrew libraries are built for the host only, while
/// Flutter release builds are universal.
void _checkMacOSSlice(File file, String library, Architecture arch) {
  final wanted = arch == Architecture.x64 ? 'x86_64' : arch.name;
  final List<String> slices;
  try {
    final result = Process.runSync('lipo', ['-archs', file.path]);
    if (result.exitCode != 0) return;
    slices = (result.stdout as String).trim().split(RegExp(r'\s+'));
  } on ProcessException {
    return;
  }
  if (slices.contains(wanted)) return;
  throw BuildError(
    message:
        '[flutter_recorder] The system "$library" library at ${file.path} '
        'has no $wanted slice (it contains: ${slices.join(', ')}).\n'
        'Flutter builds macOS release apps for both arm64 and x86_64, while '
        'Homebrew installs libraries for the host architecture only. Provide '
        'universal libraries, build only for the host architecture, or '
        'remove the `macos_use_system_xiph` user define to use the '
        'universal prebuilt libraries shipped with flutter_recorder.',
  );
}

String _systemInstallHint(OS os, Architecture arch) => switch (os) {
  OS.linux =>
    'Install `pkg-config` and the Ogg, Opus and SpeexDSP development '
        'packages in the build environment, for example '
        '`sudo apt install pkg-config libogg-dev libopus-dev libspeexdsp-dev`.',
  OS.macOS => 'Install them with `brew install libogg opus speexdsp`.',
  _ =>
    'Install them with `vcpkg install libogg opus speexdsp` for the '
        '${arch == Architecture.arm64 ? 'arm64' : 'x64'}-windows triplet and '
        'set the `VCPKG_ROOT` environment variable to the vcpkg directory.',
};
