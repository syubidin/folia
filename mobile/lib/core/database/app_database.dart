import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:folia/core/database/tables/plants_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Plants])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'folia'));

  @override
  int get schemaVersion => 1;
}
