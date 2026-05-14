import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/features/pets/widgets/pet_info_tile.dart';
import 'package:petcare/features/pets/widgets/species_pill.dart';
import 'package:petcare/ui/widgets/profile_image_picker.dart';
import 'package:petcare/utils/pet_relationship_duration.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.pet,
    required this.onEditField,
    required this.onShowWeightChart,
    required this.onImageSelected,
    required this.onImageCleared,
    required this.onDefaultIconSelected,
  });

  final Pet pet;
  final void Function(String field) onEditField;
  final VoidCallback onShowWeightChart;
  final Future<void> Function(String imagePath) onImageSelected;
  final Future<void> Function() onImageCleared;
  final Future<void> Function(String iconName, String bgColor)
      onDefaultIconSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = context.locale.toString();
    final birthLabel = pet.birthDate != null
        ? DateFormat.yMMMd(locale).format(pet.birthDate!)
        : 'pets.select_birth_date'.tr();
    final weightLabel = pet.weightKg != null
        ? '${pet.weightKg}kg'
        : 'pets.weight_kg'.tr();
    final togetherSince = pet.createdAt;
    final togetherLabel = 'pets.together_for'
        .tr(args: [formatTogetherFor(togetherSince)]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarColumn(
            pet: pet,
            onTapSpecies: () => onEditField('species'),
            onImageSelected: onImageSelected,
            onImageCleared: onImageCleared,
            onDefaultIconSelected: onDefaultIconSelected,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameRow(
                  name: pet.name,
                  onTap: () => onEditField('name'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        togetherLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.favorite, size: 14, color: cs.primary),
                  ],
                ),
                const SizedBox(height: 8),
                PetInfoTile(
                  icon: Icons.cake_outlined,
                  label: 'pets.birth_date'.tr(),
                  value: birthLabel,
                  onTap: () => onEditField('birthDate'),
                ),
                const SizedBox(height: 5),
                PetInfoTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'pets.weight'.tr(),
                  value: weightLabel,
                  onTap: () => onEditField('weight'),
                  trailing: _WeightChartButton(onTap: onShowWeightChart),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarColumn extends StatelessWidget {
  const _AvatarColumn({
    required this.pet,
    required this.onTapSpecies,
    required this.onImageSelected,
    required this.onImageCleared,
    required this.onDefaultIconSelected,
  });

  final Pet pet;
  final VoidCallback onTapSpecies;
  final Future<void> Function(String imagePath) onImageSelected;
  final Future<void> Function() onImageCleared;
  final Future<void> Function(String iconName, String bgColor)
      onDefaultIconSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileImagePicker(
          imagePath: pet.avatarUrl,
          selectedDefaultIcon: pet.defaultIcon,
          selectedBgColor: pet.profileBgColor,
          species: pet.species,
          size: 124,
          showEditIcon: true,
          onImageSelected: (image) async {
            if (image == null) return;
            await onImageSelected(image.path);
          },
          onClearSelection: () async {
            await onImageCleared();
          },
          onDefaultIconSelected: (iconName, bgColor) async {
            await onDefaultIconSelected(iconName, bgColor);
          },
        ),
        const SizedBox(height: 10),
        SpeciesPill(species: pet.species, onTap: onTapSpecies),
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_outlined, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _WeightChartButton extends StatelessWidget {
  const _WeightChartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.trending_up, size: 18, color: cs.primary),
        ),
      ),
    );
  }
}
