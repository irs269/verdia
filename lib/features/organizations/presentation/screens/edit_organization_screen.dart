import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/organization.dart';
import '../providers/organization_provider.dart';

/// Réservé au propriétaire (`organization_members.role = 'owner'`) — voir
/// [OrganizationDetailScreen], qui n'affiche le bouton "Modifier" que pour
/// lui, et la policy RLS "Owners can update their organization" (0015) qui
/// refuse de toute façon l'écriture côté serveur pour les autres.
class EditOrganizationScreen extends ConsumerStatefulWidget {
  const EditOrganizationScreen({super.key, required this.organization});

  final Organization organization;

  @override
  ConsumerState<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends ConsumerState<EditOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.organization.name);
  late final _descriptionController = TextEditingController(text: widget.organization.description);
  late final _cityController = TextEditingController(text: widget.organization.city);
  late final _countryController = TextEditingController(text: widget.organization.country);
  late final _websiteController = TextEditingController(text: widget.organization.website);
  final _memberUsernameController = TextEditingController();
  Uint8List? _newLogo;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _memberUsernameController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final username = _memberUsernameController.text.trim();
    if (username.isEmpty) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(organizationControllerProvider.notifier).addMember(
          organizationId: widget.organization.id,
          username: username,
        );
    if (!mounted) return;
    if (success) {
      _memberUsernameController.clear();
    } else {
      final error = ref.read(organizationControllerProvider).error;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeMember(String profileId) async {
    await ref.read(organizationControllerProvider.notifier).removeMember(
          organizationId: widget.organization.id,
          profileId: profileId,
        );
  }

  Future<void> _pickLogo() async {
    final image =
        await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() => _newLogo = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(organizationControllerProvider.notifier).updateOrganization(
          organizationId: widget.organization.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          newLogoBytes: _newLogo,
        );
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(organizationControllerProvider);

    ref.listen(organizationControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Modifier l'organisation")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surfaceMuted,
                      backgroundImage: _newLogo != null
                          ? MemoryImage(_newLogo!)
                          : (widget.organization.logoUrl != null
                              ? CachedNetworkImageProvider(widget.organization.logoUrl!)
                              : null),
                      child: _newLogo == null && widget.organization.logoUrl == null
                          ? const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Nom',
                  controller: _nameController,
                  validator: (v) => Validators.required(v, message: 'Nom requis'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  validator: (v) => Validators.required(v, message: 'Description requise'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'Ville', controller: _cityController)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: AppTextField(label: 'Pays', controller: _countryController)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Site web', controller: _websiteController),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Enregistrer',
                  isLoading: controllerState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Text('Membres', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: "Nom d'utilisateur",
                        hint: 'ex. ahmed.verdia',
                        controller: _memberUsernameController,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: IconButton.filled(
                        onPressed: controllerState.isLoading ? null : _addMember,
                        icon: const Icon(Icons.person_add_alt_1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Consumer(
                  builder: (context, ref, _) {
                    final membersAsync =
                        ref.watch(organizationMembersProvider(widget.organization.id));
                    return membersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(error.toString()),
                      data: (members) => Column(
                        children: members.map((member) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.surfaceMuted,
                              backgroundImage: member.avatarUrl != null
                                  ? CachedNetworkImageProvider(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl == null
                                  ? const Icon(Icons.person, size: 18, color: AppColors.textSecondary)
                                  : null,
                            ),
                            title: Text(member.fullName),
                            subtitle: Text('@${member.username}${member.isOwner ? ' · Propriétaire' : ''}'),
                            trailing: member.isOwner
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                                    tooltip: 'Retirer',
                                    onPressed: () => _removeMember(member.profileId),
                                  ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
