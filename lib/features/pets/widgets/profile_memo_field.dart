import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:petcare/ui/theme/app_gradients.dart';

class ProfileMemoField extends StatelessWidget {
  const ProfileMemoField({
    super.key,
    required this.memo,
    required this.onTap,
  });

  final String? memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasMemo = memo != null && memo!.trim().isNotEmpty;
    final displayText = hasMemo ? memo!.trim() : 'pets.memo_hint'.tr();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppGradients.softTileShadow(cs),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasMemo
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
