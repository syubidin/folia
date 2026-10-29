import 'package:flutter/material.dart';
import 'package:folia/core/theme/app_colors.dart';
import 'package:folia/core/utils/l10n_x.dart';
import 'package:folia/features/plants/domain/plant.dart';
import 'package:folia/features/plants/presentation/widgets/plant_image.dart';

enum _CardAction { edit, delete }

class PlantCard extends StatelessWidget {
  const PlantCard({
    required this.plant,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlantImage(imageName: plant.imageName),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: PopupMenuButton<_CardAction>(
                      tooltip: l10n.edit,
                      onSelected: (a) => switch (a) {
                        _CardAction.edit => onTap(),
                        _CardAction.delete => onDelete(),
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _CardAction.edit,
                          child: Text(l10n.edit),
                        ),
                        PopupMenuItem(
                          value: _CardAction.delete,
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  if (plant.species != null)
                    Text(
                      plant.species!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
