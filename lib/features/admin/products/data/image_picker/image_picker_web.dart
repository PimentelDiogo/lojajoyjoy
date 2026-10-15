import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:web/web.dart' as web;

ProductImagePicker createProductImagePicker() => BrowserProductImagePicker();

/// Seletor de fotos do navegador (`<input type=file>`) + compressão no
/// próprio navegador via canvas — sem pacote extra e sem enviar o original.
///
/// Foto de celular (12 MP, ~4 MB) vira ~150–300 KB: lado maior 1600 px,
/// WebP 82% (Safari não gera WebP → JPEG 85%).
class BrowserProductImagePicker implements ProductImagePicker {
  static const maxSide = 1600;
  static const accept = 'image/jpeg,image/png,image/webp,image/heic,image/*';

  @override
  Future<({List<PickedImage> images, int skipped})> pick({
    required int max,
  }) async {
    final files = await _chooseFiles();
    final images = <PickedImage>[];
    var skipped = 0;
    for (final file in files.take(max)) {
      final image = await _compress(file);
      if (image == null) {
        skipped++;
      } else {
        images.add(image);
      }
    }
    return (images: images, skipped: skipped);
  }

  Future<List<web.File>> _chooseFiles() {
    final completer = Completer<List<web.File>>();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = accept
      ..multiple = true;
    input
      ..addEventListener(
        'change',
        ((web.Event _) {
          final list = input.files;
          final files = <web.File>[];
          for (var i = 0; i < (list?.length ?? 0); i++) {
            final file = list!.item(i);
            if (file != null) files.add(file);
          }
          if (!completer.isCompleted) completer.complete(files);
        }).toJS,
      )
      ..addEventListener(
        'cancel',
        ((web.Event _) {
          if (!completer.isCompleted) completer.complete(const []);
        }).toJS,
      )
      ..click();
    return completer.future;
  }

  Future<PickedImage?> _compress(web.File file) async {
    try {
      // createImageBitmap(File) trava no WKWebView (Safari iOS, Instagram,
      // WhatsApp). FileReader → HTMLImageElement funciona em todos os browsers.
      final dataUrl = await _readAsDataUrl(file);
      final loaded = Completer<void>();
      final img = web.HTMLImageElement()
        ..onload = ((web.Event _) => loaded.complete()).toJS
        ..onerror = ((web.Event _) => loaded.completeError('load error')).toJS
        ..src = dataUrl;
      await loaded.future;

      final size = fitWithin(img.naturalWidth, img.naturalHeight, maxSide);
      final canvas = web.HTMLCanvasElement()
        ..width = size.width
        ..height = size.height;
      (canvas.getContext('2d')! as web.CanvasRenderingContext2D)
        // Fundo branco: PNG transparente não fica preto no JPEG.
        ..fillStyle = '#FFFFFF'.toJS
        ..fillRect(0, 0, size.width, size.height)
        ..drawImage(img, 0, 0, size.width, size.height);

      var blob = await _toBlob(canvas, 'image/webp', 0.82);
      if (blob == null || blob.type != 'image/webp') {
        blob = await _toBlob(canvas, 'image/jpeg', 0.85);
      }
      if (blob == null) return null;
      final buffer = await blob.arrayBuffer().toDart;
      return PickedImage(
        bytes: Uint8List.view(buffer.toDart),
        contentType: blob.type,
      );
    } on Object {
      return null; // formato que o navegador não abre (ex.: HEIC no Chrome)
    }
  }

  Future<String> _readAsDataUrl(web.File file) {
    final completer = Completer<String>();
    final reader = web.FileReader();
    reader
      ..addEventListener(
        'load',
        ((web.Event _) {
          completer.complete((reader.result! as JSString).toDart);
        }).toJS,
      )
      ..addEventListener(
        'error',
        ((web.Event _) => completer.completeError('FileReader error')).toJS,
      )
      ..readAsDataURL(file);
    return completer.future;
  }

  Future<web.Blob?> _toBlob(
    web.HTMLCanvasElement canvas,
    String type,
    double quality,
  ) {
    final completer = Completer<web.Blob?>();
    canvas.toBlob(
      // `toJS` exige tipos JS na assinatura (não aceita o FutureOr do complete).
      // ignore: unnecessary_lambdas
      ((web.Blob? blob) => completer.complete(blob)).toJS,
      type,
      quality.toJS,
    );
    return completer.future;
  }
}
