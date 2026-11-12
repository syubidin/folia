import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/theme/app_colors.dart';
import 'package:folia/core/utils/failure_l10n.dart';
import 'package:folia/core/utils/l10n_x.dart';
import 'package:folia/features/plants/data/plant_providers.dart';
import 'package:folia/features/plants/domain/plant.dart';
import 'package:folia/features/scan/data/scan_providers.dart';
import 'package:folia/features/scan/domain/identification.dart';
import 'package:folia/features/scan/domain/plant_catalog.dart';
import 'package:folia/features/scan/presentation/scan_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() {
        if (!mounted) return;
        ref.read(scanControllerProvider.notifier).reset();
        unawaited(ref.read(plantClassifierProvider).warmUp());
      }),
    );
  }

  PlantSpecies _species(String slug) =>
      ref.read(plantCatalogProvider).value?.lookup(slug) ??
      PlantSpecies.fromSlug(slug);

  Future<void> _addToGarden(String imagePath, PlantSpecies species) async {
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final store = ref.read(plantImageStoreProvider);
    try {
      final name = await store.adopt(imagePath);
      if (!mounted) {
        unawaited(store.delete(name));
        return;
      }
      unawaited(
        router.pushReplacement(
          '/plants/new',
          extra: PlantPrefill(
            name: species.displayName(lang),
            species: species.scientificName,
            imageName: name,
          ),
        ),
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorPhoto)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(plantClassifierProvider)
      ..watch(plantCatalogProvider);
    final state = ref.watch(scanControllerProvider);
    final controller = ref.read(scanControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.identifyPlant)),
      body: SafeArea(
        child: switch (state) {
          ScanIdle() => _Idle(onPick: controller.start),
          ScanAnalyzing(:final imagePath) => _Analyzing(imagePath: imagePath),
          ScanDone(:final imagePath, :final outcome) => _Result(
              imagePath: imagePath,
              outcome: outcome,
              resolve: _species,
              onAdd: (species) => _addToGarden(imagePath, species),
              onRetry: controller.reset,
            ),
          ScanFailed(:final failure, :final imagePath) => _Message(
              imagePath: imagePath,
              icon: Icons.error_outline,
              title: failure.localized(context.l10n),
              onRetry: controller.reset,
            ),
        },
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.onPick});

  final void Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.scanIntroTitle,
                style: text.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.scanIntroBody,
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.takePhoto),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.chooseFromGallery),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.path);

  final String path;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: 260,
          width: double.infinity,
          child: Image.file(File(path), fit: BoxFit.cover, cacheWidth: 900),
        ),
      );
}

class _Analyzing extends StatelessWidget {
  const _Analyzing({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _Preview(imagePath),
            const SizedBox(height: AppSpacing.lg),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.analyzing,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.onRetry,
    this.imagePath,
    this.body,
  });

  final String? imagePath;
  final IconData icon;
  final String title;
  final String? body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagePath != null) ...[
            _Preview(imagePath!),
            const SizedBox(height: AppSpacing.lg),
          ],
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(body!, style: text.bodyMedium, textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.l10n.tryAnotherPhoto),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.imagePath,
    required this.outcome,
    required this.resolve,
    required this.onAdd,
    required this.onRetry,
  });

  final String imagePath;
  final IdentificationOutcome outcome;
  final PlantSpecies Function(String slug) resolve;
  final void Function(PlantSpecies) onAdd;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;

    switch (outcome) {
      case NoPlant():
        return _Message(
          imagePath: imagePath,
          icon: Icons.search_off,
          title: l10n.noPlantTitle,
          body: l10n.noPlantBody,
          onRetry: onRetry,
        );

      case Uncertain(:final candidates):
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Preview(imagePath),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.notSureTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.notSureBody, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final p in candidates)
              _PredictionTile(
                species: resolve(p.label),
                prediction: p,
                lang: lang,
                onTap: () => onAdd(resolve(p.label)),
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l10n.tryAnotherPhoto),
            ),
          ],
        );

      case Confident(:final best, :final alternatives):
        final species = resolve(best.label);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Preview(imagePath),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.itLooksLike, style: text.labelLarge),
            Text(species.displayName(lang), style: text.headlineMedium),
            Text(
              species.scientificName,
              style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(
                  l10n.matchPercent((best.confidence * 100).round()),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => onAdd(species),
              icon: const Icon(Icons.add),
              label: Text(l10n.addToGarden),
            ),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.otherPossibilities, style: text.titleMedium),
              for (final p in alternatives)
                _PredictionTile(
                  species: resolve(p.label),
                  prediction: p,
                  lang: lang,
                  onTap: () => onAdd(resolve(p.label)),
                ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: Text(l10n.tryAnotherPhoto)),
          ],
        );
    }
  }
}

class _PredictionTile extends StatelessWidget {
  const _PredictionTile({
    required this.species,
    required this.prediction,
    required this.lang,
    required this.onTap,
  });

  final PlantSpecies species;
  final Prediction prediction;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(species.displayName(lang)),
        subtitle: Text(
          species.scientificName,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        trailing: Text('${(prediction.confidence * 100).round()}%'),
        onTap: onTap,
      );
}
