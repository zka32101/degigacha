import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'marketplace_model.freezed.dart';
part 'marketplace_model.g.dart';

/// マーケットリスティング
@freezed
class MarketListing with _$MarketListing {
  const factory MarketListing({
    required String listingId,
    required String sellerId,
    required String sellerName,
    required String itemId,
    required String itemName,
    required String series,
    required String rarity,
    required int price,
    required int quantity,
    required DateTime createdAt,
    required DateTime expiresAt,
    required String condition, // new, good, acceptable
    String? description,
    required double sellerRating,
    required int soldCount,
  }) = _MarketListing;

  factory MarketListing.fromJson(Map<String, dynamic> json) =>
      _$MarketListingFromJson(json);
}

/// マーケットトランザクション
@freezed
class MarketTransaction with _$MarketTransaction {
  const factory MarketTransaction({
    required String transactionId,
    required String listingId,
    required String buyerId,
    required String sellerId,
    required String itemId,
    required String itemName,
    required int quantity,
    required int pricePerUnit,
    required int totalPrice,
    required DateTime purchasedAt,
    required String status, // completed, pending, cancelled
    String? buyerReview,
    String? sellerReview,
  }) = _MarketTransaction;

  factory MarketTransaction.fromJson(Map<String, dynamic> json) =>
      _$MarketTransactionFromJson(json);
}

/// セラー評価
@freezed
class SellerRating with _$SellerRating {
  const factory SellerRating({
    required String ratingId,
    required String sellerId,
    required String buyerId,
    required int rating, // 1-5
    required String comment,
    required DateTime createdAt,
    required String reviewType, // positive, neutral, negative
  }) = _SellerRating;

  factory SellerRating.fromJson(Map<String, dynamic> json) =>
      _$SellerRatingFromJson(json);
}

/// マーケット統計
@freezed
class MarketplaceStatistics with _$MarketplaceStatistics {
  const factory MarketplaceStatistics({
    required int totalListings,
    required int totalTransactions,
    required Map<String, int> listingsByRarity,
    required Map<String, int> listingsBySeries,
    required Map<String, double> avgPriceByRarity,
    required DateTime lastUpdated,
  }) = _MarketplaceStatistics;

  factory MarketplaceStatistics.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceStatisticsFromJson(json);
}

extension MarketListingExtension on MarketListing {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'itemId': itemId,
      'itemName': itemName,
      'series': series,
      'rarity': rarity,
      'price': price,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'condition': condition,
      'description': description,
      'sellerRating': sellerRating,
      'soldCount': soldCount,
    };
  }

  /// DTOから変換
  static MarketListing fromDTO(Map<String, dynamic> dto) {
    return MarketListing(
      listingId: dto['listingId'] as String,
      sellerId: dto['sellerId'] as String,
      sellerName: dto['sellerName'] as String,
      itemId: dto['itemId'] as String,
      itemName: dto['itemName'] as String,
      series: dto['series'] as String,
      rarity: dto['rarity'] as String,
      price: dto['price'] as int,
      quantity: dto['quantity'] as int,
      createdAt: (dto['createdAt'] as Timestamp).toDate(),
      expiresAt: (dto['expiresAt'] as Timestamp).toDate(),
      condition: dto['condition'] as String,
      description: dto['description'] as String?,
      sellerRating: (dto['sellerRating'] as num).toDouble(),
      soldCount: dto['soldCount'] as int,
    );
  }
}

extension MarketTransactionExtension on MarketTransaction {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'transactionId': transactionId,
      'listingId': listingId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'status': status,
      'buyerReview': buyerReview,
      'sellerReview': sellerReview,
    };
  }

  /// DTOから変換
  static MarketTransaction fromDTO(Map<String, dynamic> dto) {
    return MarketTransaction(
      transactionId: dto['transactionId'] as String,
      listingId: dto['listingId'] as String,
      buyerId: dto['buyerId'] as String,
      sellerId: dto['sellerId'] as String,
      itemId: dto['itemId'] as String,
      itemName: dto['itemName'] as String,
      quantity: dto['quantity'] as int,
      pricePerUnit: dto['pricePerUnit'] as int,
      totalPrice: dto['totalPrice'] as int,
      purchasedAt: (dto['purchasedAt'] as Timestamp).toDate(),
      status: dto['status'] as String,
      buyerReview: dto['buyerReview'] as String?,
      sellerReview: dto['sellerReview'] as String?,
    );
  }
}

extension SellerRatingExtension on SellerRating {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'ratingId': ratingId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewType': reviewType,
    };
  }

  /// DTOから変換
  static SellerRating fromDTO(Map<String, dynamic> dto) {
    return SellerRating(
      ratingId: dto['ratingId'] as String,
      sellerId: dto['sellerId'] as String,
      buyerId: dto['buyerId'] as String,
      rating: dto['rating'] as int,
      comment: dto['comment'] as String,
      createdAt: (dto['createdAt'] as Timestamp).toDate(),
      reviewType: dto['reviewType'] as String,
    );
  }
}
