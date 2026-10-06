import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/story_content_model.dart';
import '../../data/repositories/story_content_repository.dart';

/// ストーリーコンテンツ Notifier
class StoryContentNotifier extends StateNotifier<AsyncValue<List<StoryContent>>> {
  final StoryContentRepository repository;

  StoryContentNotifier(this.repository) : super(const AsyncValue.loading());

  /// すべてのストーリーを取得
  Future<void> fetchAllStories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getAllStories(),
    );
  }

  /// ストーリータイプ別に取得
  Future<void> fetchStoriesByType(String storyType) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getStoriesByType(storyType),
    );
  }
}

/// 単一ストーリーコンテンツ Notifier
class SingleStoryContentNotifier
    extends StateNotifier<AsyncValue<StoryContent?>> {
  final StoryContentRepository repository;

  SingleStoryContentNotifier(this.repository)
      : super(const AsyncValue.loading());

  /// 特定の ID でストーリーを取得
  Future<void> fetchStoryById(String storyId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getStoryById(storyId),
    );
  }
}

/// ユーザーストーリー進捗 Notifier
class UserStoryProgressNotifier
    extends StateNotifier<AsyncValue<UserStoryProgress?>> {
  final StoryContentRepository repository;

  UserStoryProgressNotifier(this.repository)
      : super(const AsyncValue.data(null));

  /// ユーザーのストーリー進捗を取得
  Future<void> fetchProgress(String userId, String storyId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getUserStoryProgress(userId, storyId),
    );
  }

  /// ストーリー進捗を更新
  Future<void> updateProgress(
    String userId,
    String storyId,
    int lastReadChapter,
    bool isCompleted,
  ) async {
    try {
      await repository.updateStoryProgress(
        userId,
        storyId,
        lastReadChapter,
        isCompleted,
      );

      // 進捗を再度取得して状態を更新
      final progress =
          await repository.getUserStoryProgress(userId, storyId);
      state = AsyncValue.data(progress);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// ストーリー進捗を初期化
  Future<void> initializeProgress(String userId, String storyId) async {
    try {
      await repository.initializeStoryProgress(userId, storyId);

      // 進捗を取得して状態を更新
      final progress =
          await repository.getUserStoryProgress(userId, storyId);
      state = AsyncValue.data(progress);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// リセット
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// ユーザーストーリー進捗リスト Notifier
class UserStoryProgressListNotifier
    extends StateNotifier<AsyncValue<List<UserStoryProgress>>> {
  final StoryContentRepository repository;

  UserStoryProgressListNotifier(this.repository)
      : super(const AsyncValue.loading());

  /// ユーザーのすべてのストーリー進捗を取得
  Future<void> fetchProgressList(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getUserStoryProgressList(userId),
    );
  }
}
