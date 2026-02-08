import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/core/providers/emergency_contact_provider.dart';
import 'package:petcare/data/models/emergency_contact.dart';

class AddContactSheet extends ConsumerStatefulWidget {
  const AddContactSheet({
    super.key,
    required this.petId,
    this.existingContact,
  });

  final String petId;
  final EmergencyContact? existingContact;

  @override
  ConsumerState<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _notesController = TextEditingController();

  String _contactType = 'vet_clinic';
  bool _isPrimary = false;

  bool get _isEditing => widget.existingContact != null;

  final List<String> _contactTypeOptions = [
    'vet_clinic',
    'emergency_hospital',
    'pet_sitter',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.existingContact!;
      _nameController.text = c.name;
      _phoneController.text = c.phone;
      _addressController.text = c.address ?? '';
      _operatingHoursController.text = c.operatingHours ?? '';
      _notesController.text = c.notes ?? '';
      _contactType = c.contactType;
      _isPrimary = c.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _operatingHoursController.dispose();
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
        initialChildSize: 0.9,
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
                    _isEditing
                        ? 'emergency_contacts.edit'.tr()
                        : 'emergency_contacts.add_new'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Contact Type
                        DropdownButtonFormField<String>(
                          value: _contactType,
                          decoration: InputDecoration(
                            labelText: 'emergency_contacts.contact_type'.tr(),
                            prefixIcon: const Icon(Icons.category),
                          ),
                          items: _contactTypeOptions.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _contactTypeIcon(type),
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_contactTypeDisplayName(type)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _contactType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'emergency_contacts.name'.tr(),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'emergency_contacts.name_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'emergency_contacts.phone'.tr(),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'emergency_contacts.phone_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'emergency_contacts.address'.tr(),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Operating Hours
                        TextFormField(
                          controller: _operatingHoursController,
                          decoration: InputDecoration(
                            labelText:
                                'emergency_contacts.operating_hours'.tr(),
                            hintText:
                                'emergency_contacts.operating_hours_hint'.tr(),
                            prefixIcon: const Icon(Icons.schedule),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'emergency_contacts.notes'.tr(),
                            prefixIcon: const Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Primary toggle
                        SwitchListTile(
                          title: Text('emergency_contacts.is_primary'.tr()),
                          subtitle:
                              Text('emergency_contacts.is_primary_desc'.tr()),
                          value: _isPrimary,
                          onChanged: (value) {
                            setState(() => _isPrimary = value);
                          },
                          contentPadding: EdgeInsets.zero,
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

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final now = DateTime.now();

    if (_isEditing) {
      final updatedContact = widget.existingContact!.copyWith(
        contactType: _contactType,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        operatingHours: _operatingHoursController.text.trim().isEmpty
            ? null
            : _operatingHoursController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isPrimary: _isPrimary,
        updatedAt: now,
      );
      await ref
          .read(emergencyContactProvider.notifier)
          .updateContact(updatedContact);
    } else {
      final contact = EmergencyContact(
        id: now.millisecondsSinceEpoch.toString(),
        petId: widget.petId,
        contactType: _contactType,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        operatingHours: _operatingHoursController.text.trim().isEmpty
            ? null
            : _operatingHoursController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isPrimary: _isPrimary,
        createdAt: now,
        updatedAt: now,
      );
      await ref
          .read(emergencyContactProvider.notifier)
          .addContact(contact);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _contactTypeDisplayName(String type) {
    switch (type) {
      case 'vet_clinic':
        return 'emergency_contacts.type_vet_clinic'.tr();
      case 'emergency_hospital':
        return 'emergency_contacts.type_emergency_hospital'.tr();
      case 'pet_sitter':
        return 'emergency_contacts.type_pet_sitter'.tr();
      case 'other':
        return 'emergency_contacts.type_other'.tr();
      default:
        return type;
    }
  }

  IconData _contactTypeIcon(String type) {
    switch (type) {
      case 'vet_clinic':
        return Icons.local_hospital;
      case 'emergency_hospital':
        return Icons.emergency;
      case 'pet_sitter':
        return Icons.person;
      case 'other':
        return Icons.contacts;
      default:
        return Icons.contacts;
    }
  }
}
