import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/duplicate_management_model.dart';
import '../../data/repositories/duplicate_management_repository.dart';

/// 重複検出Notifier
class DuplicateDetectionNotifier
    extends StateNotifier<AsyncValue<List<DuplicateItem>>> {
  final DuplicateManagementRepository _repository;
  final String _userId;

  DuplicateDetectionNotifier({
    required DuplicateManagementRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// 重複を検出
  Future<void> detectDuplicates() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.detectDuplicates(_userId));
  }

  /// 重複を再検出
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.detectDuplicates(_userId));
  }
}

/// 重複統計Notifier
class DuplicateStatisticsNotifier
    extends StateNotifier<AsyncValue<DuplicateStatistics>> {
  final DuplicateManagementRepository _repository;
  final String _userId;

  DuplicateStatisticsNotifier({
    required DuplicateManagementRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// 統計情報を取得
  Future<void> loadStatistics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getDuplicateStatistics(_userId),
    );
  }

  /// 統計情報を再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getDuplicateStatistics(_userId),
    );
  }
}

/// シリーズ別重複Notifier
class SeriesDuplicatesNotifier
    extends StateNotifier<AsyncValue<List<DuplicateItem>>> {
  final DuplicateManagementRepository _repository;
  final String _userId;
  final String _seriesId;

  SeriesDuplicatesNotifier({
    required DuplicateManagementRepository repository,
    required String userId,
    required String seriesId,
  })  : _repository = repository,
        _userId = userId,
        _seriesId = seriesId,
        super(const AsyncValue.loading());

  /// シリーズ別重複を取得
  Future<void> loadDuplicates() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () =>
          _repository.getDuplicatesBySeriesId(_userId, _seriesId),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () =>
          _repository.getDuplicatesBySeriesId(_userId, _seriesId),
    );
  }
}

/// レアリティ別重複Notifier
class RarityDuplicatesNotifier
    extends StateNotifier<AsyncValue<List<DuplicateItem>>> {
  final DuplicateManagementRepository _repository;
  final String _userId;
  final String _rarity;

  RarityDuplicatesNotifier({
    required DuplicateManagementRepository repository,
    required String userId,
    required String rarity,
  })  : _repository = repository,
        _userId = userId,
        _rarity = rarity,
        super(const AsyncValue.loading());

  /// レアリティ別重複を取得
  Future<void> loadDuplicates() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getDuplicatesByRarity(_userId, _rarity),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getDuplicatesByRarity(_userId, _rarity),
    );
  }
}

/// 受取交換リクエストNotifier
class ReceivedExchangeRequestsNotifier
    extends StateNotifier<AsyncValue<List<DuplicateExchangeRequest>>> {
  final DuplicateManagementRepository _repository;
  final String _userId;

  ReceivedExchangeRequestsNotifier({
    required DuplicateManagementRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// 受取リクエストを取得
  Future<void> loadRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getReceivedExchangeRequests(_userId),
    );
  }

  /// 交換リクエストを承認
  Future<void> acceptRequest(String requestId) async {
    try {
      await _repository.acceptExchangeRequest(requestId);
      await loadRequests(); // 再読み込み
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 交換リクエストをキャンセル
  Future<void> cancelRequest(String requestId) async {
    try {
      await _repository.cancelExchangeRequest(requestId);
      await loadRequests(); // 再読み込み
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getReceivedExchangeRequests(_userId),
    );
  }
}

/// 送信交換リクエストNotifier
class SentExchangeRequestsNotifier
    extends StateNotifier<AsyncValue<List<DuplicateExchangeRequest>>> {
  final DuplicateManagementRepository _repository;
  final String _userId;

  SentExchangeRequestsNotifier({
    required DuplicateManagementRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  /// 送信リクエストを取得
  Future<void> loadRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getSentExchangeRequests(_userId),
    );
  }

  /// 交換リクエストをキャンセル
  Future<void> cancelRequest(String requestId) async {
    try {
      await _repository.cancelExchangeRequest(requestId);
      await loadRequests(); // 再読み込み
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getSentExchangeRequests(_userId),
    );
  }
}
