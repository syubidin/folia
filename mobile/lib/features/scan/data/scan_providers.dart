import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/features/scan/data/litert_plant_classifier.dart';
import 'package:folia/features/scan/domain/plant_catalog.dart';
import 'package:folia/features/scan/domain/plant_classifier.dart';

final plantClassifierProvider = Provider.autoDispose<PlantClassifier>((ref) {
  final link = ref.keepAlive();
  Timer? idle;
  ref
    ..onCancel(() => idle = Timer(const Duration(minutes: 2), link.close))
    ..onResume(() => idle?.cancel());

  final classifier = LiteRtPlantClassifier();
  ref.onDispose(() {
    idle?.cancel();
    classifier.dispose();
  });
  return classifier;
});

final plantCatalogProvider = FutureProvider<PlantCatalog>((ref) async {
  return PlantCatalog.fromJson(
    await rootBundle.loadString('assets/data/plants_catalog.json'),
  );
});
