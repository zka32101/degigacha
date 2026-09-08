import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/capture_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/login_bonus_screen.dart';
import '../presentation/screens/daily_spin_screen.dart';
import '../presentation/screens/character_progression_screen.dart';
import '../presentation/screens/event_gacha_screen.dart';
import '../presentation/screens/event_calendar_screen.dart';
import '../presentation/screens/story_list_screen.dart';
import '../presentation/screens/story_reader_screen.dart';
import '../presentation/screens/item_detail_screen.dart';
import '../presentation/screens/series_completion_screen.dart';

import '../presentation/riverpod/auth_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.uid ?? '';

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/' : '/login',
    redirect: (context, state) {
      // ユーザーがログインしていない場合
      if (!authState.isAuthenticated && state.location != '/login') {
        return '/login';
      }

      // ユーザーがログイン済みでログイン画面にアクセスしている場合
      if (authState.isAuthenticated && state.location == '/login') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'capture',
            builder: (context, state) => const CaptureScreen(),
          ),
          GoRoute(
            path: 'login-bonus',
            builder: (context, state) => LoginBonusScreen(
              userId: userId,
            ),
          ),
          GoRoute(
            path: 'daily-spin',
            builder: (context, state) => DailySpinScreen(
              userId: userId,
            ),
          ),
          GoRoute(
            path: 'character-progression',
            builder: (context, state) => CharacterProgressionScreen(
              userId: userId,
            ),
          ),
          GoRoute(
            path: 'event-gacha',
            builder: (context, state) => EventGachaScreen(
              userId: userId,
            ),
          ),
          GoRoute(
            path: 'event-calendar',
            builder: (context, state) => EventCalendarScreen(
              userId: userId,
            ),
          ),
          GoRoute(
            path: 'story-list',
            builder: (context, state) => StoryListScreen(
              userId: userId,
            ),
          ),
          GoRoute(
            path: 'story-reader/:storyId',
            builder: (context, state) => StoryReaderScreen(
              userId: userId,
              storyId: state.pathParameters['storyId']!,
            ),
          ),
          GoRoute(
            path: 'series-completion/:seriesId',
            builder: (context, state) => SeriesCompletionScreen(
              userId: userId,
              seriesId: state.pathParameters['seriesId']!,
            ),
          ),
          // TODO: Add more routes
          // GoRoute(
          //   path: 'collection',
          //   builder: (context, state) => const CollectionScreen(),
          // ),
          // GoRoute(
          //   path: 'trade',
          //   builder: (context, state) => const TradeScreen(),
          // ),
        ],
      ),
    ],
  );
});
