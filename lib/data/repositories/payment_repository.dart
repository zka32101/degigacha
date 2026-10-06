import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

/// 支払い管理リポジトリ
class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// IAP商品を取得
  Future<List<IAPProduct>> getProducts() async {
    try {
      final query = await _firestore
          .collection('iap_products')
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .orderBy('price')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return IAPProduct.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('商品取得に失敗: $e');
    }
  }

  /// カテゴリ別商品を取得
  Future<List<IAPProduct>> getProductsByCategory(String category) async {
    try {
      final query = await _firestore
          .collection('iap_products')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .orderBy('price')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return IAPProduct.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('カテゴリ別商品取得に失敗: $e');
    }
  }

  /// 購入を記録
  Future<String> recordPurchase({
    required String userId,
    required String productId,
    required String productName,
    required int amount,
    required int price,
    String? transactionId,
  }) async {
    try {
      final receiptId = _firestore.collection('receipts').doc().id;

      await _firestore
          .collection('receipts')
          .doc(receiptId)
          .set({
        'receiptId': receiptId,
        'userId': userId,
        'productId': productId,
        'productName': productName,
        'amount': amount,
        'price': price,
        'purchasedAt': Timestamp.now(),
        'status': 'completed',
        'transactionId': transactionId,
        'notes': null,
      });

      // ユーザー残高を更新
      await _updateUserBalance(userId, amount, price);

      return receiptId;
    } catch (e) {
      throw Exception('購入記録に失敗: $e');
    }
  }

  /// ユーザー残高を取得
  Future<UserBalance?> getUserBalance(String userId) async {
    try {
      final doc = await _firestore.collection('user_balances').doc(userId).get();

      if (!doc.exists) {
        return UserBalance(
          userId: userId,
          gemBalance: 0,
          coinBalance: 0,
          totalSpent: 0,
          totalPurchases: 0,
          lastPurchaseAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
      }

      final data = doc.data()!;
      data['userId'] = doc.id;
      return UserBalance.fromJson(data);
    } catch (e) {
      throw Exception('ユーザー残高取得に失敗: $e');
    }
  }

  /// ユーザー残高を更新
  Future<void> _updateUserBalance(String userId, int amount, int price) async {
    try {
      final balance = await getUserBalance(userId);

      if (balance == null) {
        await _firestore
            .collection('user_balances')
            .doc(userId)
            .set({
          'userId': userId,
          'gemBalance': amount,
          'coinBalance': 0,
          'totalSpent': price,
          'totalPurchases': 1,
          'lastPurchaseAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      } else {
        await _firestore
            .collection('user_balances')
            .doc(userId)
            .update({
          'gemBalance': FieldValue.increment(amount),
          'totalSpent': FieldValue.increment(price),
          'totalPurchases': FieldValue.increment(1),
          'lastPurchaseAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('ユーザー残高更新に失敗: $e');
    }
  }

  /// ユーザーのレシート履歴を取得
  Future<List<Receipt>> getUserReceipts(String userId) async {
    try {
      final query = await _firestore
          .collection('receipts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('purchasedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['receiptId'] = doc.id;
        return Receipt.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('レシート履歴取得に失敗: $e');
    }
  }

  /// プロモーションコードを検証
  Future<PromotionCode?> validatePromotionCode(String code) async {
    try {
      final query = await _firestore
          .collection('promotion_codes')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();
      data['codeId'] = doc.id;

      final promo = PromotionCode.fromJson(data);

      // 有効期限をチェック
      final now = DateTime.now();
      if (promo.validFrom.isAfter(now) || promo.validTo.isBefore(now)) {
        return null;
      }

      // 使用回数をチェック
      if (promo.usedCount >= promo.maxUses) {
        return null;
      }

      return promo;
    } catch (e) {
      throw Exception('プロモーションコード検証に失敗: $e');
    }
  }

  /// プロモーションコードを使用
  Future<void> usePromotionCode(String codeId) async {
    try {
      await _firestore
          .collection('promotion_codes')
          .doc(codeId)
          .update({
        'usedCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('プロモーションコード使用に失敗: $e');
    }
  }

  /// サブスクリプションを作成
  Future<String> createSubscription({
    required String userId,
    required String tier,
    required String billingCycle,
  }) async {
    try {
      final subscriptionId = _firestore.collection('subscriptions').doc().id;
      final renewalDate = billingCycle == 'yearly'
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 30));

      final tierData = _getTierData(tier);

      await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .set({
        'subscriptionId': subscriptionId,
        'userId': userId,
        'tier': tier,
        'monthlyPrice': tierData['price'],
        'monthlyGems': tierData['gems'],
        'startDate': Timestamp.now(),
        'renewalDate': Timestamp.fromDate(renewalDate),
        'isActive': true,
        'billingCycle': billingCycle,
      });

      return subscriptionId;
    } catch (e) {
      throw Exception('サブスクリプション作成に失敗: $e');
    }
  }

  /// ユーザーのサブスクリプションを取得
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      final query = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();
      data['subscriptionId'] = doc.id;
      return Subscription.fromJson(data);
    } catch (e) {
      throw Exception('サブスクリプション取得に失敗: $e');
    }
  }

  /// 支払い統計を取得
  Future<PaymentStatistics> getPaymentStatistics() async {
    try {
      final receiptsQuery = await _firestore
          .collection('receipts')
          .where('status', isEqualTo: 'completed')
          .get();

      int totalRevenue = 0;
      final purchasesByProduct = <String, int>{};
      final revenueByCategory = <String, int>{};

      for (final doc in receiptsQuery.docs) {
        final data = doc.data();
        totalRevenue += (data['price'] as int);

        final productId = data['productId'] as String;
        purchasesByProduct[productId] = (purchasesByProduct[productId] ?? 0) + 1;
      }

      // カテゴリ別収益を計算
      final productsQuery = await _firestore
          .collection('iap_products')
          .get();

      for (final productDoc in productsQuery.docs) {
        final productData = productDoc.data();
        final category = productData['category'] as String;
        final productId = productDoc.id;
        final count = purchasesByProduct[productId] ?? 0;
        final price = productData['price'] as int;

        revenueByCategory[category] =
            (revenueByCategory[category] ?? 0) + (count * price);
      }

      // アクティブユーザー数
      final balancesQuery = await _firestore
          .collection('user_balances')
          .where('totalPurchases', isGreaterThan: 0)
          .get();

      return PaymentStatistics(
        totalRevenue: totalRevenue,
        totalPurchases: receiptsQuery.docs.length,
        purchasesByProduct: purchasesByProduct,
        revenueByCategory: revenueByCategory,
        activeUsers: balancesQuery.docs.length,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('支払い統計取得に失敗: $e');
    }
  }

  /// ティアデータを取得
  Map<String, int> _getTierData(String tier) {
    switch (tier) {
      case 'basic':
        return {'price': 400, 'gems': 100};
      case 'premium':
        return {'price': 980, 'gems': 300};
      case 'vip':
        return {'price': 1980, 'gems': 750};
      default:
        return {'price': 400, 'gems': 100};
    }
  }
}
