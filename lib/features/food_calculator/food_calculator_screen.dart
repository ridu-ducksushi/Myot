import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/core/providers/food_calculator_provider.dart';
import 'package:petcare/core/providers/pets_provider.dart';
import 'package:petcare/data/services/food_calculator_service.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';

class FoodCalculatorScreen extends ConsumerStatefulWidget {
  const FoodCalculatorScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<FoodCalculatorScreen> createState() =>
      _FoodCalculatorScreenState();
}

class _FoodCalculatorScreenState extends ConsumerState<FoodCalculatorScreen> {
  final _weightController = TextEditingController();
  final _foodKcalController = TextEditingController();

  String _species = 'Dog';
  String _ageCategory = 'adult';
  bool _isNeutered = false;
  String _activityLevel = 'normal';

  double _rer = 0.0;
  double _der = 0.0;
  double? _dailyPortionGrams;
  bool _hasCalculated = false;

  final List<String> _speciesOptions = ['Dog', 'Cat'];
  final List<String> _ageCategoryOptions = [
    'puppy_young',
    'puppy',
    'adult',
    'senior',
  ];
  final List<String> _activityLevelOptions = ['low', 'normal', 'high'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillFromPet();
    });
  }

  void _autoFillFromPet() {
    final pet = ref.read(petByIdProvider(widget.petId));
    if (pet == null) return;

    setState(() {
      if (pet.weightKg != null && pet.weightKg! > 0) {
        _weightController.text = pet.weightKg!.toStringAsFixed(1);
      }

      if (pet.species.toLowerCase() == 'dog' ||
          pet.species.toLowerCase() == 'cat') {
        _species = pet.species.toLowerCase() == 'dog' ? 'Dog' : 'Cat';
      }

      _isNeutered = pet.neutered ?? false;

      // Auto-determine age category if birthDate is available
      if (pet.birthDate != null) {
        final now = DateTime.now();
        final ageMonths = (now.year - pet.birthDate!.year) * 12 +
            (now.month - pet.birthDate!.month);
        _ageCategory = FoodCalculatorService.getAgeCategory(
          species: _species,
          ageMonths: ageMonths,
        );
        // Update the age category options based on species
        _updateAgeCategoriesForSpecies();
      }
    });
  }

  void _updateAgeCategoriesForSpecies() {
    if (_species.toLowerCase() == 'cat') {
      _ageCategoryOptions
        ..clear()
        ..addAll(['kitten_young', 'kitten', 'adult', 'senior']);
      // Reset if current category is dog-specific
      if (_ageCategory == 'puppy_young' || _ageCategory == 'puppy') {
        _ageCategory = 'adult';
      }
    } else {
      _ageCategoryOptions
        ..clear()
        ..addAll(['puppy_young', 'puppy', 'adult', 'senior']);
      // Reset if current category is cat-specific
      if (_ageCategory == 'kitten_young' || _ageCategory == 'kitten') {
        _ageCategory = 'adult';
      }
    }
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('food_calculator.enter_valid_weight'.tr())),
      );
      return;
    }

    final rer = FoodCalculatorService.calculateRER(weight);
    final der = FoodCalculatorService.calculateDER(
      weightKg: weight,
      species: _species,
      ageCategory: _ageCategory,
      isNeutered: _isNeutered,
      activityLevel: _activityLevel,
    );

    double? portion;
    final foodKcal = double.tryParse(_foodKcalController.text);
    if (foodKcal != null && foodKcal > 0) {
      portion = FoodCalculatorService.calculateDailyPortion(
        derKcal: der,
        foodKcalPer100g: foodKcal,
      );
    }

    setState(() {
      _rer = rer;
      _der = der;
      _dailyPortionGrams = portion;
      _hasCalculated = true;
    });

    // Also update the provider for external access
    ref.read(foodCalculatorProvider.notifier).state = FoodCalculatorState(
      weightKg: weight,
      species: _species,
      ageCategory: _ageCategory,
      isNeutered: _isNeutered,
      activityLevel: _activityLevel,
      foodKcalPer100g: foodKcal,
      rer: rer,
      der: der,
      dailyPortionGrams: portion,
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _foodKcalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppCustomAppBar(
        title: Text('food_calculator.title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weight Input
            AppTextField(
              controller: _weightController,
              labelText: 'food_calculator.weight_kg'.tr(),
              prefixIcon: const Icon(Icons.monitor_weight),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 16),

            // Species Selection
            DropdownButtonFormField<String>(
              value: _species,
              decoration: InputDecoration(
                labelText: 'food_calculator.species'.tr(),
                prefixIcon: const Icon(Icons.pets),
              ),
              items: _speciesOptions.map((species) {
                return DropdownMenuItem(
                  value: species,
                  child: Text(species),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _species = value!;
                  _updateAgeCategoriesForSpecies();
                });
              },
            ),
            const SizedBox(height: 16),

            // Age Category
            DropdownButtonFormField<String>(
              value: _ageCategory,
              decoration: InputDecoration(
                labelText: 'food_calculator.age_category'.tr(),
                prefixIcon: const Icon(Icons.cake),
              ),
              items: _ageCategoryOptions.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_ageCategoryDisplayName(category)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _ageCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Neutered Toggle
            SwitchListTile(
              title: Text('food_calculator.neutered'.tr()),
              subtitle: Text(
                _isNeutered
                    ? 'food_calculator.neutered_yes'.tr()
                    : 'food_calculator.neutered_no'.tr(),
              ),
              value: _isNeutered,
              onChanged: (value) {
                setState(() {
                  _isNeutered = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Activity Level
            DropdownButtonFormField<String>(
              value: _activityLevel,
              decoration: InputDecoration(
                labelText: 'food_calculator.activity_level'.tr(),
                prefixIcon: const Icon(Icons.directions_run),
              ),
              items: _activityLevelOptions.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(_activityLevelDisplayName(level)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _activityLevel = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Food kcal/100g Input (optional)
            AppTextField(
              controller: _foodKcalController,
              labelText: 'food_calculator.food_kcal_per_100g'.tr(),
              hintText: 'food_calculator.food_kcal_hint'.tr(),
              prefixIcon: const Icon(Icons.local_fire_department),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 24),

            // Calculate Button
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: Text('food_calculator.calculate'.tr()),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_hasCalculated) ...[
              _buildResultCard(
                context,
                title: 'RER',
                subtitle: 'food_calculator.rer_description'.tr(),
                value: '${_rer.toStringAsFixed(1)} kcal/day',
                color: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 12),
              _buildResultCard(
                context,
                title: 'DER',
                subtitle: 'food_calculator.der_description'.tr(),
                value: '${_der.toStringAsFixed(1)} kcal/day',
                color: colorScheme.secondaryContainer,
                textColor: colorScheme.onSecondaryContainer,
              ),
              if (_dailyPortionGrams != null) ...[
                const SizedBox(height: 12),
                _buildResultCard(
                  context,
                  title: 'food_calculator.daily_portion'.tr(),
                  subtitle: 'food_calculator.daily_portion_description'.tr(),
                  value: '${_dailyPortionGrams!.toStringAsFixed(1)} g/day',
                  color: colorScheme.tertiaryContainer,
                  textColor: colorScheme.onTertiaryContainer,
                ),
              ],
              const SizedBox(height: 16),
              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'food_calculator.disclaimer'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _ageCategoryDisplayName(String category) {
    switch (category) {
      case 'puppy_young':
        return 'food_calculator.age_puppy_young'.tr();
      case 'puppy':
        return 'food_calculator.age_puppy'.tr();
      case 'kitten_young':
        return 'food_calculator.age_kitten_young'.tr();
      case 'kitten':
        return 'food_calculator.age_kitten'.tr();
      case 'adult':
        return 'food_calculator.age_adult'.tr();
      case 'senior':
        return 'food_calculator.age_senior'.tr();
      default:
        return category;
    }
  }

  String _activityLevelDisplayName(String level) {
    switch (level) {
      case 'low':
        return 'food_calculator.activity_low'.tr();
      case 'normal':
        return 'food_calculator.activity_normal'.tr();
      case 'high':
        return 'food_calculator.activity_high'.tr();
      default:
        return level;
    }
  }
}
