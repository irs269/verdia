import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../features/actions/presentation/screens/actions_list_screen.dart';
import '../../features/actions/presentation/screens/create_action_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/challenges/presentation/screens/create_challenge_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/map/presentation/screens/location_picker_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/posts/presentation/screens/comments_screen.dart';
import '../../features/posts/presentation/screens/feed_screen.dart';
import '../../features/profile/domain/profile.dart';
import '../../features/profile/presentation/providers/follow_provider.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/follow_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/user_profile_screen.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../services/supabase_service.dart';
import 'go_router_refresh_stream.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const map = '/map';
  static const actions = '/actions';
  static const profile = '/profile';
  static const createAction = '/actions/create';
  static const editProfile = '/profile/edit';
  static const postComments = '/posts/:id/comments';
  static const userProfile = '/users/:id';
  static const followers = '/users/:id/followers';
  static const following = '/users/:id/following';
  static const pickLocation = '/map/pick-location';
  static const createEvent = '/events/create';
  static const createChallenge = '/challenges/create';
  static const leaderboard = '/leaderboard';
  static const createReport = '/reports/create';
  static const notifications = '/notifications';
  static const search = '/search';
}

final _authRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) async {
      final isLoggedIn = SupabaseService.client.auth.currentSession != null;
      final isOnAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (state.matchedLocation == AppRoutes.splash) {
        await Future.delayed(const Duration(milliseconds: 600));
        return isLoggedIn ? AppRoutes.home : AppRoutes.onboarding;
      }
      if (!isLoggedIn && !isOnAuthRoute) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isOnAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.createAction,
        builder: (_, _) => const CreateActionScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, state) =>
            EditProfileScreen(profile: state.extra! as Profile),
      ),
      GoRoute(
        path: AppRoutes.postComments,
        builder: (_, state) =>
            CommentsScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (_, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.followers,
        builder: (_, state) => FollowListScreen(
          profileId: state.pathParameters['id']!,
          type: FollowListType.followers,
        ),
      ),
      GoRoute(
        path: AppRoutes.following,
        builder: (_, state) => FollowListScreen(
          profileId: state.pathParameters['id']!,
          type: FollowListType.following,
        ),
      ),
      GoRoute(
        path: AppRoutes.pickLocation,
        builder: (_, state) =>
            LocationPickerScreen(initial: state.extra as LatLng?),
      ),
      GoRoute(
        path: AppRoutes.createEvent,
        builder: (_, _) => const CreateEventScreen(),
      ),
      GoRoute(
        path: AppRoutes.createChallenge,
        builder: (_, _) => const CreateChallengeScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (_, _) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.createReport,
        builder: (_, _) => const CreateReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, _) => const SearchScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const FeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (_, _) => const MapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.actions,
              builder: (_, _) => const ActionsListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
