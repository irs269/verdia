import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

/// Coquille de navigation principale : 4 onglets + bouton central rond pour
/// créer une action, comme sur la maquette VERDIA.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Accueil'),
    (icon: Icons.map_rounded, label: 'Carte'),
    null, // emplacement du bouton central
    (icon: Icons.event_rounded, label: 'Actions'),
    (icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
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
