import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../actions/domain/action_category.dart';
import '../../../actions/presentation/providers/action_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../providers/challenge_provider.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController(text: 'arbres');
  ActionCategory? _category;
  DateTime _endsAt = DateTime.now().add(const Duration(days: 30));
  String? _organizerOrgId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endsAt,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endsAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une catégorie.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final success = await ref.read(createChallengeControllerProvider.notifier).publish(
          categoryId: _category!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          targetValue: double.parse(_targetController.text.replaceAll(',', '.')),
          unit: _unitController.text.trim(),
          endsAt: _endsAt,
          organizerOrgId: _organizerOrgId,
        );
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(createChallengeControllerProvider);
    final categoriesAsync = ref.watch(actionCategoriesProvider);
    final myOrgs = ref.watch(myOrganizationsProvider).valueOrNull ?? const [];

    ref.listen(createChallengeControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un défi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catégorie', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text(error.toString()),
                  data: (categories) => Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: categories.map((c) {
                      final selected = _category?.id == c.id;
                      return ChoiceChip(
                        label: Text('${c.icon} ${c.label}'),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: c.color.withValues(alpha: 0.2),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Titre du défi',
                  hint: 'Challenge 1 000 arbres',
                  controller: _titleController,
                  validator: (v) => Validators.required(v, message: 'Titre requis'),
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
                    Expanded(
                      child: AppTextField(
                        label: 'Objectif',
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || double.tryParse(v.replaceAll(',', '.')) == null) {
                            return 'Nombre requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(label: 'Unité', controller: _unitController),
                    ),
                  ],
                ),
                if (myOrgs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Publier en tant que', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: _organizerOrgId,
                        hint: const Text('Moi-même'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Moi-même'),
                          ),
                          for (final org in myOrgs)
                            DropdownMenuItem<String?>(
                              value: org.id,
                              child: Text(org.name),
                            ),
                        ],
                        onChanged: (value) => setState(() => _organizerOrgId = value),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text('Date de fin', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickEndDate,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('d MMM yyyy', 'fr_FR').format(_endsAt)),
                        const Icon(Icons.event_outlined, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Créer le défi',
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
