// Source collection for the flutter_recorder build hook.

import 'dart:io';

import 'package:code_assets/code_assets.dart';

/// Collects the plugin sources (paths relative to [packageRoot]) for
/// [targetOS].
List<String> collectSources(Uri packageRoot, OS targetOS) {
  final rootPath = packageRoot.toFilePath();
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
      final path = entity.path;
      if (!extensions.any(path.endsWith)) continue;
      if (exclude?.call(path) ?? false) continue;
      sources.add(path.substring(rootPath.length));
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
