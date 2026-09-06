import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/follow_provider.dart';
import '../../domain/conversation.dart';
import '../providers/messaging_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _selected = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis au moins un ami à ajouter.')),
      );
      return;
    }

    final conversationId = await ref.read(messagingControllerProvider.notifier).createGroup(
          name: _nameController.text.trim(),
          memberIds: _selected.toList(),
        );
    if (conversationId == null || !mounted) return;
    context.pushReplacement(
      '/messages/$conversationId',
      extra: ChatScreenArgs(
        conversationId: conversationId,
        title: _nameController.text.trim(),
        isGroup: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserProvider)?.id;
    final controllerState = ref.watch(messagingControllerProvider);
    final friendsState = myId != null ? ref.watch(followListProvider(myId)) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un groupe')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppTextField(
                  label: 'Nom du groupe',
                  hint: 'Nettoyage du samedi',
                  controller: _nameController,
                  validator: (v) => Validators.required(v, message: 'Nom requis'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Ajouter des amis'),
                ),
              ),
              Expanded(
                child: friendsState == null || friendsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : friendsState.profiles.isEmpty
                        ? const Center(
                            child: Text("Tu n'as pas encore d'amis.",
                                style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView(
                            children: [
                              for (final friend in friendsState.profiles)
                                CheckboxListTile(
                                  value: _selected.contains(friend.id),
                                  onChanged: (checked) => setState(() {
                                    if (checked ?? false) {
                                      _selected.add(friend.id);
                                    } else {
                                      _selected.remove(friend.id);
                                    }
                                  }),
                                  secondary: CircleAvatar(
                                    backgroundColor: AppColors.surfaceMuted,
                                    backgroundImage: friend.avatarUrl != null
                                        ? CachedNetworkImageProvider(friend.avatarUrl!)
                                        : null,
                                    child: friend.avatarUrl == null
                                        ? const Icon(Icons.person,
                                            color: AppColors.textSecondary)
                                        : null,
                                  ),
                                  title: Text(friend.fullName),
                                  subtitle: Text('@${friend.username}'),
                                ),
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton(
                  label: 'Créer le groupe',
                  isLoading: controllerState.isLoading,
                  onPressed: _create,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
