import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/core/theme/app_colors.dart';
import 'package:folia/core/utils/failure_l10n.dart';
import 'package:folia/core/utils/l10n_x.dart';
import 'package:folia/core/utils/validators.dart';
import 'package:folia/features/plants/data/plant_image_store.dart';
import 'package:folia/features/plants/data/plant_providers.dart';
import 'package:folia/features/plants/domain/plant.dart';
import 'package:folia/features/plants/presentation/plants_providers.dart';
import 'package:folia/features/plants/presentation/widgets/plant_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class PlantFormScreen extends ConsumerWidget {
  const PlantFormScreen({super.key, this.plantId});

  final String? plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = plantId;
    if (id == null) return const _PlantForm();

    return ref.watch(plantByIdProvider(id)).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.errorStorage)),
          ),
          data: (plant) => plant == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: Center(child: Text(context.l10n.errorNotFound)),
                )
              : _PlantForm(initial: plant),
        );
  }
}

enum _PhotoAction { camera, gallery, remove }

class _PlantForm extends ConsumerStatefulWidget {
  const _PlantForm({this.initial});

  final Plant? initial;

  @override
  ConsumerState<_PlantForm> createState() => _PlantFormState();
}

class _PlantFormState extends ConsumerState<_PlantForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _species = TextEditingController(text: widget.initial?.species);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late final PlantImageStore _store = ref.read(plantImageStoreProvider);
  late String? _imageName = widget.initial?.imageName;
  bool _saved = false;

  @override
  void dispose() {
    if (!_saved) _discardPicked();
    _name.dispose();
    _species.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _discardPicked() {
    final current = _imageName;
    if (current != null && current != widget.initial?.imageName) {
      unawaited(_store.delete(current));
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _choosePhoto() async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, _PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, _PhotoAction.gallery),
            ),
            if (_imageName != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.removePhoto),
                onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _PhotoAction.remove:
        _discardPicked();
        setState(() => _imageName = null);
      case _PhotoAction.camera:
        await _pick(ImageSource.camera);
      case _PhotoAction.gallery:
        await _pick(ImageSource.gallery);
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final name = await _store.pick(source);
      if (name == null || !mounted) return;
      _discardPicked();
      setState(() => _imageName = name);
    } on Object {
      if (mounted) _toast(context.l10n.errorPhoto);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(plantActionsProvider.notifier);
    final initial = widget.initial;
    final input = PlantInput(
      name: _name.text,
      species: _species.text,
      notes: _notes.text,
      imageName: _imageName,
    );

    final result = initial == null
        ? await actions.create(input)
        : await actions.updatePlant(initial.id, input);
    if (!mounted) return;

    switch (result) {
      case Ok():
        _saved = true;
        final original = initial?.imageName;
        if (original != null && original != _imageName) {
          unawaited(_store.delete(original));
        }
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.plantSaved)));
        context.pop();
      case Err(:final failure):
        _toast(failure.localized(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = ref.watch(plantActionsProvider).isLoading;
    final editing = widget.initial != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? l10n.editPlant : l10n.addPlant)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  label: editing ? l10n.changePhoto : l10n.addPhoto,
                  child: InkWell(
                    onTap: saving ? null : _choosePhoto,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        height: 200,
                        child: PlantImage(
                          imageName: _imageName,
                          cacheWidth: 900,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: saving ? null : _choosePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      _imageName == null ? l10n.addPhoto : l10n.changePhoto,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.plantName),
                  validator: Validators.required(l10n.nameRequired),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _species,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.species),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notes,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.notes,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: saving ? null : _save,
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
