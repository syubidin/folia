import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folia/core/database/app_database.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/features/plants/data/plant_local_data_source.dart';
import 'package:folia/features/plants/data/plant_repository_impl.dart';
import 'package:folia/features/plants/domain/plant.dart';

void main() {
  late AppDatabase db;
  late PlantRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PlantRepositoryImpl(PlantLocalDataSource(db));
  });

  tearDown(() => db.close());

  test('create lalu muncul di daftar', () async {
    await repo.create('u1', const PlantInput(name: 'Monstera'));
    final list = await repo.watchAll('u1').first;
    expect(list.map((p) => p.name), ['Monstera']);
  });

  test('data antar pengguna terisolasi', () async {
    await repo.create('u1', const PlantInput(name: 'Monstera'));
    expect(await repo.watchAll('u2').first, isEmpty);
  });

  test('pencarian berdasarkan nama atau spesies', () async {
    await repo.create(
      'u1',
      const PlantInput(name: 'Si Hijau', species: 'Aglaonema'),
    );
    await repo.create('u1', const PlantInput(name: 'Monstera'));
    expect(
      (await repo.watchAll('u1', query: 'agla').first).single.name,
      'Si Hijau',
    );
    expect(
      (await repo.watchAll('u1', query: 'monst').first).single.name,
      'Monstera',
    );
  });

  test('delete menyembunyikan dan restore mengembalikan', () async {
    final created =
        await repo.create('u1', const PlantInput(name: 'Monstera'));
    final id = (created as Ok<Plant>).value.id;

    await repo.delete('u1', id);
    expect(await repo.watchAll('u1').first, isEmpty);

    await repo.restore('u1', id);
    expect(await repo.watchAll('u1').first, hasLength(1));
  });

  test('pengguna lain tidak bisa mengubah atau menghapus', () async {
    final created =
        await repo.create('u1', const PlantInput(name: 'Monstera'));
    final id = (created as Ok<Plant>).value.id;

    final r = await repo.delete('u2', id);
    expect((r as Err<void>).failure, isA<NotFoundFailure>());
    expect(await repo.watchAll('u1').first, hasLength(1));
  });

  test('nama kosong ditolak', () async {
    final r = await repo.create('u1', const PlantInput(name: '   '));
    expect((r as Err<Plant>).failure, isA<ValidationFailure>());
  });
}
