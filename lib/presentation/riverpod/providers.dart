import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/character_progression_repository.dart';
import '../../data/repositories/daily_spin_repository.dart';
import '../../data/repositories/event_gacha_repository.dart';
import '../../data/repositories/gacha_repository.dart';
import '../../data/repositories/login_bonus_repository.dart';
import '../../data/repositories/seasonal_event_repository.dart';
import '../../data/repositories/story_content_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/usecases/auth_usecase.dart';
import '../../domain/usecases/gacha_usecase.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import 'auth_notifier.dart';
import 'character_progression_notifier.dart';
import 'daily_spin_notifier.dart';
import 'event_gacha_notifier.dart';
import 'login_bonus_notifier.dart';
import 'seasonal_event_notifier.dart';
import 'story_content_notifier.dart';

// ========== Service Providers ==========

/// AuthService を提供するプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// AIService を提供するプロバイダー
final aiServiceProvider = Provider<AIService>((ref) {
  // TODO: Replace with actual API key from environment or secure storage
  const apiKey = 'sk-ant-example-key-replace-in-production';
  return AIService(apiKey: apiKey);
});

/// GachaRepository を提供するプロバイダー
final gachaRepositoryProvider = Provider<GachaRepository>((ref) {
  return GachaRepository();
});

/// UserRepository を提供するプロバイダー
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// LoginBonusRepository を提供するプロバイダー
final loginBonusRepositoryProvider = Provider<LoginBonusRepository>((ref) {
  return LoginBonusRepository(FirebaseFirestore.instance);
});

/// DailySpinRepository を提供するプロバイダー
final dailySpinRepositoryProvider = Provider<DailySpinRepository>((ref) {
  return DailySpinRepository(FirebaseFirestore.instance);
});

/// CharacterProgressionRepository を提供するプロバイダー
final characterProgressionRepositoryProvider =
    Provider<CharacterProgressionRepository>((ref) {
  return CharacterProgressionRepository(FirebaseFirestore.instance);
});

/// EventGachaRepository を提供するプロバイダー
final eventGachaRepositoryProvider = Provider<EventGachaRepository>((ref) {
  return EventGachaRepository(FirebaseFirestore.instance);
});

/// SeasonalEventRepository を提供するプロバイダー
final seasonalEventRepositoryProvider =
    Provider<SeasonalEventRepository>((ref) {
  return SeasonalEventRepository(FirebaseFirestore.instance);
});

/// StoryContentRepository を提供するプロバイダー
final storyContentRepositoryProvider = Provider<StoryContentRepository>((ref) {
  return StoryContentRepository(FirebaseFirestore.instance);
});

// ========== Use Case Providers ==========

/// AuthUsecase を提供するプロバイダー
final authUsecaseProvider = Provider<AuthUsecase>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthUsecase(
    authService: authService,
    userRepository: userRepository,
  );
});

/// GachaUsecase を提供するプロバイダー
final gachaUsecaseProvider = Provider<GachaUsecase>((ref) {
  final gachaRepository = ref.watch(gachaRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);
  return GachaUsecase(
    gachaRepository: gachaRepository,
    aiService: aiService,
  );
});

// ========== State Management Providers ==========

/// 認証状態を管理するプロバイダー
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// 現在のユーザーUID を取得するプロバイダー
final userIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.uid;
});

/// 現在のユーザーメール を取得するプロバイダー
final userEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.email;
});

/// 認証済みかチェックするプロバイダー
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

// ========== Login Bonus State Management ==========

/// ログインボーナスプロバイダー
final loginBonusProvider =
    StateNotifierProvider.family<LoginBonusNotifier, AsyncValue<LoginBonus?>, String>(
  (ref, userId) {
    final repository = ref.watch(loginBonusRepositoryProvider);
    return LoginBonusNotifier(repository);
  },
);

// ========== Daily Spin State Management ==========

/// 日次スピンプロバイダー
final dailySpinProvider =
    StateNotifierProvider.family<DailySpinNotifier, AsyncValue<DailySpin?>, String>(
  (ref, userId) {
    final repository = ref.watch(dailySpinRepositoryProvider);
    return DailySpinNotifier(repository);
  },
);

// ========== Character Progression State Management ==========

/// キャラクター育成プロバイダー
final characterProgressionProvider = StateNotifierProvider.family<
    CharacterProgressionNotifier,
    AsyncValue<List<CharacterProgression>>,
    String>(
  (ref, userId) {
    final repository = ref.watch(characterProgressionRepositoryProvider);
    return CharacterProgressionNotifier(repository);
  },
);

/// 単一キャラクター育成プロバイダー
final singleCharacterProgressionProvider = StateNotifierProvider.family<
    SingleCharacterProgressionNotifier,
    AsyncValue<CharacterProgression?>,
    (String, String)>(
  (ref, params) {
    final repository = ref.watch(characterProgressionRepositoryProvider);
    return SingleCharacterProgressionNotifier(repository);
  },
);

