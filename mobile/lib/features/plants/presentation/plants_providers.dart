import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/features/auth/data/auth_providers.dart';
import 'package:folia/features/plants/data/plant_providers.dart';
import 'package:folia/features/plants/domain/plant.dart';

class PlantSearch extends Notifier<String> {
  @override
  String build() => '';

  /// Sets the current search query state.
  // ignore: use_setters_to_change_properties
  void set(String value) => state = value;
}

final plantSearchProvider =
    NotifierProvider<PlantSearch, String>(PlantSearch.new);

final plantsProvider = StreamProvider.autoDispose<List<Plant>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return const Stream.empty();
  final query = ref.watch(plantSearchProvider);
  return ref.watch(plantRepositoryProvider).watchAll(user.id, query: query);
});

final plantByIdProvider =
    FutureProvider.autoDispose.family<Plant?, String>((ref, id) async {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return null;
  final result = await ref.watch(plantRepositoryProvider).getById(user.id, id);
  return switch (result) {
    Ok(:final value) => value,
    Err() => null,
  };
});

final plantActionsProvider =
    AsyncNotifierProvider<PlantActions, void>(PlantActions.new);

class PlantActions extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Result<Plant>> create(PlantInput input) =>
      _run((uid) => ref.read(plantRepositoryProvider).create(uid, input));

  Future<Result<Plant>> updatePlant(String id, PlantInput input) =>
      _run((uid) => ref.read(plantRepositoryProvider).update(uid, id, input));

  Future<Result<void>> delete(String id) =>
      _run((uid) => ref.read(plantRepositoryProvider).delete(uid, id));

  Future<Result<void>> restore(String id) =>
      _run((uid) => ref.read(plantRepositoryProvider).restore(uid, id));

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function(String userId) action,
  ) async {
    final uid = ref.read(authUserProvider).value?.id;
    if (uid == null) return const Err(AuthFailure());
    state = const AsyncLoading();
    final result = await action(uid);
    state = const AsyncData(null);
    return result;
  }
}
