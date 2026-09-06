import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/organization.dart';
import '../providers/organization_provider.dart';

/// Créée toujours non vérifiée — voir le badge "non vérifiée" sur
/// [OrganizationDetailScreen] et le trigger `prevent_owner_self_verification`
/// (migration 0016) qui empêche le créateur de se vérifier lui-même. Un
/// modérateur doit la vérifier depuis le tableau de bord de modération.
class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends ConsumerState<CreateOrganizationScreen> {
  static const _categories = [
    OrganizationCategory.association,
    OrganizationCategory.ong,
    OrganizationCategory.entreprise,
    OrganizationCategory.ecole,
    OrganizationCategory.collectivite,
    OrganizationCategory.groupeCommunautaire,
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _websiteController = TextEditingController();
  String _category = OrganizationCategory.association;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final created = await ref.read(organizationControllerProvider.notifier).create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        );
    if (created != null && mounted) {
      context.pop();
      context.push('/organizations/${created.id}');
    }
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
      appBar: AppBar(title: const Text('Créer une organisation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Ton organisation sera visible immédiatement mais marquée "non vérifiée" jusqu\'à ce qu\'un modérateur la valide.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
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
                Text('Type', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _categories.map((c) {
                    return ChoiceChip(
                      label: Text('${OrganizationCategory.icon(c)} ${OrganizationCategory.label(c)}'),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    );
                  }).toList(),
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
                  label: 'Créer',
                  isLoading: controllerState.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
