import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petcare/core/providers/emergency_contact_provider.dart';
import 'package:petcare/data/models/emergency_contact.dart';
import 'package:petcare/features/emergency_contacts/widgets/add_contact_sheet.dart';
import 'package:petcare/features/emergency_contacts/widgets/emergency_contact_card.dart';
import 'package:petcare/ui/widgets/common_widgets.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(emergencyContactProvider.notifier)
          .loadContacts(widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(emergencyContactProvider);
    final contactsByType =
        ref.watch(contactsByTypeProvider(widget.petId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppCustomAppBar(
        title: Text('emergency_contacts.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactSheet(context),
          ),
        ],
      ),
      body: _buildBody(context, contactState, contactsByType, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EmergencyContactState state,
    Map<String, List<EmergencyContact>> contactsByType,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.contacts.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }

    if (state.error != null && state.contacts.isEmpty) {
      return AppErrorState(
        message: state.error!,
        onRetry: () => ref
            .read(emergencyContactProvider.notifier)
            .loadContacts(widget.petId),
      );
    }

    final petContacts =
        state.contacts.where((c) => c.petId == widget.petId).toList();

    if (petContacts.isEmpty) {
      return AppEmptyState(
        icon: Icons.contact_phone,
        title: 'emergency_contacts.empty_title'.tr(),
        message: 'emergency_contacts.empty_message'.tr(),
        action: ElevatedButton.icon(
          onPressed: () => _showAddContactSheet(context),
          icon: const Icon(Icons.add),
          label: Text('emergency_contacts.add_first'.tr()),
        ),
      );
    }

    // Define display order for contact types
    const typeOrder = [
      'vet_clinic',
      'emergency_hospital',
      'pet_sitter',
      'other',
    ];

    return RefreshIndicator(
      onRefresh: () => ref
          .read(emergencyContactProvider.notifier)
          .loadContacts(widget.petId),
      child: CustomScrollView(
        slivers: [
          ...typeOrder.where((type) => contactsByType.containsKey(type)).map(
            (type) {
              final contacts = contactsByType[type]!;
              return [
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: _contactTypeDisplayName(type),
                    subtitle: '${contacts.length} ${'emergency_contacts.contacts'.tr()}',
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => EmergencyContactCard(
                      contact: contacts[index],
                      onEdit: () =>
                          _showEditContactSheet(context, contacts[index]),
                      onDelete: () =>
                          _confirmDelete(context, contacts[index].id),
                    ),
                    childCount: contacts.length,
                  ),
                ),
              ];
            },
          ).expand((widgets) => widgets),

          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  void _showAddContactSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) => AddContactSheet(petId: widget.petId),
    );
  }

  void _showEditContactSheet(
      BuildContext context, EmergencyContact contact) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) => AddContactSheet(
        petId: widget.petId,
        existingContact: contact,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String contactId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('emergency_contacts.delete_title'.tr()),
        content: Text('emergency_contacts.delete_confirm'.tr()),
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
      ref.read(emergencyContactProvider.notifier).deleteContact(contactId);
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
}
