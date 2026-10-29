import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:folia/core/database/app_database.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/features/plants/data/plant_local_data_source.dart';
import 'package:folia/features/plants/domain/plant.dart';
import 'package:folia/features/plants/domain/plant_repository.dart';
import 'package:uuid/uuid.dart';

class _Invalid implements Exception;

class _Missing implements Exception;

final class PlantRepositoryImpl implements PlantRepository {
  PlantRepositoryImpl(this._local);

  final PlantLocalDataSource _local;
  static const _uuid = Uuid();

  @override
  Stream<List<Plant>> watchAll(String userId, {String query = ''}) => _local
      .watch(userId, query)
      .map((rows) => rows.map(_toEntity).toList(growable: false));

  @override
  Future<Result<Plant>> getById(String userId, String id) => _guard(() async {
        final row = await _local.find(userId, id);
        if (row == null) throw _Missing();
        return _toEntity(row);
      });

  @override
  Future<Result<Plant>> create(String userId, PlantInput input) =>
      _guard(() async {
        _validate(input);
        final now = DateTime.now().toUtc();
        final id = _uuid.v4();
        await _local.insert(
          PlantsCompanion.insert(
            id: id,
            userId: userId,
            name: input.name.trim(),
            species: Value(_blank(input.species)),
            notes: Value(_blank(input.notes)),
            imageName: Value(input.imageName),
            createdAt: now,
            updatedAt: now,
          ),
        );
        return _toEntity((await _local.find(userId, id))!);
      });

  @override
  Future<Result<Plant>> update(String userId, String id, PlantInput input) =>
      _guard(() async {
        _validate(input);
        final changed = await _local.update(
          userId,
          id,
          PlantsCompanion(
            name: Value(input.name.trim()),
            species: Value(_blank(input.species)),
            notes: Value(_blank(input.notes)),
            imageName: Value(input.imageName),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(true),
          ),
        );
        if (changed == 0) throw _Missing();
        return _toEntity((await _local.find(userId, id))!);
      });

  @override
  Future<Result<void>> delete(String userId, String id) => _guard(() async {
        final changed =
            await _local.softDelete(userId, id, DateTime.now().toUtc());
        if (changed == 0) throw _Missing();
      });

  @override
  Future<Result<void>> restore(String userId, String id) => _guard(() async {
        final changed =
            await _local.restore(userId, id, DateTime.now().toUtc());
        if (changed == 0) throw _Missing();
      });

  Plant _toEntity(PlantRow r) => Plant(
        id: r.id,
        name: r.name,
        species: r.species,
        notes: r.notes,
        imageName: r.imageName,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  void _validate(PlantInput i) {
    final tooLong =
        (i.species?.length ?? 0) > 100 || (i.notes?.length ?? 0) > 2000;
    final name = i.name.trim();
    if (name.isEmpty || name.length > 100 || tooLong) throw _Invalid();
  }

  String? _blank(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on _Invalid {
      return const Err(ValidationFailure());
    } on _Missing {
      return const Err(NotFoundFailure());
    } on Object catch (e, s) {
      developer.log('plant repository error', error: e, stackTrace: s);
      return const Err(StorageFailure());
    }
  }
}
