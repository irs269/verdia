import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../shared/widgets/app_button.dart';

/// Écran plein écran réutilisable pour choisir une position : on touche la
/// carte pour placer le marqueur, puis on confirme. Retourne un [LatLng] via
/// `context.pop`, ou `null` si annulé.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un lieu')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initial ?? MapConstants.defaultCenter,
              initialZoom: MapConstants.defaultZoom,
              onTap: (tapPosition, point) => setState(() => _picked = point),
            ),
            children: [
              TileLayer(
                urlTemplate: MapConstants.tileUrl,
                userAgentPackageName: MapConstants.userAgentPackageName,
              ),
              if (_picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _picked!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                  ),
                ]),
            ],
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: SafeArea(
              child: AppButton(
                label: _picked == null ? 'Touche la carte pour choisir' : 'Confirmer ce lieu',
                onPressed: _picked == null ? null : () => context.pop(_picked),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
