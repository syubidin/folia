import 'package:flutter_test/flutter_test.dart';
import 'package:folia/features/scan/domain/identification.dart';
import 'package:folia/features/scan/domain/plant_catalog.dart';

void main() {
  const labels = ['_background', 'monstera', 'aglaonema', 'zz'];
  const policy = IdentificationPolicy();

  test('yakin: skor tinggi dan jarak lebar', () {
    final r = interpretScores(
      scores: [0.02, 0.90, 0.05, 0.03],
      labels: labels,
      policy: policy,
    );
    expect(r, isA<Confident>());
    expect((r as Confident).best.label, 'monstera');
  });

  test('tidak yakin: jarak ke peringkat kedua sempit', () {
    final r = interpretScores(
      scores: [0.0, 0.45, 0.40, 0.15],
      labels: labels,
      policy: policy,
    );
    expect(r, isA<Uncertain>());
    expect((r as Uncertain).candidates, hasLength(3));
  });

  test('tidak yakin: skor tertinggi di bawah ambang', () {
    final r = interpretScores(
      scores: [0.1, 0.6, 0.2, 0.1],
      labels: labels,
      policy: policy,
    );
    expect(r, isA<Uncertain>());
  });

  test('bukan tanaman: kelas background menang', () {
    final r = interpretScores(
      scores: [0.8, 0.1, 0.05, 0.05],
      labels: labels,
      policy: policy,
    );
    expect(r, isA<NoPlant>());
  });

  test('bukan tanaman: semua skor sangat rendah', () {
    final r = interpretScores(
      scores: [0.05, 0.09, 0.05, 0.04],
      labels: labels,
      policy: policy,
    );
    expect(r, isA<NoPlant>());
  });

  test('jumlah skor dan label harus sama', () {
    expect(
      () => interpretScores(scores: [0.5], labels: labels, policy: policy),
      throwsArgumentError,
    );
  });

  test('katalog: nama lokal, cadangan bahasa Inggris, lalu nama ilmiah', () {
    final catalog = PlantCatalog.fromJson(
      '{"a_b":{"scientificName":"A b","names":{"en":"Alpha"}}}',
    );
    expect(catalog.lookup('a_b').displayName('id'), 'Alpha');
    expect(catalog.lookup('zzz_unknown').displayName('id'), 'Zzz unknown');
  });
}
