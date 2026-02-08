import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 체중 입력/수정 바텀시트
class WeightInputSheet extends StatefulWidget {
  const WeightInputSheet({
    super.key,
    this.initialWeight,
    this.initialDate,
    this.initialNote,
    this.isEditing = false,
    required this.onSave,
    this.onDelete,
  });

  final double? initialWeight;
  final DateTime? initialDate;
  final String? initialNote;
  final bool isEditing;
  final void Function(double weight, DateTime date, String? note) onSave;
  final VoidCallback? onDelete;

  @override
  State<WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends State<WeightInputSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeight?.toStringAsFixed(1) ?? '',
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.isEditing
                  ? 'weight_guide.edit_weight'.tr()
                  : 'weight_guide.add_weight'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Weight field
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
              ],
              autofocus: !widget.isEditing,
              decoration: InputDecoration(
                labelText: 'weight_guide.weight_field'.tr(),
                suffixText: 'kg',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.monitor_weight_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
            Text(
              'weight_guide.date_field'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 20, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'records.dialog.note_hint'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _handleSave,
                child: Text('common.save'.tr()),
              ),
            ),

            // Delete button (only in edit mode)
            if (widget.isEditing && widget.onDelete != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: Text('common.delete'.tr()),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  void _handleSave() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pets.weight_invalid'.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    final note = _noteController.text.trim();
    widget.onSave(weight, _selectedDate, note.isEmpty ? null : note);
  }
}
