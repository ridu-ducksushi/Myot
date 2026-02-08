import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:petcare/core/providers/allergy_provider.dart';
import 'package:petcare/data/models/pet_allergy.dart';

class AddAllergySheet extends ConsumerStatefulWidget {
  const AddAllergySheet({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<AddAllergySheet> createState() => _AddAllergySheetState();
}

class _AddAllergySheetState extends ConsumerState<AddAllergySheet> {
  final _formKey = GlobalKey<FormState>();
  final _allergenController = TextEditingController();
  final _reactionController = TextEditingController();
  final _notesController = TextEditingController();
  String _severity = 'moderate';
  DateTime? _diagnosedAt;

  final List<String> _severityOptions = ['mild', 'moderate', 'severe'];

  @override
  void dispose() {
    _allergenController.dispose();
    _reactionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.0,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'allergy.add_new'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Allergen
                        TextFormField(
                          controller: _allergenController,
                          decoration: InputDecoration(
                            labelText: 'allergy.allergen'.tr(),
                            prefixIcon: const Icon(Icons.warning_amber),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'allergy.allergen_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Reaction
                        TextFormField(
                          controller: _reactionController,
                          decoration: InputDecoration(
                            labelText: 'allergy.reaction'.tr(),
                            prefixIcon: const Icon(Icons.sick),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Severity
                        DropdownButtonFormField<String>(
                          value: _severity,
                          decoration: InputDecoration(
                            labelText: 'allergy.severity'.tr(),
                            prefixIcon: const Icon(Icons.priority_high),
                          ),
                          items: _severityOptions.map((severity) {
                            return DropdownMenuItem(
                              value: severity,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _severityColor(severity),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_severityLabel(severity)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _severity = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Diagnosed date
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text('allergy.diagnosed_date'.tr()),
                          subtitle: Text(
                            _diagnosedAt != null
                                ? DateFormat('yyyy-MM-dd')
                                    .format(_diagnosedAt!)
                                : 'allergy.not_set'.tr(),
                          ),
                          trailing: _diagnosedAt != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() => _diagnosedAt = null);
                                  },
                                )
                              : null,
                          onTap: _selectDiagnosedDate,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'allergy.notes'.tr(),
                            prefixIcon: const Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  // Buttons
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('common.cancel'.tr()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _save,
                          child: Text('common.save'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDiagnosedDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _diagnosedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _diagnosedAt = date;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final now = DateTime.now();
    final allergy = PetAllergy(
      id: now.millisecondsSinceEpoch.toString(),
      petId: widget.petId,
      allergen: _allergenController.text.trim(),
      reaction: _reactionController.text.trim().isEmpty
          ? null
          : _reactionController.text.trim(),
      severity: _severity,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      diagnosedAt: _diagnosedAt,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(allergyProvider.notifier).addAllergy(allergy);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'mild':
        return Colors.green;
      default:
        return Colors.grey;
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
}
