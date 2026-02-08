import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petcare/core/providers/allergy_provider.dart';
import 'package:petcare/data/models/pet_allergy.dart';
import 'package:petcare/data/services/dangerous_food_database.dart';
import 'package:petcare/features/allergy/widgets/add_allergy_sheet.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';

class AllergyScreen extends ConsumerStatefulWidget {
  const AllergyScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends ConsumerState<AllergyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allergyProvider.notifier).loadAllergies(widget.petId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('allergy.title'.tr()),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'allergy.my_pet_allergies'.tr()),
            Tab(text: 'allergy.dangerous_foods'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllergiesTab(context, colorScheme),
          _buildDangerousFoodsTab(context, colorScheme),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddAllergySheet(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // Tab 1: My Pet's Allergies
  Widget _buildAllergiesTab(BuildContext context, ColorScheme colorScheme) {
    final allergyState = ref.watch(allergyProvider);
    final allergies = allergyState.allergies
        .where((a) => a.petId == widget.petId)
        .toList();

    if (allergyState.isLoading && allergies.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }

    if (allergies.isEmpty) {
      return AppEmptyState(
        icon: Icons.health_and_safety,
        title: 'allergy.empty_title'.tr(),
        message: 'allergy.empty_message'.tr(),
        action: ElevatedButton.icon(
          onPressed: () => _showAddAllergySheet(context),
          icon: const Icon(Icons.add),
          label: Text('allergy.add_first'.tr()),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(allergyProvider.notifier).loadAllergies(widget.petId),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: allergies.length,
        itemBuilder: (context, index) {
          return _buildAllergyCard(context, allergies[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildAllergyCard(
      BuildContext context, PetAllergy allergy, ColorScheme colorScheme) {
    final severityColor = _severityColor(allergy.severity, colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Severity indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: severityColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          allergy.allergen,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _severityLabel(allergy.severity),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: severityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  if (allergy.reaction != null &&
                      allergy.reaction!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      allergy.reaction!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (allergy.diagnosedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'allergy.diagnosed_at'.tr(args: [
                        DateFormat('yyyy-MM-dd').format(allergy.diagnosedAt!)
                      ]),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (allergy.notes != null && allergy.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      allergy.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon:
                  Icon(Icons.delete_outline, color: colorScheme.onSurfaceVariant),
              onPressed: () => _confirmDeleteAllergy(context, allergy.id),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 2: Dangerous Foods List
  Widget _buildDangerousFoodsTab(
      BuildContext context, ColorScheme colorScheme) {
    final filteredFoods = DangerousFoodDatabase.search(_searchQuery);
    final langCode = context.locale.languageCode;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'allergy.search_foods'.tr(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        // Foods list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: filteredFoods.length,
            itemBuilder: (context, index) {
              return _buildDangerousFoodCard(
                  context, filteredFoods[index], colorScheme, langCode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDangerousFoodCard(BuildContext context, DangerousFood food,
      ColorScheme colorScheme, String langCode) {
    final severityColor = _foodSeverityColor(food.severity, colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            _severityIcon(food.severity),
            color: severityColor,
            size: 18,
          ),
        ),
        title: Text(
          food.getLocalizedName(langCode),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _foodSeverityLabel(food.severity),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              food.affectedSpecies.join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'allergy.symptoms'.tr(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: food.symptoms.map((symptom) {
                    return Chip(
                      label: Text(
                        _symptomDisplayName(symptom),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                // Show all language names
                const SizedBox(height: 8),
                Text(
                  '${food.nameKo} / ${food.nameEn} / ${food.nameJa}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAllergySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) => AddAllergySheet(petId: widget.petId),
    );
  }

  Future<void> _confirmDeleteAllergy(
      BuildContext context, String allergyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('allergy.delete_title'.tr()),
        content: Text('allergy.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(allergyProvider.notifier).deleteAllergy(allergyId);
    }
  }

  Color _severityColor(String severity, ColorScheme colorScheme) {
    switch (severity) {
      case 'severe':
        return colorScheme.error;
      case 'moderate':
        return Colors.orange;
      case 'mild':
        return colorScheme.tertiary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'severe':
        return 'allergy.severity_severe'.tr();
      case 'moderate':
        return 'allergy.severity_moderate'.tr();
      case 'mild':
        return 'allergy.severity_mild'.tr();
      default:
        return severity;
    }
  }

  Color _foodSeverityColor(String severity, ColorScheme colorScheme) {
    switch (severity) {
      case 'critical':
        return colorScheme.error;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.amber.shade700;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _foodSeverityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return 'allergy.food_critical'.tr();
      case 'high':
        return 'allergy.food_high'.tr();
      case 'moderate':
        return 'allergy.food_moderate'.tr();
      default:
        return severity;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning_amber;
      case 'moderate':
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _symptomDisplayName(String symptom) {
    // Convert snake_case to human-readable form
    return symptom.replaceAll('_', ' ');
  }
}
