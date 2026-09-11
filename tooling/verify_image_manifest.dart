import 'dart:io';

void main() {
  final manifest = File('lib/features/explore/data/datasources/generated_image_manifest.dart');
  final localManifest = File('lib/features/explore/data/datasources/local_image_manifest.dart');
  final audit = File('tooling/image_manifest_missing.txt');
  final assetDir = Directory('assets/explore_images');

  if (!manifest.existsSync() || !localManifest.existsSync() || !audit.existsSync()) {
    stderr.writeln('RELEASE BLOCKED: run the image builder first.');
    exitCode = 2;
    return;
  }

  final localText = localManifest.readAsStringSync();
  final entries = RegExp(r"^  '[0-9a-f]{16}': '([^']+)'", multiLine: true)
      .allMatches(localText)
      .map((m) => m.group(1)!)
      .toList();

  var missingFiles = 0;
  var invalidFiles = 0;
  for (final relative in entries) {
    final file = File(relative);
    if (!file.existsSync()) {
      missingFiles++;
    } else if (file.lengthSync() < 1024) {
      invalidFiles++;
    }
  }

  final report = audit.readAsStringSync();
  final unresolved = int.tryParse(
        RegExp(r'^Missing/unresolved: (\d+)', multiLine: true)
                .firstMatch(report)?.group(1) ?? '') ?? -1;

  final assetCount = assetDir.existsSync()
      ? assetDir.listSync().whereType<File>().where((f) {
          final n = f.path.toLowerCase();
          return n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png') || n.endsWith('.webp');
        }).length
      : 0;

  stdout.writeln('Local manifest entries: ${entries.length}');
  stdout.writeln('Physical image files: $assetCount');
  stdout.writeln('Missing physical files: $missingFiles');
  stdout.writeln('Invalid (<1KB) files: $invalidFiles');
  stdout.writeln('Unresolved catalog records: $unresolved');

  if (unresolved != 0 || missingFiles != 0 || invalidFiles != 0 || entries.isEmpty) {
    stderr.writeln('RELEASE BLOCKED: local exact image set is incomplete.');
    exitCode = 1;
    return;
  }

  stdout.writeln('IMAGE PIPELINE VERIFIED: local exact assets are physically present.');
}
