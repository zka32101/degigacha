import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/marketplace_model.dart';
import '../../data/repositories/marketplace_repository.dart';

/// すべてのリスティング取得Notifier
class AllListingsNotifier extends StateNotifier<AsyncValue<List<MarketListing>>> {
  final MarketplaceRepository _repository;

  AllListingsNotifier({required MarketplaceRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// すべてのリスティングを読み込み
  Future<void> loadListings() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getAllListings(),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getAllListings(),
    );
  }
}

/// レアリティ別リスティング取得Notifier
class RarityListingsNotifier
    extends StateNotifier<AsyncValue<List<MarketListing>>> {
  final MarketplaceRepository _repository;

  RarityListingsNotifier({required MarketplaceRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// レアリティ別リスティングを読み込み
  Future<void> loadListingsByRarity(String rarity) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getListingsByRarity(rarity),
    );
  }

  /// 再読み込み
  Future<void> refresh(String rarity) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getListingsByRarity(rarity),
    );
  }
}

/// シリーズ別リスティング取得Notifier
class SeriesListingsNotifier
    extends StateNotifier<AsyncValue<List<MarketListing>>> {
  final MarketplaceRepository _repository;

  SeriesListingsNotifier({required MarketplaceRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// シリーズ別リスティングを読み込み
  Future<void> loadListingsBySeries(String series) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getListingsBySeries(series),
    );
  }

  /// 再読み込み
  Future<void> refresh(String series) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getListingsBySeries(series),
    );
  }
}

/// セラーのリスティング取得Notifier
class SellerListingsNotifier
    extends StateNotifier<AsyncValue<List<MarketListing>>> {
  final MarketplaceRepository _repository;

  SellerListingsNotifier({required MarketplaceRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// セラーのリスティングを読み込み
  Future<void> loadSellerListings(String sellerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getSellerListings(sellerId),
    );
  }

  /// 再読み込み
  Future<void> refresh(String sellerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getSellerListings(sellerId),
    );
  }
}

/// トランザクション履歴Notifier
class TransactionHistoryNotifier
    extends StateNotifier<AsyncValue<List<MarketTransaction>>> {
  final MarketplaceRepository _repository;

  TransactionHistoryNotifier({required MarketplaceRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// トランザクション履歴を読み込み
  Future<void> loadHistory(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getTransactionHistory(userId),
    );
  }

  /// アイテムを購入
  Future<void> purchaseItem({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required String itemId,
    required String itemName,
    required int quantity,
    required int pricePerUnit,
  }) async {
    try {
      await _repository.purchaseItem(
        listingId: listingId,
        buyerId: buyerId,
        sellerId: sellerId,
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
      );
      await loadHistory(buyerId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 再読み込み
  Future<void> refresh(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getTransactionHistory(userId),
    );
  }
}

/// マーケットプレイス統計Notifier
class MarketplaceStatisticsNotifier
    extends StateNotifier<AsyncValue<MarketplaceStatistics>> {
  final MarketplaceRepository _repository;

  MarketplaceStatisticsNotifier({required MarketplaceRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// 統計を読み込み
  Future<void> loadStatistics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getMarketplaceStatistics(),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getMarketplaceStatistics(),
    );
  }
}
