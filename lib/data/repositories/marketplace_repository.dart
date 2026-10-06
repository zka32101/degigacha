import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_model.dart';

/// マーケットプレイスリポジトリ
class MarketplaceRepository {
  final FirebaseFirestore _firestore;

  MarketplaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// リスティングを作成
  Future<String> createListing({
    required String sellerId,
    required String sellerName,
    required String itemId,
    required String itemName,
    required String series,
    required String rarity,
    required int price,
    required int quantity,
    required String condition,
    String? description,
  }) async {
    try {
      final listingId = _firestore.collection('marketplace_listings').doc().id;
      final expiresAt = DateTime.now().add(const Duration(days: 30));

      await _firestore
          .collection('marketplace_listings')
          .doc(listingId)
          .set({
        'listingId': listingId,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'itemId': itemId,
        'itemName': itemName,
        'series': series,
        'rarity': rarity,
        'price': price,
        'quantity': quantity,
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'condition': condition,
        'description': description,
        'sellerRating': 5.0,
        'soldCount': 0,
      });

      return listingId;
    } catch (e) {
      throw Exception('リスティング作成に失敗: $e');
    }
  }

  /// すべてのリスティングを取得
  Future<List<MarketListing>> getAllListings() async {
    try {
      final query = await _firestore
          .collection('marketplace_listings')
          .where('quantity', isGreaterThan: 0)
          .orderBy('quantity', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['listingId'] = doc.id;
        return MarketListing.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('リスティング取得に失敗: $e');
    }
  }

  /// レアリティで検索
  Future<List<MarketListing>> getListingsByRarity(String rarity) async {
    try {
      final query = await _firestore
          .collection('marketplace_listings')
          .where('rarity', isEqualTo: rarity)
          .where('quantity', isGreaterThan: 0)
          .orderBy('quantity', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['listingId'] = doc.id;
        return MarketListing.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('レアリティ検索に失敗: $e');
    }
  }

  /// シリーズで検索
  Future<List<MarketListing>> getListingsBySeries(String series) async {
    try {
      final query = await _firestore
          .collection('marketplace_listings')
          .where('series', isEqualTo: series)
          .where('quantity', isGreaterThan: 0)
          .orderBy('quantity', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['listingId'] = doc.id;
        return MarketListing.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('シリーズ検索に失敗: $e');
    }
  }

  /// セラーのリスティングを取得
  Future<List<MarketListing>> getSellerListings(String sellerId) async {
    try {
      final query = await _firestore
          .collection('marketplace_listings')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['listingId'] = doc.id;
        return MarketListing.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('セラーリスティング取得に失敗: $e');
    }
  }

  /// リスティングを購入
  Future<String> purchaseItem({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required String itemId,
    required String itemName,
    required int quantity,
    required int pricePerUnit,
  }) async {
    try {
      final transactionId = _firestore.collection('marketplace_transactions').doc().id;
      final totalPrice = pricePerUnit * quantity;

      await _firestore
          .collection('marketplace_transactions')
          .doc(transactionId)
          .set({
        'transactionId': transactionId,
        'listingId': listingId,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
        'totalPrice': totalPrice,
        'purchasedAt': Timestamp.now(),
        'status': 'completed',
        'buyerReview': null,
        'sellerReview': null,
      });

      // リスティングの数量を更新
      await _firestore
          .collection('marketplace_listings')
          .doc(listingId)
          .update({
        'quantity': FieldValue.increment(-quantity),
        'soldCount': FieldValue.increment(1),
      });

      return transactionId;
    } catch (e) {
      throw Exception('購入に失敗: $e');
    }
  }

  /// トランザクション履歴を取得
  Future<List<MarketTransaction>> getTransactionHistory(String userId) async {
    try {
      // バイヤーとしての履歴
      final buyerQuery = await _firestore
          .collection('marketplace_transactions')
          .where('buyerId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      // セラーとしての履歴
      final sellerQuery = await _firestore
          .collection('marketplace_transactions')
          .where('sellerId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      final results = <MarketTransaction>[];

      for (final doc in buyerQuery.docs) {
        final data = doc.data();
        data['transactionId'] = doc.id;
        results.add(MarketTransaction.fromJson(data));
      }

      for (final doc in sellerQuery.docs) {
        final data = doc.data();
        data['transactionId'] = doc.id;
        results.add(MarketTransaction.fromJson(data));
      }

      results.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

      return results;
    } catch (e) {
      throw Exception('トランザクション履歴取得に失敗: $e');
    }
  }

  /// セラー評価を追加
  Future<void> addSellerRating({
    required String sellerId,
    required String buyerId,
    required int rating,
    required String comment,
    required String reviewType,
  }) async {
    try {
      final ratingId = _firestore.collection('seller_ratings').doc().id;

      await _firestore
          .collection('seller_ratings')
          .doc(ratingId)
          .set({
        'ratingId': ratingId,
        'sellerId': sellerId,
        'buyerId': buyerId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
        'reviewType': reviewType,
      });

      // セラーの平均評価を更新
      await _updateSellerRating(sellerId);
    } catch (e) {
      throw Exception('評価追加に失敗: $e');
    }
  }

  /// セラーの平均評価を計算して更新
  Future<void> _updateSellerRating(String sellerId) async {
    try {
      final ratingsQuery = await _firestore
          .collection('seller_ratings')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      if (ratingsQuery.docs.isEmpty) {
        return;
      }

      final avgRating = ratingsQuery.docs
              .map((doc) => doc['rating'] as int)
              .reduce((a, b) => a + b) /
          ratingsQuery.docs.length;

      // セラーのリスティングの平均評価を更新
      final listingsQuery = await _firestore
          .collection('marketplace_listings')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      for (final doc in listingsQuery.docs) {
        await doc.reference.update({
          'sellerRating': avgRating,
        });
      }
    } catch (e) {
      throw Exception('セラー評価更新に失敗: $e');
    }
  }

  /// マーケットプレイス統計を取得
  Future<MarketplaceStatistics> getMarketplaceStatistics() async {
    try {
      final listingsQuery = await _firestore
          .collection('marketplace_listings')
          .where('quantity', isGreaterThan: 0)
          .get();

      final transactionsQuery =
          await _firestore.collection('marketplace_transactions').get();

      final listingsByRarity = <String, int>{};
      final listingsBySeries = <String, int>{};
      final totalPriceByRarity = <String, int>{};
      final countByRarity = <String, int>{};
      final totalPriceBySeries = <String, int>{};
      final countBySeries = <String, int>{};

      for (final doc in listingsQuery.docs) {
        final data = doc.data();
        final rarity = data['rarity'] as String;
        final series = data['series'] as String;
        final price = data['price'] as int;

        listingsByRarity[rarity] = (listingsByRarity[rarity] ?? 0) + 1;
        listingsBySeries[series] = (listingsBySeries[series] ?? 0) + 1;

        totalPriceByRarity[rarity] = (totalPriceByRarity[rarity] ?? 0) + price;
        countByRarity[rarity] = (countByRarity[rarity] ?? 0) + 1;

        totalPriceBySeries[series] = (totalPriceBySeries[series] ?? 0) + price;
        countBySeries[series] = (countBySeries[series] ?? 0) + 1;
      }

      final avgPriceByRarity = <String, double>{};
      for (final rarity in totalPriceByRarity.keys) {
        avgPriceByRarity[rarity] =
            totalPriceByRarity[rarity]! / countByRarity[rarity]!;
      }

      return MarketplaceStatistics(
        totalListings: listingsQuery.docs.length,
        totalTransactions: transactionsQuery.docs.length,
        listingsByRarity: listingsByRarity,
        listingsBySeries: listingsBySeries,
        avgPriceByRarity: avgPriceByRarity,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('統計取得に失敗: $e');
    }
  }

  /// リスティングを削除（取り下げ）
  Future<void> delisting(String listingId) async {
    try {
      await _firestore
          .collection('marketplace_listings')
          .doc(listingId)
          .delete();
    } catch (e) {
      throw Exception('リスティング削除に失敗: $e');
    }
  }
}
