import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/features/scan/data/inference_worker.dart';
import 'package:folia/features/scan/domain/identification.dart';
import 'package:folia/features/scan/domain/plant_classifier.dart';

final class _Engine {
  const _Engine(this.worker, this.labels, this.policy);
  final InferenceWorker worker;
  final List<String> labels;
  final IdentificationPolicy policy;
}

final class LiteRtPlantClassifier implements PlantClassifier {
  LiteRtPlantClassifier({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static const _modelAsset = 'assets/models/plants.tflite';
  static const _labelsAsset = 'assets/models/labels.txt';
  static const _metaAsset = 'assets/models/model_meta.json';

  final AssetBundle _bundle;
  Future<_Engine>? _engine;

  Future<_Engine> _ready() => _engine ??= _initEngine();

  Future<_Engine> _initEngine() async {
    try {
      return await _load();
    } on Object {
      _engine = null;
      rethrow;
    }
  }

  Future<_Engine> _load() async {
    final labels = (await _bundle.loadString(_labelsAsset))
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
    final rawMeta = await _bundle.loadString(_metaAsset);
    final meta = jsonDecode(rawMeta) as Map<String, dynamic>;
    final data = await _bundle.load(_modelAsset);
    final worker = await InferenceWorker.spawn(
      model: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      inputSize: (meta['inputSize'] as num?)?.toInt() ?? 224,
    );
    return _Engine(worker, labels, IdentificationPolicy.fromJson(meta));
  }

  @override
  Future<void> warmUp() async {
    try {
      await _ready();
    } on Object catch (e, s) {
      developer.log('warm-up failed', error: e, stackTrace: s);
    }
  }

  @override
  Future<Result<IdentificationOutcome>> classify(String imagePath) async {
    try {
      final watch = Stopwatch()..start();
      final engine = await _ready();
      final scores = await engine.worker.run(imagePath);
      if (scores.length != engine.labels.length) {
        throw const InferenceException(
          'labels and model output do not match',
        );
      }
      developer.log('identify took ${watch.elapsedMilliseconds} ms');
      return Ok(
        interpretScores(
          scores: scores,
          labels: engine.labels,
          policy: engine.policy,
        ),
      );
    } on Object catch (e, s) {
      developer.log('classification failed', error: e, stackTrace: s);
      return const Err(ModelFailure());
    }
  }

  void dispose() {
    final pending = _engine;
    _engine = null;
    if (pending != null) {
      unawaited(
        pending.then((e) => e.worker.close(), onError: (Object _) {}),
      );
    }
  }
}
