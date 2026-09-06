import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/action_category.dart';
import '../providers/action_provider.dart';

class CreateActionScreen extends ConsumerStatefulWidget {
  const CreateActionScreen({super.key});

  @override
  ConsumerState<CreateActionScreen> createState() => _CreateActionScreenState();
}

class _CreateActionScreenState extends ConsumerState<CreateActionScreen> {
  static const _stepLabels = ['Type', 'Détails', 'Publication'];

  /// Au-delà de cette distance (en mètres) entre le repère choisi sur la
  /// carte et la position GPS réelle de l'appareil, la position n'est pas
  /// considérée comme vérifiée (mais la publication n'est jamais bloquée).
  static const _locationVerificationThresholdMeters = 500.0;

  int _step = 0;
  ActionCategory? _category;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _quantityController = TextEditingController();
  final _participantsController = TextEditingController(text: '1');
  final _zoneRadiusController = TextEditingController();
  final List<Uint8List> _picked = [];
  Uint8List? _avantPhoto;
  Uint8List? _apresPhoto;
  LatLng? _location;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  bool _locatingDevice = false;
  bool _locationVerified = false;
  Position? _devicePosition;

  int _estimatedPoints = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _quantityController.dispose();
    _participantsController.dispose();
    _zoneRadiusController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85, limit: 4);
    if (images.isEmpty) return;
    final bytes = await Future.wait(images.map((f) => f.readAsBytes()));
    setState(() {
      _picked.addAll(bytes);
      if (_picked.length > 4) _picked.removeRange(0, _picked.length - 4);
    });
  }

  Future<void> _pickSingle(ValueChanged<Uint8List> onPicked) async {
    final image =
        await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (image == null) return;
    onPicked(await image.readAsBytes());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<LatLng>('/map/pick-location', extra: _location);
    if (picked == null) return;
    setState(() {
      _location = picked;
      _devicePosition = null;
      _locationVerified = false;
    });
    await _verifyDeviceLocation(picked);
  }

  /// Best-effort : n'importe quel échec (permission refusée, service de
  /// localisation désactivé, timeout) laisse simplement la position non
  /// vérifiée — ne bloque jamais la publication.
  Future<void> _verifyDeviceLocation(LatLng picked) async {
    setState(() => _locatingDevice = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        picked.latitude,
        picked.longitude,
      );
      if (!mounted) return;
      setState(() {
        _devicePosition = position;
        _locationVerified = distance <= _locationVerificationThresholdMeters;
      });
    } catch (_) {
      // Position indisponible/refusée : pas de badge, publication inchangée.
    } finally {
      if (mounted) setState(() => _locatingDevice = false);
    }
  }

  Future<void> _goToPreview() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final points = await ref.read(actionRepositoryProvider).estimatePoints(
          categoryId: _category!.id,
          quantity: quantity,
        );
    setState(() {
      _estimatedPoints = points;
      _step = 2;
    });
  }

  Future<void> _publish() async {
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final occurredAt =
        DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final success = await ref.read(createActionControllerProvider.notifier).publish(
          categoryId: _category!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          quantity: quantity,
          quantityUnit: quantity != null ? _quantityUnitFor(_category!.code) : null,
          participantsCount: int.tryParse(_participantsController.text) ?? 1,
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          lat: _location?.latitude,
          lng: _location?.longitude,
          occurredAt: occurredAt,
          deviceLat: _devicePosition?.latitude,
          deviceLng: _devicePosition?.longitude,
          locationVerified: _locationVerified,
          zoneRadiusM: _category?.code == 'nettoyage'
              ? double.tryParse(_zoneRadiusController.text.replaceAll(',', '.'))
              : null,
          avantBytes: _avantPhoto,
          apresBytes: _apresPhoto,
          mediaBytes: _picked,
        );
    if (!success || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Action publiée, en attente de validation par un modérateur."),
      ),
    );
  }

  String _quantityUnitFor(String categoryCode) {
    switch (categoryCode) {
      case 'plantation':
        return 'arbres';
      case 'nettoyage':
      case 'recyclage':
        return 'kg';
      default:
        return 'unités';
    }
  }

  String _quantityLabelFor(String? categoryCode) {
    switch (categoryCode) {
      case 'plantation':
        return "Nombre d'arbres plantés";
      case 'nettoyage':
        return 'Déchets collectés (kg)';
      case 'recyclage':
        return 'Quantité recyclée (kg)';
      default:
        return 'Quantité (optionnel)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(createActionControllerProvider);

    ref.listen(createActionControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une action'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () {
            if (_step == 0) {
              context.pop();
            } else {
              setState(() => _step -= 1);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: List.generate(_stepLabels.length, (index) {
                  final active = index <= _step;
                  return Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: active ? AppColors.primary : AppColors.border,
                          child: Text('${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        Text(_stepLabels[index],
                            style: TextStyle(
                                color: active ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 12)),
                        if (index < _stepLabels.length - 1)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              height: 1,
                              color: active ? AppColors.primary : AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: switch (_step) {
                  0 => _CategoryStep(
                      selected: _category,
                      onSelected: (c) => setState(() => _category = c),
                    ),
                  1 => _DetailsStep(
                      formKey: _formKey,
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      cityController: _cityController,
                      quantityController: _quantityController,
                      participantsController: _participantsController,
                      quantityLabel: _quantityLabelFor(_category?.code),
                      showZoneRadius: _category?.code == 'nettoyage',
                      zoneRadiusController: _zoneRadiusController,
                      picked: _picked,
                      onPickImages: _pickImages,
                      avantPhoto: _avantPhoto,
                      apresPhoto: _apresPhoto,
                      onPickAvant: () => _pickSingle((b) => setState(() => _avantPhoto = b)),
                      onPickApres: () => _pickSingle((b) => setState(() => _apresPhoto = b)),
                      location: _location,
                      onPickLocation: _pickLocation,
                      locatingDevice: _locatingDevice,
                      locationVerified: _locationVerified,
                      date: _date,
                      time: _time,
                      onPickDate: _pickDate,
                      onPickTime: _pickTime,
                    ),
                  _ => _PreviewStep(
                      category: _category!,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      city: _cityController.text,
                      picked: _picked,
                      estimatedPoints: _estimatedPoints,
                    ),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: _step == 2 ? 'Publier' : 'Suivant',
                isLoading: controllerState.isLoading,
                onPressed: switch (_step) {
                  0 => _category == null ? null : () => setState(() => _step = 1),
                  1 => _goToPreview,
                  _ => _publish,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStep extends ConsumerWidget {
  const _CategoryStep({required this.selected, required this.onSelected});

  final ActionCategory? selected;
  final ValueChanged<ActionCategory> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(actionCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quel type d\'action ?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(error.toString()),
          data: (categories) => GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.95,
            children: categories.map((category) {
              final isSelected = selected?.id == category.id;
              return GestureDetector(
                onTap: () => onSelected(category),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withValues(alpha: 0.12)
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSelected ? category.color : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(category.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          category.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.cityController,
    required this.quantityController,
    required this.participantsController,
    required this.quantityLabel,
    required this.showZoneRadius,
    required this.zoneRadiusController,
    required this.picked,
    required this.onPickImages,
    required this.avantPhoto,
    required this.apresPhoto,
    required this.onPickAvant,
    required this.onPickApres,
    required this.location,
    required this.onPickLocation,
    required this.locatingDevice,
    required this.locationVerified,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController cityController;
  final TextEditingController quantityController;
  final TextEditingController participantsController;
  final String quantityLabel;
  final bool showZoneRadius;
  final TextEditingController zoneRadiusController;
  final List<Uint8List> picked;
  final VoidCallback onPickImages;
  final Uint8List? avantPhoto;
  final Uint8List? apresPhoto;
  final VoidCallback onPickAvant;
  final VoidCallback onPickApres;
  final LatLng? location;
  final VoidCallback onPickLocation;
  final bool locatingDevice;
  final bool locationVerified;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Titre',
            hint: "Plantation d'arbres",
            controller: titleController,
            validator: (v) => Validators.required(v, message: 'Titre requis'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Description',
            hint: 'Nous avons planté 25 arbres avec les jeunes du quartier.',
            controller: descriptionController,
            validator: (v) => Validators.required(v, message: 'Description requise'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Lieu', hint: 'Moroni', controller: cityController),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PickerField(
                  label: 'Date',
                  value: DateFormat('d MMM yyyy', 'fr_FR').format(date),
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PickerField(
                  label: 'Heure',
                  value: time.format(context),
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Position sur la carte (optionnel)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          InkWell(
            onTap: onPickLocation,
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
                  Text(location == null
                      ? 'Toucher pour placer un repère'
                      : '${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)}'),
                  const Icon(Icons.map_outlined, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (location != null) ...[
            const SizedBox(height: 6),
            if (locatingDevice)
              const Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 6),
                  Text('Vérification de ta position...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              )
            else if (locationVerified)
              const Row(
                children: [
                  Icon(Icons.verified, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Position vérifiée par GPS',
                      style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ],
              ),
          ],
          if (showZoneRadius && location != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Rayon de la zone nettoyée (m, optionnel)',
              hint: '50',
              controller: zoneRadiusController,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Photos avant / après (optionnel)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PhotoSlot(label: 'Avant', bytes: avantPhoto, onTap: onPickAvant),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PhotoSlot(label: 'Après', bytes: apresPhoto, onTap: onPickApres),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: quantityLabel,
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: 'Participants',
                  controller: participantsController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Autres photos (optionnel)', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final bytes in picked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
                ),
              GestureDetector(
                onTap: picked.length >= 4 ? null : onPickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.label, required this.bytes, required this.onTap});

  final String label;
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: bytes != null
              ? Image.memory(bytes!, fit: BoxFit.cover)
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text(label,
                          style:
                              const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.category,
    required this.title,
    required this.description,
    required this.city,
    required this.picked,
    required this.estimatedPoints,
  });

  final ActionCategory category;
  final String title;
  final String description;
  final String city;
  final List<Uint8List> picked;
  final int estimatedPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text('${category.icon} ${category.label}',
                style: TextStyle(color: category.color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(description),
          if (city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
          if (picked.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.memory(picked.first, fit: BoxFit.cover),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text('⭐ +$estimatedPoints points d\'impact estimés',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Ces points seront crédités une fois ton action validée par un modérateur.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
