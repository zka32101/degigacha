import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_bonus_model.freezed.dart';
part 'login_bonus_model.g.dart';

/// ボーナスレベルの種類
enum BonusLevel {
  @JsonValue('bronze')
  bronze('bronze', 10),
  @JsonValue('silver')
  silver('silver', 25),
  @JsonValue('gold')
  gold('gold', 50),
  @JsonValue('platinum')
  platinum('platinum', 100);

  final String value;
  final int bonusPoints;
  const BonusLevel(this.value, this.bonusPoints);

  /// 連続ログイン日数からボーナスレベルを決定
  static BonusLevel fromConsecutiveDays(int days) {
    if (days >= 30) return BonusLevel.platinum;
    if (days >= 14) return BonusLevel.gold;
    if (days >= 7) return BonusLevel.silver;
    return BonusLevel.bronze;
  }
}

/// ログインボーナス情報
@freezed
class LoginBonus with _$LoginBonus {
  const factory LoginBonus({
    required String id,
    required String userId,
    required DateTime lastLoginDate,
    required int consecutiveDays,
    required int totalBonusPoints,
    required BonusLevel bonusLevel,
    required bool isClaimedToday,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LoginBonus;

  factory LoginBonus.fromJson(Map<String, dynamic> json) =>
      _$LoginBonusFromJson(json);
}

/// Firestore用ログインボーナスDTO
@freezed
class LoginBonusDTO with _$LoginBonusDTO {
  const factory LoginBonusDTO({
    required String id,
    required String userId,
    required int lastLoginDateMillis,
    required int consecutiveDays,
    required int totalBonusPoints,
    required String bonusLevel,
    required bool isClaimedToday,
    required int createdAtMillis,
    required int updatedAtMillis,
  }) = _LoginBonusDTO;

  factory LoginBonusDTO.fromJson(Map<String, dynamic> json) =>
      _$LoginBonusDTOFromJson(json);

  factory LoginBonusDTO.fromLoginBonus(LoginBonus bonus) {
    return LoginBonusDTO(
      id: bonus.id,
      userId: bonus.userId,
      lastLoginDateMillis: bonus.lastLoginDate.millisecondsSinceEpoch,
      consecutiveDays: bonus.consecutiveDays,
      totalBonusPoints: bonus.totalBonusPoints,
      bonusLevel: bonus.bonusLevel.value,
      isClaimedToday: bonus.isClaimedToday,
      createdAtMillis: bonus.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: bonus.updatedAt.millisecondsSinceEpoch,
    );
  }

  LoginBonus toLoginBonus() {
    return LoginBonus(
      id: id,
      userId: userId,
      lastLoginDate: DateTime.fromMillisecondsSinceEpoch(lastLoginDateMillis),
      consecutiveDays: consecutiveDays,
      totalBonusPoints: totalBonusPoints,
      bonusLevel: _parseBonusLevel(bonusLevel),
      isClaimedToday: isClaimedToday,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }
}

BonusLevel _parseBonusLevel(String value) {
  return BonusLevel.values.firstWhere(
    (level) => level.value == value,
    orElse: () => BonusLevel.bronze,
  );
}
