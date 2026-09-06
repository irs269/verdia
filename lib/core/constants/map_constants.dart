import 'package:latlong2/latlong.dart';

/// Centre par défaut de la carte — Moroni, Comores.
abstract final class MapConstants {
  static const defaultCenter = LatLng(-11.7042, 43.2402);
  static const defaultZoom = 12.0;
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackageName = 'com.verdia.app';
}
