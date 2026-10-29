import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/core/theme/app_colors.dart';
import 'package:folia/core/utils/failure_l10n.dart';
import 'package:folia/core/utils/l10n_x.dart';
import 'package:folia/features/auth/presentation/auth_controller.dart';
import 'package:folia/features/plants/domain/plant.dart';
import 'package:folia/features/plants/presentation/plants_providers.dart';
import 'package:folia/features/plants/presentation/widgets/plant_card.dart';
import 'package:go_router/go_router.dart';

class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => ref.read(plantSearchProvider.notifier).set(value),
    );
  }

  Future<void> _delete(Plant plant) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(plantActionsProvider.notifier);

    final result = await actions.delete(plant.id);
    if (!mounted) return;

    messenger.clearSnackBars();
    switch (result) {
      case Ok():
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.plantDeleted(plant.name)),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () => actions.restore(plant.id),
            ),
          ),
        );
      case Err(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failure.localized(l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plants = ref.watch(plantsProvider);
    final searching = ref.watch(plantSearchProvider).trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myGarden),
        actions: [
          IconButton(
            tooltip: l10n.logout,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/plants/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addPlant),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: plants.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text(l10n.errorStorage)),
              data: (list) => list.isEmpty
                  ? _EmptyState(searching: searching)
                  : Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              l10n.plantCount(list.length),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              96,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: AppSpacing.md - 4,
                              crossAxisSpacing: AppSpacing.md - 4,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final plant = list[i];
                              return PlantCard(
                                key: ValueKey(plant.id),
                                plant: plant,
                                onTap: () =>
                                    context.push('/plants/${plant.id}/edit'),
                                onDelete: () => _delete(plant),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.local_florist_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              searching ? l10n.emptySearchTitle : l10n.emptyGardenTitle,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              searching ? l10n.emptySearchBody : l10n.emptyGardenBody,
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
