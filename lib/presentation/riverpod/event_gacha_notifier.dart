import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_gacha_model.dart';
import '../../data/repositories/event_gacha_repository.dart';

/// イベントガチャ情報の Notifier
class EventGachaNotifier extends StateNotifier<AsyncValue<EventGacha?>> {
  final EventGachaRepository repository;

  EventGachaNotifier(this.repository) : super(const AsyncValue.loading());

  /// アクティブなイベントを取得
  Future<void> fetchActiveEvent() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getActiveEvent(),
    );
  }

  /// 全イベントを取得
  Future<void> fetchAllEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async {
        final events = await repository.getAllEvents();
        // 最初のイベントを返す（複数イベント対応の場合は別途修正）
        return events.isNotEmpty ? events.first : null;
      },
    );
  }
}

/// イベントスピン結果の Notifier
class EventSpinResultNotifier
    extends StateNotifier<AsyncValue<EventSpinResult?>> {
  final EventGachaRepository repository;

  EventSpinResultNotifier(this.repository)
      : super(const AsyncValue.data(null));

  /// イベントガチャを実行
  Future<EventSpinResult?> performEventSpin(
    String userId,
    String eventId,
    EventGacha event,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result = await repository.performEventSpin(userId, eventId, event);
      state = AsyncValue.data(result);
      return result;
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
