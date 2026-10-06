import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_spin_model.dart';
import '../../data/repositories/daily_spin_repository.dart';

/// 日次スピン情報の Notifier
class DailySpinNotifier extends StateNotifier<AsyncValue<DailySpin?>> {
  final DailySpinRepository repository;

  DailySpinNotifier(this.repository) : super(const AsyncValue.loading());

  /// ユーザーの日次スピン情報を取得
  Future<void> fetchDailySpin(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getDailySpin(userId),
    );
  }

  /// スピンを実行
  Future<SpinResult?> performSpin(String userId) async {
    state = const AsyncValue.loading();
    try {
      final result = await repository.performSpin(userId);
      // スピン後の最新情報を取得
      final spin = await repository.getDailySpin(userId);
      state = AsyncValue.data(spin);
      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// 日次リセット
  Future<void> resetDaily(String userId) async {
    try {
      await repository.resetDailySpins(userId);
      await fetchDailySpin(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
