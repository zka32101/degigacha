import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/duplicate_management_model.dart';
import '../../data/models/trading_model.dart';
import '../../data/models/marketplace_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/character_progression_repository.dart';
import '../../data/repositories/daily_spin_repository.dart';
import '../../data/repositories/duplicate_management_repository.dart';
import '../../data/repositories/event_gacha_repository.dart';
import '../../data/repositories/trading_repository.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/gacha_repository.dart';
import '../../data/repositories/login_bonus_repository.dart';
import '../../data/repositories/seasonal_event_repository.dart';
import '../../data/repositories/story_content_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/usecases/auth_usecase.dart';
import '../../domain/usecases/gacha_usecase.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import 'auth_notifier.dart';
import 'character_progression_notifier.dart';
import 'daily_spin_notifier.dart';
import 'duplicate_management_notifier.dart';
import 'event_gacha_notifier.dart';
import 'login_bonus_notifier.dart';
import 'trading_notifier.dart';
import 'marketplace_notifier.dart';
import 'payment_notifier.dart';
import 'user_profile_notifier.dart';
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

/// DuplicateManagementRepository を提供するプロバイダー
final duplicateManagementRepositoryProvider =
    Provider<DuplicateManagementRepository>((ref) {
  return DuplicateManagementRepository(FirebaseFirestore.instance);
});

/// TradingRepository を提供するプロバイダー
final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  return TradingRepository(FirebaseFirestore.instance);
});

/// MarketplaceRepository を提供するプロバイダー
final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(FirebaseFirestore.instance);
});

/// PaymentRepository を提供するプロバイダー
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(FirebaseFirestore.instance);
});

/// UserProfileRepository を提供するプロバイダー
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(FirebaseFirestore.instance);
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

// ========== Duplicate Management State Management ==========

/// 重複検出プロバイダー
final duplicateDetectionProvider = StateNotifierProvider.family<
    DuplicateDetectionNotifier,
    AsyncValue<List<DuplicateItem>>,
    String>((ref, userId) {
  final repository = ref.watch(duplicateManagementRepositoryProvider);
  return DuplicateDetectionNotifier(repository: repository, userId: userId);
});

/// 重複統計プロバイダー
final duplicateStatisticsProvider = StateNotifierProvider.family<
    DuplicateStatisticsNotifier,
    AsyncValue<DuplicateStatistics>,
    String>((ref, userId) {
  final repository = ref.watch(duplicateManagementRepositoryProvider);
  return DuplicateStatisticsNotifier(repository: repository, userId: userId);
});

/// シリーズ別重複プロバイダー
final seriesDuplicatesProvider = StateNotifierProvider.family<
    SeriesDuplicatesNotifier,
    AsyncValue<List<DuplicateItem>>,
    (String, String)>((ref, params) {
  final repository = ref.watch(duplicateManagementRepositoryProvider);
  return SeriesDuplicatesNotifier(
    repository: repository,
    userId: params.$1,
    seriesId: params.$2,
  );
});

/// レアリティ別重複プロバイダー
final rarityDuplicatesProvider = StateNotifierProvider.family<
    RarityDuplicatesNotifier,
    AsyncValue<List<DuplicateItem>>,
    (String, String)>((ref, params) {
  final repository = ref.watch(duplicateManagementRepositoryProvider);
  return RarityDuplicatesNotifier(
    repository: repository,
    userId: params.$1,
    rarity: params.$2,
  );
});

/// 受取交換リクエストプロバイダー
final receivedExchangeRequestsProvider = StateNotifierProvider.family<
    ReceivedExchangeRequestsNotifier,
    AsyncValue<List<DuplicateExchangeRequest>>,
    String>((ref, userId) {
  final repository = ref.watch(duplicateManagementRepositoryProvider);
  return ReceivedExchangeRequestsNotifier(
    repository: repository,
    userId: userId,
  );
});

/// 送信交換リクエストプロバイダー
final sentExchangeRequestsProvider = StateNotifierProvider.family<
    SentExchangeRequestsNotifier,
    AsyncValue<List<DuplicateExchangeRequest>>,
    String>((ref, userId) {
  final repository = ref.watch(duplicateManagementRepositoryProvider);
  return SentExchangeRequestsNotifier(
    repository: repository,
    userId: userId,
  );
});

// ========== Trading State Management ==========

/// 受け取ったトレード要求プロバイダー
final receivedTradeRequestsProvider = StateNotifierProvider.family<
    ReceivedTradeRequestsNotifier,
    AsyncValue<List<TradeRequest>>,
    String>((ref, userId) {
  final repository = ref.watch(tradingRepositoryProvider);
  return ReceivedTradeRequestsNotifier(
    repository: repository,
    userId: userId,
  );
});

/// 送信したトレード要求プロバイダー
final sentTradeRequestsProvider = StateNotifierProvider.family<
    SentTradeRequestsNotifier,
    AsyncValue<List<TradeRequest>>,
    String>((ref, userId) {
  final repository = ref.watch(tradingRepositoryProvider);
  return SentTradeRequestsNotifier(
    repository: repository,
    userId: userId,
  );
});

/// トレード履歴プロバイダー
final tradeHistoryProvider = StateNotifierProvider.family<
    TradeHistoryNotifier,
    AsyncValue<List<TradeHistory>>,
    String>((ref, userId) {
  final repository = ref.watch(tradingRepositoryProvider);
  return TradeHistoryNotifier(
    repository: repository,
    userId: userId,
  );
});

