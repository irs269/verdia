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

/// Un `ListView` scrollable (même pour l'état vide) est nécessaire pour que
/// le tiré-pour-rafraîchir marche : ces onglets restent vivants en
/// arrière-plan (`TabBarView` les garde en cache), donc c'est le seul moyen
/// de voir apparaître un élément publié pendant que l'onglet vide était déjà
/// affiché, sans redémarrer l'appli — même bug que sur le fil (Phase 10).
Widget _refreshableEmpty({required Future<void> Function() onRefresh, required String message}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(child: Text(message, style: const TextStyle(color: AppColors.textSecondary))),
      ],
    ),
  );
}

class _ActionsTab extends ConsumerStatefulWidget {
  const _ActionsTab();

  @override
  ConsumerState<_ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends ConsumerState<_ActionsTab> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(actionsListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(actionsListProvider);
    final notifier = ref.read(actionsListProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.actions.isEmpty) {
      return Center(child: Text(state.error.toString()));
    }
    if (state.actions.isEmpty) {
      return _refreshableEmpty(
        onRefresh: notifier.refresh,
        message: "Aucune action près de vous pour l'instant.",
      );
    }
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.actions.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= state.actions.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return ActionTile(action: state.actions[index]);
        },
      ),
    );
  }
}

class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab();

  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(upcomingEventsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(upcomingEventsProvider);
    final notifier = ref.read(upcomingEventsProvider.notifier);

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.events.isEmpty) {
      body = Center(child: Text(state.error.toString()));
    } else if (state.events.isEmpty) {
      body = _refreshableEmpty(onRefresh: notifier.refresh, message: 'Aucun événement prévu.');
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: state.events.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= state.events.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return EventCard(event: state.events[index]);
          },
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Événement', style: TextStyle(color: Colors.white)),
      ),
      body: body,
    );
  }
}

class _ChallengesTab extends ConsumerStatefulWidget {
  const _ChallengesTab();

  @override
  ConsumerState<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends ConsumerState<_ChallengesTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(activeChallengesProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(activeChallengesProvider);
    final notifier = ref.read(activeChallengesProvider.notifier);

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.challenges.isEmpty) {
      body = Center(child: Text(state.error.toString()));
    } else if (state.challenges.isEmpty) {
      body = _refreshableEmpty(onRefresh: notifier.refresh, message: 'Aucun défi en cours.');
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: state.challenges.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= state.challenges.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return ChallengeCard(challenge: state.challenges[index]);
          },
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/challenges/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Défi', style: TextStyle(color: Colors.white)),
      ),
      body: body,
    );
  }
}

class _ReportsTab extends ConsumerStatefulWidget {
  const _ReportsTab();

  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(reportsListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(reportsListProvider);
    final notifier = ref.read(reportsListProvider.notifier);

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.reports.isEmpty) {
      body = Center(child: Text(state.error.toString()));
    } else if (state.reports.isEmpty) {
      body = _refreshableEmpty(
        onRefresh: notifier.refresh,
        message: 'Aucun signalement pour le moment.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: state.reports.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index >= state.reports.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return ReportTile(report: state.reports[index]);
          },
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reports/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Signaler', style: TextStyle(color: Colors.white)),
      ),
      body: body,
    );
  }
}
