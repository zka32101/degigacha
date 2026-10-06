import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_progression_model.freezed.dart';
part 'character_progression_model.g.dart';

/// キャラクターのスキル
@freezed
class CharacterSkill with _$CharacterSkill {
  const factory CharacterSkill({
    required String id,
    required String name,
    required String description,
    required int requiredLevel,
    required bool isUnlocked,
  }) = _CharacterSkill;

  factory CharacterSkill.fromJson(Map<String, dynamic> json) =>
      _$CharacterSkillFromJson(json);
}

/// キャラクター育成情報
@freezed
class CharacterProgression with _$CharacterProgression {
  const factory CharacterProgression({
    required String id,
    required String userId,
    required String characterId,
    required String characterName,
    required int currentLevel,
    required int maxLevel,
    required int currentExperience,
    required int experienceToNextLevel,
    required List<CharacterSkill> skills,
    required DateTime acquiredAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CharacterProgression;

  factory CharacterProgression.fromJson(Map<String, dynamic> json) =>
      _$CharacterProgressionFromJson(json);

  /// 次のレベルまでの進捗率（0-1）
  double get progressToNextLevel =>
      currentExperience / experienceToNextLevel.toDouble();

  /// レベルアップ可能か判定
  bool get canLevelUp => currentLevel < maxLevel;

  /// 全体の進捗率（0-1）
  double get overallProgress => currentLevel / maxLevel.toDouble();

  /// 獲得可能なスキル数
  int get availableSkillsCount =>
      skills.where((skill) => !skill.isUnlocked).length;
}

/// Firestore用スキルDTO
@freezed
class CharacterSkillDTO with _$CharacterSkillDTO {
  const factory CharacterSkillDTO({
    required String id,
    required String name,
    required String description,
    required int requiredLevel,
    required bool isUnlocked,
  }) = _CharacterSkillDTO;

  factory CharacterSkillDTO.fromJson(Map<String, dynamic> json) =>
      _$CharacterSkillDTOFromJson(json);

  factory CharacterSkillDTO.fromCharacterSkill(CharacterSkill skill) {
    return CharacterSkillDTO(
      id: skill.id,
      name: skill.name,
      description: skill.description,
      requiredLevel: skill.requiredLevel,
      isUnlocked: skill.isUnlocked,
    );
  }

  CharacterSkill toCharacterSkill() {
    return CharacterSkill(
      id: id,
      name: name,
      description: description,
      requiredLevel: requiredLevel,
      isUnlocked: isUnlocked,
    );
  }
}

/// Firestore用キャラクター育成情報DTO
@freezed
class CharacterProgressionDTO with _$CharacterProgressionDTO {
  const factory CharacterProgressionDTO({
    required String id,
    required String userId,
    required String characterId,
    required String characterName,
    required int currentLevel,
    required int maxLevel,
    required int currentExperience,
    required int experienceToNextLevel,
    required List<Map<String, dynamic>> skills,
    required int acquiredAtMillis,
    required int createdAtMillis,
    required int updatedAtMillis,
  }) = _CharacterProgressionDTO;

  factory CharacterProgressionDTO.fromJson(Map<String, dynamic> json) =>
      _$CharacterProgressionDTOFromJson(json);

  factory CharacterProgressionDTO.fromCharacterProgression(
    CharacterProgression progression,
  ) {
    return CharacterProgressionDTO(
      id: progression.id,
      userId: progression.userId,
      characterId: progression.characterId,
      characterName: progression.characterName,
      currentLevel: progression.currentLevel,
      maxLevel: progression.maxLevel,
      currentExperience: progression.currentExperience,
      experienceToNextLevel: progression.experienceToNextLevel,
      skills: progression.skills
          .map((skill) => CharacterSkillDTO.fromCharacterSkill(skill).toJson())
          .toList(),
      acquiredAtMillis: progression.acquiredAt.millisecondsSinceEpoch,
      createdAtMillis: progression.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: progression.updatedAt.millisecondsSinceEpoch,
    );
  }

  CharacterProgression toCharacterProgression() {
    return CharacterProgression(
      id: id,
      userId: userId,
      characterId: characterId,
      characterName: characterName,
      currentLevel: currentLevel,
      maxLevel: maxLevel,
      currentExperience: currentExperience,
      experienceToNextLevel: experienceToNextLevel,
      skills: skills
          .map((json) => CharacterSkillDTO.fromJson(json).toCharacterSkill())
          .toList(),
      acquiredAt: DateTime.fromMillisecondsSinceEpoch(acquiredAtMillis),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }
}
