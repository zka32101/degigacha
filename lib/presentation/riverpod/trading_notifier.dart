import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trading_model.dart';
import '../../data/repositories/trading_repository.dart';

/// 受け取ったトレード要求Notifier
class ReceivedTradeRequestsNotifier
    extends StateNotifier<AsyncValue<List<TradeRequest>>> {
  final TradingRepository _repository;
  final String _userId;

  ReceivedTradeRequestsNotifier({
    required TradingRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// 受け取ったトレード要求を読み込み
  Future<void> loadRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getReceivedTradeRequests(_userId),
    );
  }

  /// トレード要求を承認
  Future<void> acceptRequest(String requestId) async {
    try {
      await _repository.acceptTradeRequest(requestId);
      await loadRequests();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// トレード要求を却下
  Future<void> rejectRequest(String requestId) async {
    try {
      await _repository.rejectTradeRequest(requestId);
      await loadRequests();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getReceivedTradeRequests(_userId),
    );
  }
}

/// 送信したトレード要求Notifier
class SentTradeRequestsNotifier
    extends StateNotifier<AsyncValue<List<TradeRequest>>> {
  final TradingRepository _repository;
  final String _userId;

  SentTradeRequestsNotifier({
    required TradingRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// 送信したトレード要求を読み込み
  Future<void> loadRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getSentTradeRequests(_userId),
    );
  }

  /// トレード要求をキャンセル
  Future<void> cancelRequest(String requestId) async {
    try {
      await _repository.cancelTradeRequest(requestId);
      await loadRequests();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getSentTradeRequests(_userId),
    );
  }
}

/// トレード履歴Notifier
class TradeHistoryNotifier
    extends StateNotifier<AsyncValue<List<TradeHistory>>> {
  final TradingRepository _repository;
  final String _userId;

  TradeHistoryNotifier({
    required TradingRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// トレード履歴を読み込み
  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getTradeHistory(_userId),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getTradeHistory(_userId),
    );
  }
}

/// トレード統計Notifier
class TradeStatisticsNotifier
    extends StateNotifier<AsyncValue<TradeStatistics>> {
  final TradingRepository _repository;
  final String _userId;

  TradeStatisticsNotifier({
    required TradingRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// トレード統計を読み込み
  Future<void> loadStatistics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getTradeStatistics(_userId),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getTradeStatistics(_userId),
    );
  }
}

/// トレード提案Notifier
class TradeSuggestionsNotifier
    extends StateNotifier<AsyncValue<List<TradeSuggestion>>> {
  final TradingRepository _repository;
  final String _userId;

  TradeSuggestionsNotifier({
    required TradingRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// トレード提案を生成（モック実装）
  Future<void> generateSuggestions(
    String itemId,
    List<String> otherItemIds,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.generateTradeSuggestions(_userId, itemId, otherItemIds),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    // 提案は自動生成なのでリセット
    state = const AsyncValue.data([]);
  }
}
