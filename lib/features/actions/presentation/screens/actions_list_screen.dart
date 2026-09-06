import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../challenges/presentation/widgets/challenge_card.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../events/presentation/widgets/event_card.dart';
import '../../../reports/presentation/providers/report_provider.dart';
import '../../../reports/presentation/widgets/report_tile.dart';
import '../providers/action_provider.dart';
import '../widgets/action_tile.dart';

class ActionsListScreen extends StatelessWidget {
  const ActionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Actions'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Actions'),
              Tab(text: 'Événements'),
              Tab(text: 'Défis'),
              Tab(text: 'Signalements'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ActionsTab(), _EventsTab(), _ChallengesTab(), _ReportsTab()],
        ),
      ),
    );
  }
}

class _ActionsTab extends ConsumerWidget {
  const _ActionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionsListProvider);

    return actionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (actions) {
        if (actions.isEmpty) {
          return const Center(
            child: Text(
              "Aucune action près de vous pour l'instant.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(actionsListProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => ActionTile(action: actions[index]),
          ),
        );
      },
    );
  }
}

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Événement', style: TextStyle(color: Colors.white)),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Aucun événement prévu.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(upcomingEventsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => EventCard(event: events[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/challenges/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Défi', style: TextStyle(color: Colors.white)),
      ),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (challenges) {
          if (challenges.isEmpty) {
            return const Center(
              child: Text(
                'Aucun défi en cours.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activeChallengesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: challenges.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => ChallengeCard(challenge: challenges[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reports/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Signaler', style: TextStyle(color: Colors.white)),
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'Aucun signalement pour le moment.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reportsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => ReportTile(report: reports[index]),
            ),
          );
        },
      ),
    );
  }
}
