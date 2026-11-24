import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/share_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/travel_share_format.dart';

class TravelCardShareService {
  const TravelCardShareService();

  Future<void> shareBoundary({
    required RenderRepaintBoundary boundary,
    required String fileName,
    required String shareText,
    TravelShareFormat format = TravelShareFormat.post,
  }) async {
    // iPad needs an anchor rectangle for the share popover; read it before any
    // asynchronous work while the render object is still attached.
    final origin = _shareOrigin(boundary);

    final bytes = await _renderPng(boundary, format);

    final temp = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final suffix = format == TravelShareFormat.story ? '_story' : '';
    final file = File('${temp.path}/$safeName$suffix.png');

    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: shareText,
      sharePositionOrigin: origin,
    );
  }

  Rect? _shareOrigin(RenderRepaintBoundary boundary) {
    try {
      if (!boundary.attached || !boundary.hasSize) return null;
      final rect = boundary.localToGlobal(Offset.zero) & boundary.size;
      if (rect.isEmpty || !rect.isFinite) return null;
      return rect;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _renderPng(
    RenderRepaintBoundary boundary,
    TravelShareFormat format,
  ) async {
    final card = await boundary.toImage(pixelRatio: 3);
    try {
      if (format == TravelShareFormat.post) {
        return await _encode(card);
      }
      return await _composeStory(card);
    } finally {
      card.dispose();
    }
  }

  Future<Uint8List> _encode(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Could not render travel card.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Places the card on a branded 1080x1920 canvas (Stories ratio).
  Future<Uint8List> _composeStory(ui.Image card) async {
    const canvasWidth = 1080.0;
    const canvasHeight = 1920.0;
    const margin = 48.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      const ui.Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
    );

    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          const ui.Offset(canvasWidth, canvasHeight),
          const [AppColors.darkNavy, AppColors.primary],
        ),
    );

    const targetWidth = canvasWidth - margin * 2;
    final scale = targetWidth / card.width;
    final targetHeight = card.height * scale;
    final top = (canvasHeight - targetHeight) / 2 - 56;
    final destination = ui.Rect.fromLTWH(margin, top, targetWidth, targetHeight);

    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(destination, const ui.Radius.circular(44)),
    );
    canvas.drawImageRect(
      card,
      ui.Rect.fromLTWH(0, 0, card.width.toDouble(), card.height.toDouble()),
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    canvas.restore();

    var footerTop = destination.bottom + 64;
    _paintCentered(
      canvas,
      'EDIBLE',
      top: footerTop,
      fontSize: 54,
      weight: FontWeight.w900,
      letterSpacing: 8,
      width: canvasWidth,
    );

    final link = ShareConfig.appShareUrl;
    if (link != null) {
      footerTop += 78;
      _paintCentered(
        canvas,
        Uri.parse(link).host,
        top: footerTop,
        fontSize: 36,
        weight: FontWeight.w600,
        width: canvasWidth,
      );
    }

    final picture = recorder.endRecording();
    final composed = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    try {
      return await _encode(composed);
    } finally {
      composed.dispose();
      picture.dispose();
    }
  }

  void _paintCentered(
    ui.Canvas canvas,
    String text, {
    required double top,
    required double fontSize,
    required FontWeight weight,
    required double width,
    double letterSpacing = 0,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: fontSize,
        fontWeight: weight,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      )
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(paragraph, ui.Offset(0, top));
  }
}
