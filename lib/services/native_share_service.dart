import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class NativeShareService {
  static const MethodChannel _channel = MethodChannel('app.zaatra/share');

  /// Capture any widget wrapped in RepaintBoundary with [key] and share it as PNG
  static Future<Map<String, dynamic>> captureAndShareWidget({
    required GlobalKey key,
    String? text,
    String? fallbackShareUrl,
  }) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        return {
          'success': false,
          'message': 'Unable to find card render boundary',
        };
      }

      // 1. Render widget to high-DPI image (pixelRatio: 3.0 for sharp text/icons)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return {
          'success': false,
          'message': 'Failed to encode PNG bytes',
        };
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. Save PNG to temporary cache directory
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/zaatra_trip_card_$timestamp.png');
        await file.writeAsBytes(pngBytes, flush: true);

        // 3. Dispatch to Android default sharesheet via MethodChannel
        if (Platform.isAndroid) {
          final res = await _channel.invokeMethod<bool>('shareImage', {
            'filePath': file.path,
            'text': text ?? 'Track my Zaatra ride live!',
          });
          return {
            'success': res == true,
            'filePath': file.path,
            'pngBytes': pngBytes,
          };
        }

        return {
          'success': true,
          'filePath': file.path,
          'pngBytes': pngBytes,
        };
      }

      // Web platform fallback
      return {
        'success': true,
        'isWeb': true,
        'pngBytes': pngBytes,
      };
    } catch (e) {
      debugPrint('NativeShareService error capturing/sharing: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
