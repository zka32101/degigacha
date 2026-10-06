import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character_progression_model.dart';

/// キャラクター育成情報のリポジトリ
class CharacterProgressionRepository {
  final FirebaseFirestore _firestore;

  CharacterProgressionRepository(this._firestore);

  /// ユーザーが所有するキャラクター一覧を取得
  Future<List<CharacterProgression>> getUserCharacters(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .orderBy('currentLevel', descending: true)
          .orderBy('acquiredAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              CharacterProgressionDTO.fromJson(doc.data()).toCharacterProgression())
          .toList();
    } catch (e) {
      throw Exception('キャラクター一覧の取得に失敗しました: $e');
    }
  }

  /// 特定のキャラクターの育成情報を取得
  Future<CharacterProgression?> getCharacter(
    String userId,
    String characterId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(characterId)
          .get();

      if (!snapshot.exists) {
        return null;
      }

      return CharacterProgressionDTO.fromJson(snapshot.data() as Map<String, dynamic>)
          .toCharacterProgression();
    } catch (e) {
      throw Exception('キャラクター情報の取得に失敗しました: $e');
    }
  }

  /// キャラクター育成情報を追加または更新
  Future<CharacterProgression> upsertCharacter(
    CharacterProgression character,
  ) async {
    try {
      final dto = CharacterProgressionDTO.fromCharacterProgression(character);
      await _firestore
          .collection('users')
          .doc(character.userId)
          .collection('characters')
          .doc(character.id)
          .set(dto.toJson());

      return character;
    } catch (e) {
      throw Exception('キャラクター情報の更新に失敗しました: $e');
    }
  }

  /// キャラクターに経験値を追加
  Future<CharacterProgression> addExperience(
    String userId,
    String characterId,
    int experienceAmount,
  ) async {
    try {
      var character = await getCharacter(userId, characterId);

      if (character == null) {
        throw Exception('キャラクターが見つかりません');
      }

      int newExperience = character.currentExperience + experienceAmount;
      int newLevel = character.currentLevel;

      // レベルアップの判定
      while (newExperience >= character.experienceToNextLevel &&
          newLevel < character.maxLevel) {
        newExperience -= character.experienceToNextLevel;
        newLevel++;

        // スキルアンロックをチェック
        final updatedSkills = character.skills.map((skill) {
          if (skill.requiredLevel == newLevel && !skill.isUnlocked) {
            return skill.copyWith(isUnlocked: true);
          }
          return skill;
        }).toList();

        character = character.copyWith(skills: updatedSkills);
      }

      // 次のレベルまでに必要な経験値を再計算
      final nextLevelExp = _calculateExperienceToNextLevel(newLevel);

      character = character.copyWith(
        currentLevel: newLevel,
        currentExperience: newExperience,
        experienceToNextLevel: nextLevelExp,
        updatedAt: DateTime.now(),
      );

      await upsertCharacter(character);
      return character;
    } catch (e) {
      throw Exception('経験値の追加に失敗しました: $e');
    }
  }

  /// 新しいキャラクターを獲得
  Future<CharacterProgression> acquireCharacter(
    String userId,
    String characterId,
    String characterName,
  ) async {
    try {
      final now = DateTime.now();
      final initialSkills = _generateInitialSkills();

      final character = CharacterProgression(
        id: 'char_${userId}_$characterId',
        userId: userId,
        characterId: characterId,
        characterName: characterName,
        currentLevel: 1,
        maxLevel: 50,
        currentExperience: 0,
        experienceToNextLevel: _calculateExperienceToNextLevel(1),
        skills: initialSkills,
        acquiredAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await upsertCharacter(character);
      return character;
    } catch (e) {
      throw Exception('キャラクター獲得に失敗しました: $e');
    }
  }

  /// 初期スキルを生成
  List<CharacterSkill> _generateInitialSkills() {
    return [
      CharacterSkill(
        id: 'skill_001',
        name: '通常攻撃',
        description: '基本的な攻撃スキル',
        requiredLevel: 1,
        isUnlocked: true,
      ),
      CharacterSkill(
        id: 'skill_002',
        name: 'スペシャルアタック',
        description: '威力の強い攻撃スキル',
        requiredLevel: 5,
        isUnlocked: false,
      ),
      CharacterSkill(
        id: 'skill_003',
        name: 'アルティメットスキル',
        description: 'このキャラの最強スキル',
        requiredLevel: 20,
        isUnlocked: false,
      ),
      CharacterSkill(
        id: 'skill_004',
        name: 'マスターアビリティ',
        description: '最高レベルで獲得できる力',
        requiredLevel: 50,
        isUnlocked: false,
      ),
    ];
  }

  /// レベルに必要な経験値を計算
  int _calculateExperienceToNextLevel(int currentLevel) {
    // 経験値はレベルが上がるに従って指数関数的に増加
    return 100 * (1 + currentLevel ~/ 5);
  }
}
