import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare/data/models/pet_supplies.dart';
import 'package:petcare/ui/theme/app_gradients.dart';

class DailySuppliesSection extends StatelessWidget {
  const DailySuppliesSection({
    super.key,
    required this.currentDate,
    required this.currentSupplies,
    required this.onPreviousDate,
    required this.onNextDate,
    required this.onPickDate,
    required this.onEditSupply,
  });

  final DateTime currentDate;
  final PetSupplies? currentSupplies;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;
  final VoidCallback onPickDate;
  final void Function(String field) onEditSupply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DateNavBar(
            date: currentDate,
            onPrev: onPreviousDate,
            onPick: onPickDate,
            onNext: onNextDate,
          ),
          const SizedBox(height: 10),
          if (currentSupplies == null)
            _EmptyRecordCard(onTap: () => onEditSupply('dryFood'))
          else
            _SuppliesList(
              supplies: currentSupplies!,
              onEditSupply: onEditSupply,
            ),
        ],
      ),
    );
  }
}

class _DateNavBar extends StatelessWidget {
  const _DateNavBar({
    required this.date,
    required this.onPrev,
    required this.onPick,
    required this.onNext,
  });

  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onPick;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = context.locale.toString();
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppGradients.softTileShadow(cs),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _ArrowButton(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat.yMMMd(locale).format(date),
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _ArrowButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: cs.primary, size: 22),
        ),
      ),
    );
  }
}

class _EmptyRecordCard extends StatelessWidget {
  const _EmptyRecordCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'supplies.no_record_for_date'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'supplies.add_prompt'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: cs.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuppliesList extends StatelessWidget {
  const _SuppliesList({
    required this.supplies,
    required this.onEditSupply,
  });

  final PetSupplies supplies;
  final void Function(String field) onEditSupply;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <_SupplyRowSpec>[
      _SupplyRowSpec(
        field: 'dryFood',
        icon: Icons.restaurant,
        label: 'supplies.dry_food'.tr(),
        value: supplies.dryFood,
      ),
      _SupplyRowSpec(
        field: 'wetFood',
        icon: Icons.rice_bowl,
        label: 'supplies.wet_food'.tr(),
        value: supplies.wetFood,
      ),
      _SupplyRowSpec(
        field: 'supplement',
        icon: Icons.medication,
        label: 'supplies.supplement'.tr(),
        value: supplies.supplement,
      ),
      _SupplyRowSpec(
        field: 'snack',
        icon: Icons.cookie,
        label: 'supplies.snack'.tr(),
        value: supplies.snack,
      ),
      _SupplyRowSpec(
        field: 'litter',
        icon: Icons.cleaning_services,
        label: 'supplies.litter'.tr(),
        value: supplies.litter,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppGradients.softTileShadow(cs),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SupplyRow(
              spec: items[i],
              onTap: () => onEditSupply(items[i].field),
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: cs.outline.withOpacity(0.15),
              ),
          ],
        ],
      ),
    );
  }
}

class _SupplyRowSpec {
  const _SupplyRowSpec({
    required this.field,
    required this.icon,
    required this.label,
    required this.value,
  });

  final String field;
  final IconData icon;
  final String label;
  final String? value;
}

class _SupplyRow extends StatelessWidget {
  const _SupplyRow({required this.spec, required this.onTap});

  final _SupplyRowSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = spec.value != null && spec.value!.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(spec.icon, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue
                        ? spec.value!
                        : 'supplies.add_placeholder'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              hasValue ? FontWeight.w600 : FontWeight.w500,
                          color: hasValue ? cs.onSurface : cs.primary,
                        ),
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
