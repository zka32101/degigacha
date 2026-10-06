import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

/// アプリ内課金商品
@freezed
class IAPProduct with _$IAPProduct {
  const factory IAPProduct({
    required String productId,
    required String name,
    required String description,
    required int price, // 金額（円）
    required int amount, // 付与ポイント数
    required bool isActive,
    required String category, // gem, coin, bundle
    String? imageUrl,
    String? tag, // sale, new, popular など
    required DateTime createdAt,
  }) = _IAPProduct;

  factory IAPProduct.fromJson(Map<String, dynamic> json) =>
      _$IAPProductFromJson(json);
}

/// レシート・購入履歴
@freezed
class Receipt with _$Receipt {
  const factory Receipt({
    required String receiptId,
    required String userId,
    required String productId,
    required String productName,
    required int amount, // 付与ポイント数
    required int price,
    required DateTime purchasedAt,
    required String status, // completed, pending, failed, refunded
    String? transactionId,
    String? notes,
  }) = _Receipt;

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);
}

/// ユーザー残高
@freezed
class UserBalance with _$UserBalance {
  const factory UserBalance({
    required String userId,
    required int gemBalance, // プレミアムポイント
    required int coinBalance, // ゲーム内通貨
    required int totalSpent, // 総支出金額
    required int totalPurchases, // 購入回数
    required DateTime lastPurchaseAt,
    required DateTime lastUpdated,
  }) = _UserBalance;

  factory UserBalance.fromJson(Map<String, dynamic> json) =>
      _$UserBalanceFromJson(json);
}

/// 支払い統計
@freezed
class PaymentStatistics with _$PaymentStatistics {
  const factory PaymentStatistics({
    required int totalRevenue,
    required int totalPurchases,
    required Map<String, int> purchasesByProduct,
    required Map<String, int> revenueByCategory,
    required int activeUsers,
    required DateTime lastUpdated,
  }) = _PaymentStatistics;

  factory PaymentStatistics.fromJson(Map<String, dynamic> json) =>
      _$PaymentStatisticsFromJson(json);
}

/// 割引・キャンペーン
@freezed
class PromotionCode with _$PromotionCode {
  const factory PromotionCode({
    required String codeId,
    required String code,
    required String description,
    required int discountPercent, // 割引率 (0-100)
    required DateTime validFrom,
    required DateTime validTo,
    required int maxUses,
    required int usedCount,
    required bool isActive,
    List<String>? applicableProducts, // null = すべて
  }) = _PromotionCode;

  factory PromotionCode.fromJson(Map<String, dynamic> json) =>
      _$PromotionCodeFromJson(json);
}

/// サブスクリプション
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String subscriptionId,
    required String userId,
    required String tier, // basic, premium, vip
    required int monthlyPrice,
    required int monthlyGems,
    required DateTime startDate,
    required DateTime renewalDate,
    required bool isActive,
    required String billingCycle, // monthly, yearly
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}

extension IAPProductExtension on IAPProduct {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'price': price,
      'amount': amount,
      'isActive': isActive,
      'category': category,
      'imageUrl': imageUrl,
      'tag': tag,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// DTOから変換
  static IAPProduct fromDTO(Map<String, dynamic> dto) {
    return IAPProduct(
      productId: dto['productId'] as String,
      name: dto['name'] as String,
      description: dto['description'] as String,
      price: dto['price'] as int,
      amount: dto['amount'] as int,
      isActive: dto['isActive'] as bool,
      category: dto['category'] as String,
      imageUrl: dto['imageUrl'] as String?,
      tag: dto['tag'] as String?,
      createdAt: (dto['createdAt'] as Timestamp).toDate(),
    );
  }
}

extension ReceiptExtension on Receipt {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'receiptId': receiptId,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'amount': amount,
      'price': price,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'status': status,
      'transactionId': transactionId,
      'notes': notes,
    };
  }

  /// DTOから変換
  static Receipt fromDTO(Map<String, dynamic> dto) {
    return Receipt(
      receiptId: dto['receiptId'] as String,
      userId: dto['userId'] as String,
      productId: dto['productId'] as String,
      productName: dto['productName'] as String,
      amount: dto['amount'] as int,
      price: dto['price'] as int,
      purchasedAt: (dto['purchasedAt'] as Timestamp).toDate(),
      status: dto['status'] as String,
      transactionId: dto['transactionId'] as String?,
      notes: dto['notes'] as String?,
    );
  }
}

extension UserBalanceExtension on UserBalance {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'userId': userId,
      'gemBalance': gemBalance,
      'coinBalance': coinBalance,
      'totalSpent': totalSpent,
      'totalPurchases': totalPurchases,
      'lastPurchaseAt': Timestamp.fromDate(lastPurchaseAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// DTOから変換
  static UserBalance fromDTO(Map<String, dynamic> dto) {
    return UserBalance(
      userId: dto['userId'] as String,
      gemBalance: dto['gemBalance'] as int,
      coinBalance: dto['coinBalance'] as int,
      totalSpent: dto['totalSpent'] as int,
      totalPurchases: dto['totalPurchases'] as int,
      lastPurchaseAt: (dto['lastPurchaseAt'] as Timestamp).toDate(),
      lastUpdated: (dto['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