// ========== Event Gacha State Management ==========

/// イベントガチャプロバイダー
final eventGachaProvider =
    StateNotifierProvider<EventGachaNotifier, AsyncValue<EventGacha?>>((ref) {
  final repository = ref.watch(eventGachaRepositoryProvider);
  return EventGachaNotifier(repository);
});

/// イベントスピン結果プロバイダー
final eventSpinResultProvider =
    StateNotifierProvider<EventSpinResultNotifier, AsyncValue<EventSpinResult?>>((ref) {
  final repository = ref.watch(eventGachaRepositoryProvider);
  return EventSpinResultNotifier(repository);
});

// ========== Seasonal Event State Management ==========

/// シーズナルイベントプロバイダー
final seasonalEventProvider =
    StateNotifierProvider<SeasonalEventNotifier, AsyncValue<SeasonalEvent?>>((ref) {
  final repository = ref.watch(seasonalEventRepositoryProvider);
  return SeasonalEventNotifier(repository);
});

/// シーズナルイベント一覧プロバイダー
final seasonalEventListProvider = StateNotifierProvider<
    SeasonalEventListNotifier,
    AsyncValue<List<SeasonalEvent>>>((ref) {
  final repository = ref.watch(seasonalEventRepositoryProvider);
  return SeasonalEventListNotifier(repository);
});

// ========== Story Content State Management ==========

/// ストーリーコンテンツリストプロバイダー
final storyContentListProvider = StateNotifierProvider<
    StoryContentNotifier,
    AsyncValue<List<StoryContent>>>((ref) {
  final repository = ref.watch(storyContentRepositoryProvider);
  return StoryContentNotifier(repository);
});

/// 単一ストーリーコンテンツプロバイダー
final singleStoryContentProvider = StateNotifierProvider.family<
    SingleStoryContentNotifier,
    AsyncValue<StoryContent?>,
    String>((ref, storyId) {
  final repository = ref.watch(storyContentRepositoryProvider);
  return SingleStoryContentNotifier(repository);
});

/// ユーザーストーリー進捗プロバイダー
final userStoryProgressProvider = StateNotifierProvider.family<
    UserStoryProgressNotifier,
    AsyncValue<UserStoryProgress?>,
    (String, String)>((ref, params) {
  final repository = ref.watch(storyContentRepositoryProvider);
  return UserStoryProgressNotifier(repository);
});

/// ユーザーストーリー進捗リストプロバイダー
final userStoryProgressListProvider = StateNotifierProvider.family<
    UserStoryProgressListNotifier,
    AsyncValue<List<UserStoryProgress>>,
    String>((ref, userId) {
  final repository = ref.watch(storyContentRepositoryProvider);
  return UserStoryProgressListNotifier(repository);
});

// ========== Gacha Items State Management ==========

// /// ガチャアイテムリストプロバイダー
// final gachaItemsProvider = FutureProvider<List<GachaItem>>((ref) async {
//   final userId = ref.watch(userIdProvider);
//   if (userId == null) return [];
//
//   final repository = ref.watch(gachaRepositoryProvider);
//   return repository.getUserItems(userId);
// });

// /// シリーズ別ガチャアイテムプロバイダー
// final gachaItemsBySeriesProvider =
//     FutureProvider.family<List<GachaItem>, String>((ref, series) async {
//   final userId = ref.watch(userIdProvider);
//   if (userId == null) return [];
//
//   final repository = ref.watch(gachaRepositoryProvider);
//   return repository.getUserItemsBySeries(userId, series);
// });

// /// ユーザー統計プロバイダー
// final userStatisticsProvider = FutureProvider<ItemStatistics>((ref) async {
//   final userId = ref.watch(userIdProvider);
//   if (userId == null) {
//     return ItemStatistics(
//       totalItems: 0,
//       duplicateItems: 0,
//       manuallyEditedItems: 0,
//       rarityDistribution: {},
//       seriesCount: 0,
//       uniqueSeriesMap: {},
//     );
//   }
//
//   final repository = ref.watch(gachaRepositoryProvider);
//   return repository.getUserStatistics(userId);
// });

// ========== AI Judgment State Management ==========
// TODO: Implement after AI service integration

// /// AI判定実行プロバイダー
// final aiJudgmentProvider = FutureProvider.family<AIResult, String>((ref, imagePath) async {
//   final aiService = ref.watch(aiServiceProvider);
//   return aiService.identifyGachaItem(imagePath);
// });

// ========== UI State Management ==========

/// アプリローディング状態
final appLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

/// エラーメッセージ表示用
final errorMessageProvider = StateProvider<String?>((ref) {
  return null;
});

/// 成功メッセージ表示用
final successMessageProvider = StateProvider<String?>((ref) {
  return null;
});
