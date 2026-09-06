import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Coquille de navigation principale : 4 onglets + bouton central rond pour
/// créer une action, comme sur la maquette VERDIA.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.home_rounded, label: l10n.navHome),
      (icon: Icons.map_rounded, label: l10n.navMap),
      null, // emplacement du bouton central
      (icon: Icons.event_rounded, label: l10n.navActions),
      (icon: Icons.person_rounded, label: l10n.navProfile),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              if (tab == null) {
                return Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push('/actions/create'),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                );
              }

              // Les branches réelles sont 0,1,_,2,3 -> décale après le bouton central.
              final branchIndex = index < 2 ? index : index - 1;
              final selected = navigationShell.currentIndex == branchIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => navigationShell.goBranch(
                    branchIndex,
                    initialLocation: branchIndex == navigationShell.currentIndex,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
