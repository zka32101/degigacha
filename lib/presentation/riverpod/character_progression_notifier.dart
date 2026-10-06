import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/character_progression_model.dart';
import '../../data/repositories/character_progression_repository.dart';

/// キャラクター育成情報の Notifier
class CharacterProgressionNotifier extends StateNotifier<AsyncValue<List<CharacterProgression>>> {
  final CharacterProgressionRepository repository;

  CharacterProgressionNotifier(this.repository) : super(const AsyncValue.loading());

  /// ユーザーのキャラクター一覧を取得
  Future<void> fetchCharacters(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getUserCharacters(userId),
    );
  }

  /// キャラクターに経験値を追加
  Future<CharacterProgression?> addExperience(
    String userId,
    String characterId,
    int experienceAmount,
  ) async {
    try {
      final character =
          await repository.addExperience(userId, characterId, experienceAmount);
      await fetchCharacters(userId);
      return character;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// 新しいキャラクターを獲得
  Future<CharacterProgression?> acquireCharacter(
    String userId,
    String characterId,
    String characterName,
  ) async {
    try {
      final character = await repository.acquireCharacter(
        userId,
        characterId,
        characterName,
      );
      await fetchCharacters(userId);
      return character;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

/// 単一キャラクター用の Notifier
class SingleCharacterProgressionNotifier
    extends StateNotifier<AsyncValue<CharacterProgression?>> {
  final CharacterProgressionRepository repository;

  SingleCharacterProgressionNotifier(this.repository)
      : super(const AsyncValue.loading());

  /// 特定のキャラクター情報を取得
  Future<void> fetchCharacter(String userId, String characterId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getCharacter(userId, characterId),
    );
  }

  /// キャラクターをリフレッシュ
  Future<void> refreshCharacter(String userId, String characterId) async {
    await fetchCharacter(userId, characterId);
  }
}
