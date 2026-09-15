import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'trading_model.freezed.dart';
part 'trading_model.g.dart';

/// トレード要求
@freezed
class TradeRequest with _$TradeRequest {
  const factory TradeRequest({
    required String requestId,
    required String fromUserId,
    required String toUserId,
    required String offeredItemId,
    required String requestedItemId,
    required String status, // pending, accepted, completed, rejected, cancelled
    required DateTime createdAt,
    required DateTime? completedAt,
    String? message,
  }) = _TradeRequest;

  factory TradeRequest.fromJson(Map<String, dynamic> json) =>
      _$TradeRequestFromJson(json);
}

/// トレードマッチング結果
@freezed
class TradeMatch with _$TradeMatch {
  const factory TradeMatch({
    required String matchId,
    required String userId1,
    required String userId2,
    required String item1Id,
    required String item2Id,
    required String item1Name,
    required String item2Name,
    required String item1Rarity,
    required String item2Rarity,
    required double matchScore, // 0.0 - 1.0
    required DateTime matchedAt,
    required bool isAcceptedByUser1,
    required bool isAcceptedByUser2,
  }) = _TradeMatch;

  factory TradeMatch.fromJson(Map<String, dynamic> json) =>
      _$TradeMatchFromJson(json);
}

/// トレード履歴
@freezed
class TradeHistory with _$TradeHistory {
  const factory TradeHistory({
    required String tradeId,
    required String userId1,
    required String userId2,
    required String item1Id,
    required String item2Id,
    required String item1Name,
    required String item2Name,
    required String item1Rarity,
    required String item2Rarity,
    required DateTime completedAt,
    required String reason, // normal, cancelled, declined
    String? notes,
  }) = _TradeHistory;

  factory TradeHistory.fromJson(Map<String, dynamic> json) =>
      _$TradeHistoryFromJson(json);
}

/// トレード統計
@freezed
class TradeStatistics with _$TradeStatistics {
  const factory TradeStatistics({
    required int completedTrades,
    required int pendingTrades,
    required int totalItemsTraded,
    required Map<String, int> tradesByRarity,
    required List<String> favoriteTradePartners,
    required DateTime lastUpdated,
  }) = _TradeStatistics;

  factory TradeStatistics.fromJson(Map<String, dynamic> json) =>
      _$TradeStatisticsFromJson(json);
}

/// トレード提案
@freezed
class TradeSuggestion with _$TradeSuggestion {
  const factory TradeSuggestion({
    required String suggestionId,
    required String fromUserId,
    required String toUserId,
    required String offeredItemId,
    required List<String> requestedItemOptions,
    required String status, // pending, accepted, rejected, expired
    required DateTime createdAt,
    required DateTime expiresAt,
    required double confidence,
    String? reason,
  }) = _TradeSuggestion;

  factory TradeSuggestion.fromJson(Map<String, dynamic> json) =>
      _$TradeSuggestionFromJson(json);
}

extension TradeRequestExtension on TradeRequest {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'requestId': requestId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'offeredItemId': offeredItemId,
      'requestedItemId': requestedItemId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'message': message,
    };
  }

  /// DTOから変換
  static TradeRequest fromDTO(Map<String, dynamic> dto) {
    return TradeRequest(
      requestId: dto['requestId'] as String,
      fromUserId: dto['fromUserId'] as String,
      toUserId: dto['toUserId'] as String,
      offeredItemId: dto['offeredItemId'] as String,
      requestedItemId: dto['requestedItemId'] as String,
      status: dto['status'] as String,
      createdAt: (dto['createdAt'] as Timestamp).toDate(),
      completedAt: dto['completedAt'] != null
          ? (dto['completedAt'] as Timestamp).toDate()
          : null,
      message: dto['message'] as String?,
    );
  }
}

extension TradeHistoryExtension on TradeHistory {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'tradeId': tradeId,
      'userId1': userId1,
      'userId2': userId2,
      'item1Id': item1Id,
      'item2Id': item2Id,
      'item1Name': item1Name,
      'item2Name': item2Name,
      'item1Rarity': item1Rarity,
      'item2Rarity': item2Rarity,
      'completedAt': Timestamp.fromDate(completedAt),
      'reason': reason,
      'notes': notes,
    };
  }

  /// DTOから変換
  static TradeHistory fromDTO(Map<String, dynamic> dto) {
    return TradeHistory(
      tradeId: dto['tradeId'] as String,
      userId1: dto['userId1'] as String,
      userId2: dto['userId2'] as String,
      item1Id: dto['item1Id'] as String,
      item2Id: dto['item2Id'] as String,
      item1Name: dto['item1Name'] as String,
      item2Name: dto['item2Name'] as String,
      item1Rarity: dto['item1Rarity'] as String,
      item2Rarity: dto['item2Rarity'] as String,
      completedAt: (dto['completedAt'] as Timestamp).toDate(),
      reason: dto['reason'] as String,
      notes: dto['notes'] as String?,
    );
  }
}
