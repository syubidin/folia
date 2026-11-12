import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

final class InferenceException implements Exception {
  const InferenceException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class _Init {
  const _Init(this.reply, this.model, this.inputSize, this.threads);
  final SendPort reply;
  final TransferableTypedData model;
  final int inputSize;
  final int threads;
}

final class _Request {
  const _Request(this.path, this.reply);
  final String path;
  final SendPort reply;
}

final class InferenceWorker {
  InferenceWorker._(this._port);

  final SendPort _port;
  bool _closed = false;

  static Future<InferenceWorker> spawn({
    required Uint8List model,
    required int inputSize,
    int threads = 2,
  }) async {
    final handshake = ReceivePort();
    await Isolate.spawn(
      _entry,
      _Init(
        handshake.sendPort,
        TransferableTypedData.fromList([model]),
        inputSize,
        threads,
      ),
    );
    final port = await handshake.first as SendPort;
    handshake.close();
    return InferenceWorker._(port);
  }

  Future<Float32List> run(String imagePath) async {
    if (_closed) throw const InferenceException('worker closed');
    final reply = ReceivePort();
    _port.send(_Request(imagePath, reply.sendPort));
    final Object? message = await reply.first;
    reply.close();
    return switch (message) {
      final TransferableTypedData data => data.materialize().asFloat32List(),
      final String error => throw InferenceException(error),
      _ => throw const InferenceException('unexpected worker reply'),
    };
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _port.send(null);
  }

  static Future<void> _entry(_Init init) async {
    final inbox = ReceivePort();
    Interpreter? interpreter;
    String? initError;
    try {
      interpreter = Interpreter.fromBuffer(
        init.model.materialize().asUint8List(),
        options: InterpreterOptions()..threads = init.threads,
      );
      final shape = interpreter.getInputTensor(0).shape;
      if (shape.length != 4 ||
          shape[1] != init.inputSize ||
          shape[2] != init.inputSize ||
          shape[3] != 3) {
        throw StateError('unexpected input shape $shape');
      }
    } on Object catch (e) {
      initError = '$e';
    }
    init.reply.send(inbox.sendPort);

    await for (final message in inbox) {
      if (message == null) break;
      if (message is! _Request) continue;
      if (interpreter == null) {
        message.reply.send('model init failed: $initError');
        continue;
      }
      try {
        final input = _preprocess(message.path, init.inputSize);
        final classes = interpreter.getOutputTensor(0).shape.last;
        final output = Float32List(classes);
        interpreter.run(input.buffer, output.buffer);
        message.reply.send(TransferableTypedData.fromList([output]));
      } on Object catch (e) {
        message.reply.send('inference failed: $e');
      }
    }
    interpreter?.close();
    inbox.close();
  }

  static Float32List _preprocess(String path, int size) {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) throw const FormatException('cannot decode image');
    final square = img.copyResizeCropSquare(
      img.bakeOrientation(decoded),
      size: size,
      interpolation: img.Interpolation.linear,
    );
    final out = Float32List(size * size * 3);
    var i = 0;
    for (final px in square) {
      out[i++] = px.r.toDouble();
      out[i++] = px.g.toDouble();
      out[i++] = px.b.toDouble();
    }
    return out;
  }
}
