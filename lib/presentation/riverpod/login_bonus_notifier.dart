import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/login_bonus_model.dart';
import '../../data/repositories/login_bonus_repository.dart';

/// ログインボーナス情報の Notifier
class LoginBonusNotifier extends StateNotifier<AsyncValue<LoginBonus?>> {
  final LoginBonusRepository repository;

  LoginBonusNotifier(this.repository) : super(const AsyncValue.loading());

  /// ユーザーのログインボーナス情報を取得
  Future<void> fetchLoginBonus(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getLoginBonus(userId),
    );
  }

  /// ログインボーナスを請求
  Future<LoginBonus?> claimBonus(String userId) async {
    state = const AsyncValue.loading();
    try {
      final bonus = await repository.claimLoginBonus(userId);
      state = AsyncValue.data(bonus);
      return bonus;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// 日次リセット
  Future<void> resetDaily(String userId) async {
    try {
      await repository.resetDailyClaim(userId);
      await fetchLoginBonus(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
