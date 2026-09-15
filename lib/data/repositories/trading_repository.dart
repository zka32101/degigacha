import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trading_model.dart';

/// トレード管理リポジトリ
class TradingRepository {
  final FirebaseFirestore _firestore;

  TradingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// トレード要求を作成
  Future<String> createTradeRequest({
    required String fromUserId,
    required String toUserId,
    required String offeredItemId,
    required String requestedItemId,
    String? message,
  }) async {
    try {
      final requestId = _firestore.collection('trade_requests').doc().id;

      await _firestore
          .collection('trade_requests')
          .doc(requestId)
          .set({
        'requestId': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'offeredItemId': offeredItemId,
        'requestedItemId': requestedItemId,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'completedAt': null,
        'message': message,
      });

      return requestId;
    } catch (e) {
      throw Exception('トレード要求作成に失敗: $e');
    }
  }

  /// 受け取ったトレード要求を取得
  Future<List<TradeRequest>> getReceivedTradeRequests(String userId) async {
    try {
      final query = await _firestore
          .collection('trade_requests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = doc.id;
        return TradeRequest.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('受取トレード要求取得に失敗: $e');
    }
  }

  /// 送信したトレード要求を取得
  Future<List<TradeRequest>> getSentTradeRequests(String userId) async {
    try {
      final query = await _firestore
          .collection('trade_requests')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = doc.id;
        return TradeRequest.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('送信トレード要求取得に失敗: $e');
    }
  }

  /// トレード要求を承認
  Future<void> acceptTradeRequest(String requestId) async {
    try {
      await _firestore
          .collection('trade_requests')
          .doc(requestId)
          .update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('トレード承認に失敗: $e');
    }
  }

  /// トレード要求を却下
  Future<void> rejectTradeRequest(String requestId) async {
    try {
      await _firestore
          .collection('trade_requests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('トレード却下に失敗: $e');
    }
  }

  /// トレード要求をキャンセル
  Future<void> cancelTradeRequest(String requestId) async {
    try {
      await _firestore
          .collection('trade_requests')
          .doc(requestId)
          .update({
        'status': 'cancelled',
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('トレードキャンセルに失敗: $e');
    }
  }

  /// トレード履歴を記録
  Future<void> recordTradeHistory({
    required String userId1,
    required String userId2,
    required String item1Id,
    required String item2Id,
    required String item1Name,
    required String item2Name,
    required String item1Rarity,
    required String item2Rarity,
    required String reason,
    String? notes,
  }) async {
    try {
      final tradeId = _firestore.collection('trade_history').doc().id;

      await _firestore
          .collection('trade_history')
          .doc(tradeId)
          .set({
        'tradeId': tradeId,
        'userId1': userId1,
        'userId2': userId2,
        'item1Id': item1Id,
        'item2Id': item2Id,
        'item1Name': item1Name,
        'item2Name': item2Name,
        'item1Rarity': item1Rarity,
        'item2Rarity': item2Rarity,
        'completedAt': Timestamp.now(),
        'reason': reason,
        'notes': notes,
      });
    } catch (e) {
      throw Exception('トレード履歴記録に失敗: $e');
    }
  }

  /// トレード履歴を取得
  Future<List<TradeHistory>> getTradeHistory(String userId) async {
    try {
      final query = await _firestore
          .collection('trade_history')
          .where('userId1', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .get();

      final query2 = await _firestore
          .collection('trade_history')
          .where('userId2', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .get();

      final results = <TradeHistory>[];

      for (final doc in query.docs) {
        final data = doc.data();
        data['tradeId'] = doc.id;
        results.add(TradeHistory.fromJson(data));
      }

      for (final doc in query2.docs) {
        final data = doc.data();
        data['tradeId'] = doc.id;
        results.add(TradeHistory.fromJson(data));
      }

      // 日時でソート
      results.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      return results;
    } catch (e) {
      throw Exception('トレード履歴取得に失敗: $e');
    }
  }

  /// トレード統計を取得
  Future<TradeStatistics> getTradeStatistics(String userId) async {
    try {
      final histories = await getTradeHistory(userId);

      final completedTrades = histories
          .where((h) => h.reason == 'normal')
          .toList()
          .length;

      final receivedRequests = await getReceivedTradeRequests(userId);
      final pendingTrades = receivedRequests.length;

      // レアリティ別統計
      final tradesByRarity = <String, int>{};
      for (final history in histories) {
        tradesByRarity[history.item1Rarity] =
            (tradesByRarity[history.item1Rarity] ?? 0) + 1;
        tradesByRarity[history.item2Rarity] =
            (tradesByRarity[history.item2Rarity] ?? 0) + 1;
      }

      // よくトレードする相手
      final partnerCounts = <String, int>{};
      for (final history in histories) {
        final partner = history.userId1 == userId ? history.userId2 : history.userId1;
        partnerCounts[partner] = (partnerCounts[partner] ?? 0) + 1;
      }

      final favoritePartners = partnerCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return TradeStatistics(
        completedTrades: completedTrades,
        pendingTrades: pendingTrades,
        totalItemsTraded: histories.length * 2,
        tradesByRarity: tradesByRarity,
        favoriteTradePartners:
            favoritePartners.map((e) => e.key).take(5).toList(),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('トレード統計取得に失敗: $e');
    }
  }

  /// トレード提案を作成（マッチングアルゴリズム）
  Future<List<TradeSuggestion>> generateTradeSuggestions(
    String userId,
    String userItemId,
    List<String> otherUsersItemIds,
  ) async {
    try {
      final suggestions = <TradeSuggestion>[];

      for (final otherItemId in otherUsersItemIds) {
        final suggestionId =
            _firestore.collection('trade_suggestions').doc().id;

        // シンプルなマッチング計算（後で改善可能）
        double confidence = 0.7 + (0.3 * (suggestionId.hashCode % 10) / 10);

        suggestions.add(
          TradeSuggestion(
            suggestionId: suggestionId,
            fromUserId: userId,
            toUserId: '', // 実装時に決定
            offeredItemId: userItemId,
            requestedItemOptions: [otherItemId],
            status: 'pending',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
            confidence: confidence,
            reason: 'マッチング提案',
          ),
        );
      }

      return suggestions;
    } catch (e) {
      throw Exception('トレード提案生成に失敗: $e');
    }
  }
}
