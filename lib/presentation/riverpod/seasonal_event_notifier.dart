import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/seasonal_event_model.dart';
import '../../data/repositories/seasonal_event_repository.dart';

/// シーズナルイベント Notifier
class SeasonalEventNotifier extends StateNotifier<AsyncValue<SeasonalEvent?>> {
  final SeasonalEventRepository repository;

  SeasonalEventNotifier(this.repository) : super(const AsyncValue.loading());

  /// 現在進行中のイベントを取得
  Future<void> fetchCurrentEvent() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getCurrentEvent(),
    );
  }

  /// すべてのイベントを取得
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

  /// 特定の ID でイベントを取得
  Future<void> fetchEventById(String eventId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getEventById(eventId),
    );
  }

  /// 現在進行中のイベント一覧を取得
  Future<void> fetchRunningEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async {
        final events = await repository.getRunningEvents();
        // 最初のイベントを返す（複数イベント対応の場合は別途修正）
        return events.isNotEmpty ? events.first : null;
      },
    );
  }
}

/// シーズナルイベント一覧 Notifier
class SeasonalEventListNotifier extends StateNotifier<AsyncValue<List<SeasonalEvent>>> {
  final SeasonalEventRepository repository;

  SeasonalEventListNotifier(this.repository) : super(const AsyncValue.loading());

  /// すべてのイベント一覧を取得
  Future<void> fetchAllEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getAllEvents(),
    );
  }

  /// イベントタイプ別に取得
  Future<void> fetchEventsByType(String eventType) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getEventsByType(eventType),
    );
  }

  /// 実行中のイベント一覧を取得
  Future<void> fetchRunningEvents() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.getRunningEvents(),
    );
  }
}
