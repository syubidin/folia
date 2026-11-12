import 'package:folia/core/error/result.dart';
import 'package:folia/features/scan/domain/identification.dart';

abstract interface class PlantClassifier {
  Future<void> warmUp();
  Future<Result<IdentificationOutcome>> classify(String imagePath);
}
