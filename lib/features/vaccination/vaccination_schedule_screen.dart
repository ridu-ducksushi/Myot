import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/core/providers/records_provider.dart';
import 'package:petcare/core/providers/vaccination_provider.dart';
import 'package:petcare/data/models/record.dart';
import 'package:petcare/data/services/vaccination_schedule_service.dart';
import 'package:petcare/features/vaccination/widgets/vaccine_card.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';

class VaccinationScheduleScreen extends ConsumerStatefulWidget {
  const VaccinationScheduleScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<VaccinationScheduleScreen> createState() =>
      _VaccinationScheduleScreenState();
}

class _VaccinationScheduleScreenState
    extends ConsumerState<VaccinationScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordsProvider.notifier).loadRecords(widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petByIdProvider(widget.petId));
    final colorScheme = Theme.of(context).colorScheme;

    // Guard: pet not found
    if (pet == null) {
      return Scaffold(
        appBar: AppCustomAppBar(
          title: Text('vaccination.title'.tr()),
        ),
        body: AppEmptyState(
          icon: Icons.pets,
          title: 'vaccination.pet_not_found'.tr(),
          message: 'vaccination.pet_not_found_message'.tr(),
        ),
      );
    }

    // Guard: species not supported
    if (!VaccinationScheduleService.isSpeciesSupported(pet.species)) {
      return Scaffold(
        appBar: AppCustomAppBar(
          title: Text('vaccination.title'.tr()),
        ),
        body: AppEmptyState(
          icon: Icons.vaccines,
          title: 'vaccination.unsupported_species'.tr(),
          message: 'vaccination.unsupported_species_message'
              .tr(args: [pet.species]),
        ),
      );
    }

    // Guard: no birthDate
    if (pet.birthDate == null) {
      return Scaffold(
        appBar: AppCustomAppBar(
          title: Text('vaccination.title'.tr()),
        ),
        body: AppEmptyState(
          icon: Icons.cake,
          title: 'vaccination.no_birthdate'.tr(),
          message: 'vaccination.no_birthdate_message'.tr(),
          action: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.edit),
            label: Text('vaccination.set_birthdate'.tr()),
          ),
        ),
      );
    }

    final overdueVaccines = ref.watch(overdueVaccinesProvider(widget.petId));
    final upcomingVaccines = ref.watch(upcomingVaccinesProvider(widget.petId));
    final completedVaccines =
        ref.watch(completedVaccinesProvider(widget.petId));

    return Scaffold(
      appBar: AppCustomAppBar(
        title: Text('vaccination.title'.tr()),
      ),
      body: CustomScrollView(
        slivers: [
          // Summary header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSummaryChip(
                    context,
                    label:
                        'vaccination.overdue_count'.tr(args: ['${overdueVaccines.length}']),
                    color: colorScheme.error,
                    bgColor: colorScheme.errorContainer,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryChip(
                    context,
                    label:
                        'vaccination.upcoming_count'.tr(args: ['${upcomingVaccines.length}']),
                    color: colorScheme.primary,
                    bgColor: colorScheme.primaryContainer,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryChip(
                    context,
                    label:
                        'vaccination.completed_count'.tr(args: ['${completedVaccines.length}']),
                    color: colorScheme.tertiary,
                    bgColor: colorScheme.tertiaryContainer,
                  ),
                ],
              ),
            ),
          ),

          // Overdue Section
          if (overdueVaccines.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'vaccination.overdue'.tr(),
                subtitle: '${overdueVaccines.length} ${'vaccination.items'.tr()}',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => VaccineCard(
                  item: overdueVaccines[index],
                  onComplete: () =>
                      _completeVaccine(overdueVaccines[index]),
                ),
                childCount: overdueVaccines.length,
              ),
            ),
          ],

          // Upcoming Section
          if (upcomingVaccines.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'vaccination.upcoming'.tr(),
                subtitle: '${upcomingVaccines.length} ${'vaccination.items'.tr()}',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => VaccineCard(
                  item: upcomingVaccines[index],
                  onComplete: () =>
                      _completeVaccine(upcomingVaccines[index]),
                ),
                childCount: upcomingVaccines.length,
              ),
            ),
          ],

          // Completed Section
          if (completedVaccines.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'vaccination.completed'.tr(),
                subtitle:
                    '${completedVaccines.length} ${'vaccination.items'.tr()}',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => VaccineCard(
                  item: completedVaccines[index],
                ),
                childCount: completedVaccines.length,
              ),
            ),
          ],

          // Empty state if no vaccines at all
          if (overdueVaccines.isEmpty &&
              upcomingVaccines.isEmpty &&
              completedVaccines.isEmpty)
            SliverFillRemaining(
              child: AppEmptyState(
                icon: Icons.vaccines,
                title: 'vaccination.empty_title'.tr(),
                message: 'vaccination.empty_message'.tr(),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context, {
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _completeVaccine(VaccineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('vaccination.complete_title'.tr()),
        content: Text(
            'vaccination.complete_confirm'.tr(args: [item.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('vaccination.mark_complete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final now = DateTime.now();
    final record = Record(
      id: now.millisecondsSinceEpoch.toString(),
      petId: widget.petId,
      type: 'health_vaccine',
      title: item.name,
      content: item.fullName,
      value: {
        'vaccineKey': item.key,
        'vaccineName': item.name,
        'scheduledDate': item.dueDate.toIso8601String(),
        'completedDate': now.toIso8601String(),
      },
      at: now,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(recordsProvider.notifier).addRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('vaccination.completed_message'.tr(args: [item.name])),
        ),
      );
    }
  }
}