/// トレード統計プロバイダー
final tradeStatisticsProvider = StateNotifierProvider.family<
    TradeStatisticsNotifier,
    AsyncValue<TradeStatistics>,
    String>((ref, userId) {
  final repository = ref.watch(tradingRepositoryProvider);
  return TradeStatisticsNotifier(
    repository: repository,
    userId: userId,
  );
});

/// トレード提案プロバイダー
final tradeSuggestionsProvider = StateNotifierProvider.family<
    TradeSuggestionsNotifier,
    AsyncValue<List<TradeSuggestion>>,
    String>((ref, userId) {
  final repository = ref.watch(tradingRepositoryProvider);
  return TradeSuggestionsNotifier(
    repository: repository,
    userId: userId,
  );
});

// ========== Marketplace State Management ==========

/// すべてのリスティングプロバイダー
final allListingsProvider = StateNotifierProvider<
    AllListingsNotifier,
    AsyncValue<List<MarketListing>>>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return AllListingsNotifier(repository: repository);
});

/// レアリティ別リスティングプロバイダー
final rarityListingsProvider = StateNotifierProvider.family<
    RarityListingsNotifier,
    AsyncValue<List<MarketListing>>,
    String>((ref, rarity) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return RarityListingsNotifier(repository: repository);
});

/// シリーズ別リスティングプロバイダー
final seriesListingsProvider = StateNotifierProvider.family<
    SeriesListingsNotifier,
    AsyncValue<List<MarketListing>>,
    String>((ref, series) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return SeriesListingsNotifier(repository: repository);
});

/// セラーのリスティングプロバイダー
final sellerListingsProvider = StateNotifierProvider.family<
    SellerListingsNotifier,
    AsyncValue<List<MarketListing>>,
    String>((ref, sellerId) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return SellerListingsNotifier(repository: repository);
});

/// トランザクション履歴プロバイダー
final transactionHistoryProvider = StateNotifierProvider.family<
    TransactionHistoryNotifier,
    AsyncValue<List<MarketTransaction>>,
    String>((ref, userId) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return TransactionHistoryNotifier(repository: repository);
});

/// マーケットプレイス統計プロバイダー
final marketplaceStatisticsProvider = StateNotifierProvider<
    MarketplaceStatisticsNotifier,
    AsyncValue<MarketplaceStatistics>>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return MarketplaceStatisticsNotifier(repository: repository);
});

// ========== Payment State Management ==========

/// IAP商品プロバイダー
final iapProductsProvider = StateNotifierProvider<
    IAPProductsNotifier,
    AsyncValue<List<IAPProduct>>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return IAPProductsNotifier(repository: repository);
});

/// カテゴリ別商品プロバイダー
final categoryProductsProvider = StateNotifierProvider.family<
    CategoryProductsNotifier,
    AsyncValue<List<IAPProduct>>,
    String>((ref, category) {
  final repository = ref.watch(paymentRepositoryProvider);
  return CategoryProductsNotifier(repository: repository);
});

/// ユーザー残高プロバイダー
final userBalanceProvider = StateNotifierProvider.family<
    UserBalanceNotifier,
    AsyncValue<UserBalance?>,
    String>((ref, userId) {
  final repository = ref.watch(paymentRepositoryProvider);
  return UserBalanceNotifier(repository: repository);
});

/// レシート履歴プロバイダー
final receiptHistoryProvider = StateNotifierProvider.family<
    ReceiptHistoryNotifier,
    AsyncValue<List<Receipt>>,
    String>((ref, userId) {
  final repository = ref.watch(paymentRepositoryProvider);
  return ReceiptHistoryNotifier(repository: repository);
});

/// 支払い統計プロバイダー
final paymentStatisticsProvider = StateNotifierProvider<
    PaymentStatisticsNotifier,
    AsyncValue<PaymentStatistics>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentStatisticsNotifier(repository: repository);
});

/// プロモーションコードプロバイダー
final promotionCodeProvider = StateNotifierProvider<
    PromotionCodeNotifier,
    AsyncValue<PromotionCode?>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PromotionCodeNotifier(repository: repository);
});

/// サブスクリプションプロバイダー
final subscriptionProvider = StateNotifierProvider.family<
    SubscriptionNotifier,
    AsyncValue<Subscription?>,
    String>((ref, userId) {
  final repository = ref.watch(paymentRepositoryProvider);
  return SubscriptionNotifier(repository: repository);
});

// ========== User Profile State Management ==========

/// ユーザープロフィールプロバイダー
final userProfileProvider = StateNotifierProvider.family<
    UserProfileNotifier,
    AsyncValue<UserProfile>,
    String>((ref, userId) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return UserProfileNotifier(repository: repository, userId: userId);
});

/// ユーザーフレンドリストプロバイダー
final userFriendsProvider = StateNotifierProvider.family<
    UserFriendsNotifier,
    AsyncValue<List<Friend>>,
    String>((ref, userId) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return UserFriendsNotifier(repository: repository, userId: userId);
});

/// フレンドリクエストプロバイダー
final friendRequestsProvider = StateNotifierProvider.family<
    FriendRequestsNotifier,
    AsyncValue<List<FriendRequest>>,
    String>((ref, userId) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return FriendRequestsNotifier(repository: repository, userId: userId);
});

/// ユーザー統計プロバイダー
final userStatsProvider = StateNotifierProvider.family<
    UserStatsNotifier,
    AsyncValue<UserStats>,
    String>((ref, userId) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return UserStatsNotifier(repository: repository, userId: userId);
});

/// ユーザー実績プロバイダー
final userAchievementsProvider = StateNotifierProvider.family<
    UserAchievementsNotifier,
    AsyncValue<List<UserAchievement>>,
    String>((ref, userId) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return UserAchievementsNotifier(repository: repository, userId: userId);
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
