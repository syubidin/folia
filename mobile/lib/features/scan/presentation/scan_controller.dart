import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/features/plants/data/plant_providers.dart';
import 'package:folia/features/scan/data/scan_providers.dart';
import 'package:folia/features/scan/domain/identification.dart';
import 'package:image_picker/image_picker.dart';

sealed class ScanState {
  const ScanState();
}

final class ScanIdle extends ScanState {
  const ScanIdle();
}

final class ScanAnalyzing extends ScanState {
  const ScanAnalyzing(this.imagePath);
  final String imagePath;
}

final class ScanDone extends ScanState {
  const ScanDone({required this.imagePath, required this.outcome});
  final String imagePath;
  final IdentificationOutcome outcome;
}

final class ScanFailed extends ScanState {
  const ScanFailed({required this.failure, this.imagePath});
  final Failure failure;
  final String? imagePath;
}

final scanControllerProvider =
    NotifierProvider<ScanController, ScanState>(ScanController.new);

class ScanController extends Notifier<ScanState> {
  String? _tempPath;

  @override
  ScanState build() => const ScanIdle();

  void reset() {
    _deleteTemp();
    state = const ScanIdle();
  }

  Future<void> start(ImageSource source) async {
    if (state is ScanAnalyzing) return;

    final String? path;
    try {
      path = await ref.read(plantImageStoreProvider).pickTemp(source);
    } on Object {
      state = const ScanFailed(failure: StorageFailure());
      return;
    }
    if (path == null) return;

    _deleteTemp();
    _tempPath = path;
    state = ScanAnalyzing(path);

    final result = await ref.read(plantClassifierProvider).classify(path);
    state = switch (result) {
      Ok(:final value) => ScanDone(imagePath: path, outcome: value),
      Err(:final failure) => ScanFailed(failure: failure, imagePath: path),
    };
  }

  void _deleteTemp() {
    final path = _tempPath;
    _tempPath = null;
    if (path != null) {
      unawaited(File(path).delete().then<void>((_) {}, onError: (Object _) {}));
    }
  }
}
