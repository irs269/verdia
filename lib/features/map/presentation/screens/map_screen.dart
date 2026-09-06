import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../actions/presentation/providers/action_provider.dart';
import '../../../events/domain/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../reports/domain/environmental_report.dart';
import '../../../reports/presentation/providers/report_provider.dart';
import '../widgets/map_detail_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _filter = 'all'; // 'all' | category code | 'events' | 'reports'

  @override
  Widget build(BuildContext context) {
    final actionsState = ref.watch(actionsListProvider);
    final eventsState = ref.watch(upcomingEventsProvider);
    final reportsState = ref.watch(reportsListProvider);
    final categoriesAsync = ref.watch(actionCategoriesProvider);

    final actions = actionsState.actions
        .where((a) => a.lat != null && a.lng != null)
        .where((a) => _filter == 'all' || a.category.code == _filter)
        .toList();
    final events = (_filter == 'all' || _filter == 'events')
        ? eventsState.events
        : <Event>[];
    final reports = (_filter == 'all' || _filter == 'reports')
        ? reportsState.reports
        : <EnvironmentalReport>[];

    final markers = <Marker>[
      for (final action in actions)
        Marker(
          point: LatLng(action.lat!, action.lng!),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => showActionDetailSheet(context, action),
            child: _MarkerPin(color: action.category.color, emoji: action.category.icon),
          ),
        ),
      for (final event in events)
        Marker(
          point: LatLng(event.lat, event.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => showEventDetailSheet(context, event),
            child: const _MarkerPin(color: AppColors.info, emoji: '📅'),
          ),
        ),
      for (final report in reports)
        Marker(
          point: LatLng(report.lat, report.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => showReportDetailSheet(context, report),
            child: _MarkerPin(color: AppColors.error, emoji: ReportType.icon(report.type)),
          ),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: MapConstants.defaultCenter,
              initialZoom: MapConstants.defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: MapConstants.tileUrl,
                userAgentPackageName: MapConstants.userAgentPackageName,
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tout',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    ...categoriesAsync.valueOrNull?.map((c) => Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.sm),
                              child: _FilterChip(
                                label: '${c.icon} ${c.label}',
                                selected: _filter == c.code,
                                onTap: () => setState(() => _filter = c.code),
                              ),
                            )) ??
                        [],
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _FilterChip(
                        label: '📅 Événements',
                        selected: _filter == 'events',
                        onTap: () => setState(() => _filter = 'events'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _FilterChip(
                        label: '⚠️ Signalements',
                        selected: _filter == 'reports',
                        onTap: () => setState(() => _filter = 'reports'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _MarkerPin extends StatelessWidget {
  const _MarkerPin({required this.color, required this.emoji});

  final Color color;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}
