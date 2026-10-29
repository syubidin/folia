import 'package:drift/drift.dart';

@DataClassName('PlantRow')
@TableIndex(name: 'plants_user_updated_idx', columns: {#userId, #updatedAt})
class Plants extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get species => text().nullable().withLength(max: 100)();
  TextColumn get notes => text().nullable().withLength(max: 2000)();
  TextColumn get imageName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
