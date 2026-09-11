import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TravelCardShareService {
  const TravelCardShareService();

  Future<void> shareBoundary({
    required RenderRepaintBoundary boundary,
    required String fileName,
    required String shareText,
  }) async {
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw StateError('Could not render travel card.');
    }

    final temp = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final file = File('${temp.path}/$safeName.png');

    await file.writeAsBytes(
      byteData.buffer.asUint8List(),
      flush: true,
    );

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: shareText,
    );
  }
}
