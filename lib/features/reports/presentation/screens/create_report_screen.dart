import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/environmental_report.dart';
import '../providers/report_provider.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  String _type = ReportType.depotSauvage;
  LatLng? _location;
  Uint8List? _photo;

  @override
  void dispose() {
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<LatLng>('/map/pick-location', extra: _location);
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() => _photo = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis un lieu sur la carte.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final success = await ref.read(createReportControllerProvider.notifier).publish(
          type: _type,
          description: _descriptionController.text.trim(),
          lat: _location!.latitude,
          lng: _location!.longitude,
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          photoBytes: _photo,
        );
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(createReportControllerProvider);

    ref.listen(createReportControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Signaler un problème')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type de problème', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ReportType.all.map((type) {
                    final selected = _type == type;
                    return ChoiceChip(
                      label: Text('${ReportType.icon(type)} ${ReportType.label(type)}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = type),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Description',
                  hint: 'Décris ce que tu as constaté...',
                  controller: _descriptionController,
                  validator: (v) => Validators.required(v, message: 'Description requise'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Lieu sur la carte', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickLocation,
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
                        Text(_location == null
                            ? 'Toucher pour choisir'
                            : '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}'),
                        const Icon(Icons.map_outlined, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Ville (optionnel)', controller: _cityController),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                      image: _photo != null
                          ? DecorationImage(image: MemoryImage(_photo!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _photo == null
                        ? const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.textSecondary, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Envoyer le signalement',
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
