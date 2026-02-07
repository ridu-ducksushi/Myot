import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditLabValueDialog extends StatefulWidget {
  final String itemKey;
  final String currentValue;
  final String reference;
  final String unit;
  // (newItemKey, newValue, newReference, newUnit)
  final void Function(String, String, String, String) onSave;
  final VoidCallback? onDelete; // 현재 수치 삭제

  const EditLabValueDialog({
    super.key,
    required this.itemKey,
    required this.currentValue,
    required this.reference,
    required this.unit,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditLabValueDialog> createState() => EditLabValueDialogState();
}

class EditLabValueDialogState extends State<EditLabValueDialog> {
  late TextEditingController _itemKeyController;
  late TextEditingController _valueController;
  late TextEditingController _referenceController;
  late TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _itemKeyController = TextEditingController(text: widget.itemKey);
    _valueController = TextEditingController(text: widget.currentValue);
    _referenceController = TextEditingController(text: widget.reference);
    _unitController = TextEditingController(text: widget.unit);
  }

  @override
  void dispose() {
    _itemKeyController.dispose();
    _valueController.dispose();
    _referenceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('labs.edit_test_value'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _itemKeyController,
              decoration: InputDecoration(
                labelText: 'labs.test_name_label'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'labs.test_name_hint'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                FilteringTextInputFormatter.deny(RegExp(r',')),
              ],
              decoration: InputDecoration(
                labelText: 'labs.test_value_label'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'labs.test_value_hint'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'labs.reference_label'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'labs.reference_hint'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _unitController,
              decoration: InputDecoration(
                labelText: 'labs.unit_label'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'labs.unit_hint'.tr(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            widget.onDelete?.call();
            Navigator.of(context).pop();
          },
          child: Text('common.delete'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            final newItemKey = _itemKeyController.text.trim();
            final newValue = _valueController.text.trim();
            final newReference = _referenceController.text.trim();
            final newUnit = _unitController.text.trim();
            if (newItemKey.isNotEmpty) {
              widget.onSave(newItemKey, newValue, newReference, newUnit);
              Navigator.of(context).pop();
            }
          },
          child: Text('common.save'.tr()),
        ),
      ],
    );
  }
}
