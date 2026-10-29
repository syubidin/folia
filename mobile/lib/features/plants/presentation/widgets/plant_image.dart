import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/features/plants/data/plant_providers.dart';
import 'package:path/path.dart' as p;

class PlantImage extends ConsumerWidget {
  const PlantImage({super.key, this.imageName, this.cacheWidth = 600});

  final String? imageName;
  final int cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(plantImageDirProvider).value;
    final name = imageName;
    if (name == null || dir == null) return const _Placeholder();
    return Image.file(
      File(p.join(dir, name)),
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primary.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          Icons.local_florist_outlined,
          size: 40,
          color: scheme.primary,
        ),
      ),
    );
  }
}
