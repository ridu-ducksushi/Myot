import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcare/features/pets/models/pet_tool.dart';
import 'package:petcare/features/pets/widgets/tool_grid_tile.dart';

class ToolsGridSection extends StatelessWidget {
  const ToolsGridSection({
    super.key,
    required this.petId,
    required this.onSelected,
  });

  final String petId;
  final void Function(PetTool tool) onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tools = PetTool.all();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'tools.section_title'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.92,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return ToolGridTile(
                icon: tool.icon,
                label: tool.label(),
                onTap: () => onSelected(tool),
              );
            },
          ),
        ],
      ),
    );
  }
}
