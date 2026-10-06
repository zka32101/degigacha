import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';

/// IAP商品一覧Notifier
class IAPProductsNotifier extends StateNotifier<AsyncValue<List<IAPProduct>>> {
  final PaymentRepository _repository;

  IAPProductsNotifier({required PaymentRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// 商品を読み込み
  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getProducts(),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getProducts(),
    );
  }
}

/// カテゴリ別商品Notifier
class CategoryProductsNotifier
    extends StateNotifier<AsyncValue<List<IAPProduct>>> {
  final PaymentRepository _repository;

  CategoryProductsNotifier({required PaymentRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// カテゴリ別商品を読み込み
  Future<void> loadProductsByCategory(String category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getProductsByCategory(category),
    );
  }

  /// 再読み込み
  Future<void> refresh(String category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getProductsByCategory(category),
    );
  }
}

/// ユーザー残高Notifier
class UserBalanceNotifier extends StateNotifier<AsyncValue<UserBalance?>> {
  final PaymentRepository _repository;

  UserBalanceNotifier({required PaymentRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// ユーザー残高を読み込み
  Future<void> loadBalance(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getUserBalance(userId),
    );
  }

  /// 購入処理
  Future<void> purchase({
    required String userId,
    required String productId,
    required String productName,
    required int amount,
    required int price,
    String? transactionId,
  }) async {
    try {
      await _repository.recordPurchase(
        userId: userId,
        productId: productId,
        productName: productName,
        amount: amount,
        price: price,
        transactionId: transactionId,
      );
      await loadBalance(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 再読み込み
  Future<void> refresh(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getUserBalance(userId),
    );
  }
}

/// レシート履歴Notifier
class ReceiptHistoryNotifier
    extends StateNotifier<AsyncValue<List<Receipt>>> {
  final PaymentRepository _repository;

  ReceiptHistoryNotifier({required PaymentRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// レシート履歴を読み込み
  Future<void> loadReceipts(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getUserReceipts(userId),
    );
  }

  /// 再読み込み
  Future<void> refresh(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getUserReceipts(userId),
    );
  }
}

/// 支払い統計Notifier
class PaymentStatisticsNotifier
    extends StateNotifier<AsyncValue<PaymentStatistics>> {
  final PaymentRepository _repository;

  PaymentStatisticsNotifier({required PaymentRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// 統計を読み込み
  Future<void> loadStatistics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getPaymentStatistics(),
    );
  }

  /// 再読み込み
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getPaymentStatistics(),
    );
  }
}

/// プロモーションコードNotifier
class PromotionCodeNotifier extends StateNotifier<AsyncValue<PromotionCode?>> {
  final PaymentRepository _repository;

  PromotionCodeNotifier({required PaymentRepository repository})
      : _repository = repository,
        super(const AsyncValue.data(null));

  /// プロモーションコードを検証
  Future<void> validateCode(String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.validatePromotionCode(code),
    );
  }

  /// プロモーションコードをリセット
  void resetCode() {
    state = const AsyncValue.data(null);
  }
}

/// サブスクリプションNotifier
class SubscriptionNotifier
    extends StateNotifier<AsyncValue<Subscription?>> {
  final PaymentRepository _repository;

  SubscriptionNotifier({required PaymentRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading());

  /// ユーザーのサブスクリプションを読み込み
  Future<void> loadSubscription(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getUserSubscription(userId),
    );
  }

  /// サブスクリプションを作成
  Future<void> subscribe({
    required String userId,
    required String tier,
    required String billingCycle,
  }) async {
    try {
      await _repository.createSubscription(
        userId: userId,
        tier: tier,
        billingCycle: billingCycle,
      );
      await loadSubscription(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// 再読み込み
  Future<void> refresh(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getUserSubscription(userId),
    );
  }
}
