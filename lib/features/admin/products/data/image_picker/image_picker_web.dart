import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:web/web.dart' as web;

ProductImagePicker createProductImagePicker() => BrowserProductImagePicker();

@JS('Worker')
extension type _JSWorker._(JSObject _) implements JSObject {
  external factory _JSWorker(String scriptUrl);
  external void postMessage(JSAny? message);
  external JSFunction? get onmessage;
  external set onmessage(JSFunction? value);
  external JSFunction? get onerror;
  external set onerror(JSFunction? value);
  external void terminate();
}

@JS('MessageEvent')
extension type _JSMessageEvent._(JSObject _) implements JSObject {
  external JSObject? get data;
}

/// Seletor de fotos do navegador (`<input type=file>`) + compressão numa
/// Web Worker separada (ver `web/photo_worker.js`).
///
/// A compressão rodava antes na thread principal via `<canvas>`, mas isso
/// disputava recursos com o CanvasKit do Flutter Web e travava o navegador
/// de vez em alguns iPhones (confirmado: a mesma foto processa instantâneo
/// fora do Flutter). Uma Web Worker roda numa thread de verdade, isolada —
/// mesmo que a thread principal fique ocupada, a worker continua.
///
/// Foto de celular (12 MP, ~4 MB) vira ~150–300 KB: lado maior 1600 px,
/// WebP 82% (Safari não gera WebP → JPEG 85%). Se a worker falhar ou não
/// responder — ex.: iPadOS < 16.4 não tem `OffscreenCanvas`, confirmado via
/// Web Inspector (`ReferenceError: Can't find variable: OffscreenCanvas`) —
/// sobe a foto original sem comprimir (se já vier num formato aceito pelo
/// Storage: jpeg/png/webp). A worker responde rápido nesse caso (~500 ms),
/// então o timeout é curto: não faz sentido fazer a Ana esperar 20 s por
/// algo que sabemos que já falhou.
class BrowserProductImagePicker implements ProductImagePicker {
  static const maxSide = 1600;
  static const accept = 'image/jpeg,image/png,image/webp,image/heic,image/*';
  static const _timeout = Duration(seconds: 8);
  static const _allowedOriginal = {'image/jpeg', 'image/png', 'image/webp'};

  @override
  Future<({List<PickedImage> images, int skipped})> pick({
    required int max,
  }) async {
    final files = await _chooseFiles();
    final images = <PickedImage>[];
    var skipped = 0;
    for (final file in files.take(max)) {
      final image = await _compress(file) ?? await _original(file);
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

  /// iPadOS < 16.4 (e navegadores antigos) não têm `OffscreenCanvas`: nem
  /// vale a pena criar a worker e esperar a mensagem ir e voltar — confirmado
  /// via Web Inspector num iPad real (iPadOS 15.8.3).
  bool get _supportsWorkerCompression =>
      globalContext.hasProperty('OffscreenCanvas'.toJS).toDart;

  Future<PickedImage?> _compress(web.File file) async {
    if (!_supportsWorkerCompression) return null;
    _JSWorker? worker;
    try {
      worker = _JSWorker('photo_worker.js');
      final completer = Completer<PickedImage?>();
      worker
        ..onmessage = ((web.Event e) {
          if (completer.isCompleted) return;
          completer.complete(_parseResult((e as _JSMessageEvent).data));
        }).toJS
        ..onerror = ((web.Event _) {
          if (!completer.isCompleted) completer.complete(null);
        }).toJS;

      final message = JSObject()
        ..setProperty('file'.toJS, file)
        ..setProperty('maxSide'.toJS, maxSide.toJS);
      worker.postMessage(message);

      return await completer.future.timeout(_timeout);
    } on Object {
      return null;
    } finally {
      worker?.terminate();
    }
  }

  PickedImage? _parseResult(JSObject? data) {
    if (data == null) return null;
    final ok = data.getProperty('ok'.toJS);
    if (!ok.isA<JSBoolean>() || !(ok! as JSBoolean).toDart) return null;
    final buffer = data.getProperty('buffer'.toJS);
    final contentType = data.getProperty('contentType'.toJS);
    if (!buffer.isA<JSArrayBuffer>() || !contentType.isA<JSString>()) {
      return null;
    }
    return PickedImage(
      bytes: (buffer! as JSArrayBuffer).toDart.asUint8List(),
      contentType: (contentType! as JSString).toDart,
    );
  }

  Future<PickedImage?> _original(web.File file) async {
    if (!_allowedOriginal.contains(file.type)) return null;
    try {
      final buffer = await file.arrayBuffer().toDart.timeout(_timeout);
      return PickedImage(
        bytes: Uint8List.view(buffer.toDart),
        contentType: file.type,
      );
    } on Object {
      return null;
    }
  }
}
