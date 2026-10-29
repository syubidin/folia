import 'package:folia/core/error/result.dart';
import 'package:folia/features/plants/domain/plant.dart';

abstract interface class PlantRepository {
  Stream<List<Plant>> watchAll(String userId, {String query = ''});
  Future<Result<Plant>> getById(String userId, String id);
  Future<Result<Plant>> create(String userId, PlantInput input);
  Future<Result<Plant>> update(String userId, String id, PlantInput input);
  Future<Result<void>> delete(String userId, String id);
  Future<Result<void>> restore(String userId, String id);
}
