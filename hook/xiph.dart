// Prebuilt Xiph library wiring for the flutter_recorder build hook.
//
// The Xiph libraries (Opus, Ogg) are precompiled using the scripts in `xiph/`:
// - iOS/macOS: static archives are linked into the plugin library.
// - Android/Windows: shared libraries/DLLs are linked and bundled as code assets.
// - Linux: the shared libraries in linux/libs are linked.

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

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
        const libs = ['fr_ogg', 'fr_opus'];
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
        const libs = ['ogg', 'opus'];
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
        const libs = ['fr_ogg', 'fr_opus'];
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
        const libs = ['ogg', 'opus'];
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
        const libs = ['ogg', 'opus'];
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
