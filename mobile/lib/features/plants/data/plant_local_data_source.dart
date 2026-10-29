import 'package:drift/drift.dart';
import 'package:folia/core/database/app_database.dart';

class PlantLocalDataSource {
  PlantLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<PlantRow>> watch(String userId, String query) {
    final q = query.trim();
    final stmt = _db.select(_db.plants)
      ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.asc(t.name),
      ]);
    if (q.isNotEmpty) {
      stmt.where(
        (t) =>
            t.name.contains(q) |
            t.species.contains(q),
      );
    }
    return stmt.watch();
  }

  Future<PlantRow?> find(String userId, String id) => (_db.select(_db.plants)
        ..where(
          (t) =>
              t.id.equals(id) & t.userId.equals(userId) & t.deletedAt.isNull(),
        ))
      .getSingleOrNull();

  Future<void> insert(PlantsCompanion row) =>
      _db.into(_db.plants).insert(row);

  Future<int> update(String userId, String id, PlantsCompanion changes) =>
      (_db.update(_db.plants)
            ..where(
              (t) =>
                  t.id.equals(id) &
                  t.userId.equals(userId) &
                  t.deletedAt.isNull(),
            ))
          .write(changes);

  Future<int> softDelete(String userId, String id, DateTime now) =>
      update(
        userId,
        id,
        PlantsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          dirty: const Value(true),
        ),
      );

  Future<int> restore(String userId, String id, DateTime now) =>
      (_db.update(_db.plants)
            ..where(
              (t) =>
                  t.id.equals(id) &
                  t.userId.equals(userId) &
                  t.deletedAt.isNotNull(),
            ))
          .write(
        PlantsCompanion(
          deletedAt: const Value<DateTime?>(null),
          updatedAt: Value(now),
          dirty: const Value(true),
        ),
      );
}
