import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/login_bonus_model.dart';

/// ログインボーナス情報のリポジトリ
class LoginBonusRepository {
  final FirebaseFirestore _firestore;

  LoginBonusRepository(this._firestore);

  /// ユーザーのログインボーナス情報を取得
  Future<LoginBonus?> getLoginBonus(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loginBonus')
          .doc('current')
          .get();

      if (!snapshot.exists) {
        return null;
      }

      return LoginBonusDTO.fromJson(snapshot.data() as Map<String, dynamic>)
          .toLoginBonus();
    } catch (e) {
      throw Exception('ログインボーナス情報の取得に失敗しました: $e');
    }
  }

  /// ログインボーナス情報を作成または更新
  Future<LoginBonus> upsertLoginBonus(LoginBonus bonus) async {
    try {
      final dto = LoginBonusDTO.fromLoginBonus(bonus);
      await _firestore
          .collection('users')
          .doc(bonus.userId)
          .collection('loginBonus')
          .doc('current')
          .set(dto.toJson());

      return bonus;
    } catch (e) {
      throw Exception('ログインボーナス情報の更新に失敗しました: $e');
    }
  }

  /// ユーザーがログインしたときにボーナスを請求する
  Future<LoginBonus> claimLoginBonus(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 既存のログインボーナス情報を取得
      var bonus = await getLoginBonus(userId);

      if (bonus == null) {
        // 初めてのログインの場合
        bonus = LoginBonus(
          id: 'login_bonus_$userId',
          userId: userId,
          lastLoginDate: today,
          consecutiveDays: 1,
          totalBonusPoints: BonusLevel.bronze.bonusPoints,
          bonusLevel: BonusLevel.bronze,
          isClaimedToday: true,
          createdAt: now,
          updatedAt: now,
        );
      } else {
        final lastLogin =
            DateTime(bonus.lastLoginDate.year, bonus.lastLoginDate.month, bonus.lastLoginDate.day);

        // 既に本日請求済みの場合
        if (bonus.isClaimedToday) {
          return bonus;
        }

        // 連続ログイン日数を計算
        final daysDifference = today.difference(lastLogin).inDays;
        int newConsecutiveDays = bonus.consecutiveDays;

        // 1日連続している場合
        if (daysDifference == 1) {
          newConsecutiveDays = bonus.consecutiveDays + 1;
        } else if (daysDifference > 1) {
          // ログインが途切れた場合はリセット
          newConsecutiveDays = 1;
        }

        // ボーナスレベルを計算
        final newBonusLevel = BonusLevel.fromConsecutiveDays(newConsecutiveDays);
        final bonusPoints = newBonusLevel.bonusPoints;

        bonus = bonus.copyWith(
          lastLoginDate: today,
          consecutiveDays: newConsecutiveDays,
          totalBonusPoints: bonus.totalBonusPoints + bonusPoints,
          bonusLevel: newBonusLevel,
          isClaimedToday: true,
          updatedAt: now,
        );
      }

      await upsertLoginBonus(bonus);
      return bonus;
    } catch (e) {
      throw Exception('ログインボーナスの請求に失敗しました: $e');
    }
  }

  /// 日付が変わったときに isClaimedToday をリセット
  Future<void> resetDailyClaim(String userId) async {
    try {
      final bonus = await getLoginBonus(userId);
      if (bonus != null) {
        await upsertLoginBonus(
          bonus.copyWith(isClaimedToday: false),
        );
      }
    } catch (e) {
      throw Exception('日次リセットに失敗しました: $e');
    }
  }
}
