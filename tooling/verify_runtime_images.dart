import 'dart:io';

void main() {
  final dir = Directory('assets/explore_images');
  final manifest = File('lib/features/explore/data/datasources/local_image_manifest.dart');

  if (!dir.existsSync()) {
    stderr.writeln('IMAGE AUDIT FAIL: assets/explore_images does not exist');
    exitCode = 1;
    return;
  }
  if (!manifest.existsSync()) {
    stderr.writeln('IMAGE AUDIT FAIL: local_image_manifest.dart does not exist');
    exitCode = 1;
    return;
  }

  final physical = dir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'\.(jpg|jpeg|png|webp)$', caseSensitive: false)
          .hasMatch(f.path))
      .toList();

  final text = manifest.readAsStringSync();
  final manifestPaths = RegExp(
    r"'([0-9a-f]{16})'\s*:\s*'([^']+)'",
  ).allMatches(text).map((m) => m.group(2)!).toList();

  final missing = <String>[];
  for (final path in manifestPaths) {
    if (!File(path).existsSync()) missing.add(path);
  }

  stdout.writeln('Physical image files: ${physical.length}');
  stdout.writeln('Manifest entries: ${manifestPaths.length}');
  stdout.writeln('Missing manifest files: ${missing.length}');

  if (missing.isNotEmpty) {
    for (final path in missing.take(20)) {
      stdout.writeln('MISSING: $path');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('IMAGE AUDIT PASS');
}
