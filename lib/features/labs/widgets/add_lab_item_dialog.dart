import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petcare/utils/date_utils.dart' as app_date_utils;
import 'package:supabase_flutter/supabase_flutter.dart';

class AddLabItemDialog extends StatefulWidget {
  final String species;
  final String petId;
  final VoidCallback onItemAdded;

  const AddLabItemDialog({
    super.key,
    required this.species,
    required this.petId,
    required this.onItemAdded,
  });

  @override
  State<AddLabItemDialog> createState() => AddLabItemDialogState();
}

class AddLabItemDialogState extends State<AddLabItemDialog> {
  late TextEditingController _itemKeyController;
  late TextEditingController _valueController;
  late TextEditingController _referenceController;
  late TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _itemKeyController = TextEditingController();
    _valueController = TextEditingController();
    _referenceController = TextEditingController();
    _unitController = TextEditingController();
  }

  @override
  void dispose() {
    _itemKeyController.dispose();
    _valueController.dispose();
    _referenceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveNewItem() async {
    final itemKey = _itemKeyController.text.trim();
    final value = _valueController.text.trim();

    if (itemKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('labs.test_name_required'.tr())));
      return;
    }

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('labs.login_required'.tr())));
        return;
      }

      final dateKey = app_date_utils.DateUtils.toDateKey(DateTime.now());

      // Get current lab data for today
      final currentRes = await Supabase.instance.client
          .from('labs')
          .select('items')
          .eq('user_id', uid)
          .eq('pet_id', widget.petId)
          .eq('date', dateKey)
          .eq('panel', 'BloodTest')
          .maybeSingle();

      Map<String, dynamic> currentItems = {};
      if (currentRes != null) {
        currentItems = Map<String, dynamic>.from(currentRes['items'] ?? {});
      }

      // Add new item to the current items
      currentItems[itemKey] = {
        'value': value,
        'unit': _unitController.text.trim(),
        'reference': _referenceController.text.trim(),
      };

      // Save to Supabase
      await Supabase.instance.client.from('labs').upsert({
        'user_id': uid,
        'pet_id': widget.petId,
        'date': dateKey,
        'panel': 'BloodTest',
        'items': currentItems,
      });

      if (mounted) {
        // 성공 시에는 알림을 띄우지 않음 (건강 탭 UX 정책)
        widget.onItemAdded();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('labs.save_ocr_error'.tr(namedArgs: {'error': e.toString()}))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('labs.add_new_test_item'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _itemKeyController,
              decoration: InputDecoration(
                labelText: 'labs.test_name_asterisk'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'labs.add_test_name_hint'.tr(),
                helperText: 'labs.add_test_name_helper'.tr(),
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
                helperText: 'labs.add_test_value_helper'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'labs.reference_label'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'labs.reference_hint'.tr(),
                helperText: 'labs.add_reference_helper'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _unitController,
              decoration: InputDecoration(
                labelText: 'labs.unit_label'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'labs.unit_hint'.tr(),
                helperText: 'labs.add_unit_helper'.tr(),
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
        ElevatedButton(onPressed: _saveNewItem, child: Text('common.add'.tr())),
      ],
    );
  }
}
