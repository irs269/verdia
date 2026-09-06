import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/event_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _targetController = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  LatLng? _location;
  Uint8List? _cover;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<LatLng>('/map/pick-location', extra: _location);
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _pickCover() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() => _cover = bytes);
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

    final startsAt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final success = await ref.read(createEventControllerProvider.notifier).publish(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          lat: _location!.latitude,
          lng: _location!.longitude,
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          startsAt: startsAt,
          targetParticipants: int.tryParse(_targetController.text),
          coverBytes: _cover,
        );
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(createEventControllerProvider);

    ref.listen(createEventControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un événement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickCover,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                      image: _cover != null
                          ? DecorationImage(image: MemoryImage(_cover!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _cover == null
                        ? const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.textSecondary, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: "Titre de l'événement",
                  hint: 'Nettoyage de la plage de Moroni',
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
                      child: _PickerField(
                        label: 'Date',
                        value: DateFormat('d MMM yyyy', 'fr_FR').format(_date),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PickerField(
                        label: 'Heure',
                        value: _time.format(context),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _PickerField(
                  label: 'Lieu sur la carte',
                  value: _location == null
                      ? 'Toucher pour choisir'
                      : '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}',
                  onTap: _pickLocation,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Ville', controller: _cityController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Objectif de participants (optionnel)',
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: "Créer l'événement",
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

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value),
                const Icon(Icons.edit_calendar_outlined,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
