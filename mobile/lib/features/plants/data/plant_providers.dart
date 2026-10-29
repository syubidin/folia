import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/database/database_provider.dart';
import 'package:folia/features/plants/data/plant_image_store.dart';
import 'package:folia/features/plants/data/plant_local_data_source.dart';
import 'package:folia/features/plants/data/plant_repository_impl.dart';
import 'package:folia/features/plants/domain/plant_repository.dart';

final plantRepositoryProvider = Provider<PlantRepository>(
  (ref) => PlantRepositoryImpl(
    PlantLocalDataSource(ref.watch(appDatabaseProvider)),
  ),
);

final plantImageStoreProvider = Provider<PlantImageStore>(
  (ref) => PlantImageStore(),
);

final plantImageDirProvider = FutureProvider<String>((ref) async {
  final dir = await ref.watch(plantImageStoreProvider).directory();
  return dir.path;
});
