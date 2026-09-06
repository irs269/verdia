import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/profile_list_tile.dart';
import '../providers/follow_provider.dart';

class FollowListScreen extends ConsumerStatefulWidget {
  const FollowListScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(followListProvider(widget.profileId).notifier).loadMore();
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
    final state = ref.watch(followListProvider(widget.profileId));

    return Scaffold(
      appBar: AppBar(title: const Text('Amis')),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.profiles.isEmpty) {
            return Center(child: Text(state.error.toString()));
          }
          if (state.profiles.isEmpty) {
            return const Center(
              child: Text("Pas encore d'amis.",
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.profiles.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= state.profiles.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ProfileListTile(profile: state.profiles[index]);
            },
          );
        },
      ),
    );
  }
}
