import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gacha_item_model.dart';
import '../models/duplicate_management_model.dart';

/// 重複アイテム管理リポジトリ
class DuplicateManagementRepository {
  final FirebaseFirestore _firestore;

  DuplicateManagementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ユーザーのすべての重複アイテムを検出
  Future<List<DuplicateItem>> detectDuplicates(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('items')
          .get();

      // アイテムをグループ化して重複を検出
      final itemGroups = <String, List<GachaItem>>{};

      for (final doc in query.docs) {
        final json = doc.data();
        json['id'] = doc.id;
        // GachaItemは他のモデルなので、ここでは簡易的にマッピング
        final itemId = json['id'] as String;
        final itemName = json['itemName'] as String;
        final series = json['series'] as String;

        // 重複検出キーを生成（シリーズ + アイテム名 + レアリティ）
        final rarity = json['rarity'] as String?;
        final key = '$series|$itemName|${rarity ?? "unknown"}';

        itemGroups.putIfAbsent(key, () => []);
        // ここでは簡易的にitem情報を保持
      }

      // 重複（2個以上）のアイテムをフィルタリング
      final duplicates = <DuplicateItem>[];

      for (final doc in query.docs) {
        final json = doc.data();
        json['id'] = doc.id;

        final itemId = json['id'] as String;
        final itemName = json['itemName'] as String;
        final series = json['series'] as String;
        final rarity = json['rarity'] as String?;
        final key = '$series|$itemName|${rarity ?? "unknown"}';

        // キー内のアイテム数をカウント
        final itemsWithKey = query.docs
            .where((d) {
              final data = d.data();
              final dItemName = data['itemName'] as String;
              final dSeries = data['series'] as String;
              final dRarity = data['rarity'] as String?;
              final dKey = '$dSeries|$dItemName|${dRarity ?? "unknown"}';
              return dKey == key;
            })
            .toList();

        if (itemsWithKey.length >= 2) {
          // 重複アイテム
          final duplicateIds = itemsWithKey
              .map((d) => d.id)
              .where((id) => id != itemId)
              .toList();

          if (!duplicates.any((d) => d.itemId == itemId)) {
            duplicates.add(
              DuplicateItem(
                itemId: itemId,
                itemName: itemName,
                series: series,
                rarity: rarity ?? 'unknown',
                duplicateCount: itemsWithKey.length - 1,
                firstAcquisitionDate:
                    (json['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
                lastAcquisitionDate:
                    (json['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
                duplicateIds: duplicateIds,
                notes: json['notes'] as String?,
              ),
            );
          }
        }
      }

      return duplicates;
    } catch (e) {
      throw Exception('重複検出に失敗: $e');
    }
  }

  /// 重複統計情報を取得
  Future<DuplicateStatistics> getDuplicateStatistics(String userId) async {
    try {
      final duplicates = await detectDuplicates(userId);

      if (duplicates.isEmpty) {
        return DuplicateStatistics(
          totalDuplicateItems: 0,
          totalDuplicateCount: 0,
          duplicateCountByRarity: {},
          duplicateCountBySeries: {},
          averageDuplicateCount: 0,
          lastUpdated: DateTime.now(),
        );
      }

      // レアリティ別の統計
      final duplicateCountByRarity = <String, int>{};
      for (final duplicate in duplicates) {
        duplicateCountByRarity[duplicate.rarity] =
            (duplicateCountByRarity[duplicate.rarity] ?? 0) +
                duplicate.duplicateCount;
      }

      // シリーズ別の統計
      final duplicateCountBySeries = <String, int>{};
      for (final duplicate in duplicates) {
        duplicateCountBySeries[duplicate.series] =
            (duplicateCountBySeries[duplicate.series] ?? 0) +
                duplicate.duplicateCount;
      }

      // 平均重複数
      final totalDuplicateCount =
          duplicates.fold(0, (sum, d) => sum + d.duplicateCount);
      final averageDuplicateCount = duplicates.isNotEmpty
          ? totalDuplicateCount / duplicates.length
          : 0;

      return DuplicateStatistics(
        totalDuplicateItems: duplicates.length,
        totalDuplicateCount: totalDuplicateCount,
        duplicateCountByRarity: duplicateCountByRarity,
        duplicateCountBySeries: duplicateCountBySeries,
        averageDuplicateCount: averageDuplicateCount,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('統計情報取得に失敗: $e');
    }
  }

  /// 特定シリーズの重複アイテムを取得
  Future<List<DuplicateItem>> getDuplicatesBySeriesId(
    String userId,
    String seriesId,
  ) async {
    try {
      final allDuplicates = await detectDuplicates(userId);
      return allDuplicates
          .where((d) => d.series == seriesId)
          .toList();
    } catch (e) {
      throw Exception('シリーズ別重複取得に失敗: $e');
    }
  }

  /// 特定レアリティの重複アイテムを取得
  Future<List<DuplicateItem>> getDuplicatesByRarity(
    String userId,
    String rarity,
  ) async {
    try {
      final allDuplicates = await detectDuplicates(userId);
      return allDuplicates
          .where((d) => d.rarity == rarity)
          .toList();
    } catch (e) {
      throw Exception('レアリティ別重複取得に失敗: $e');
    }
  }

  /// 重複アイテムを交換するためのリクエストを作成
  Future<void> createExchangeRequest({
    required String userId,
    required String targetUserId,
    required String duplicateItemId,
    required int quantity,
    required String requestedItemId,
  }) async {
    try {
      final requestId =
          _firestore.collection('exchange_requests').doc().id;

      await _firestore
          .collection('exchange_requests')
          .doc(requestId)
          .set({
        'requestId': requestId,
        'fromUserId': userId,
        'toUserId': targetUserId,
        'duplicateItemId': duplicateItemId,
        'quantityOffered': quantity,
        'requestedItemId': requestedItemId,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'completedAt': null,
      });
    } catch (e) {
      throw Exception('交換リクエスト作成に失敗: $e');
    }
  }

  /// ユーザーが受け取った交換リクエストを取得
  Future<List<DuplicateExchangeRequest>> getReceivedExchangeRequests(
    String userId,
  ) async {
    try {
      final query = await _firestore
          .collection('exchange_requests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = doc.id;
        return DuplicateExchangeRequest.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('受取交換リクエスト取得に失敗: $e');
    }
  }

  /// ユーザーが送信した交換リクエストを取得
  Future<List<DuplicateExchangeRequest>> getSentExchangeRequests(
    String userId,
  ) async {
    try {
      final query = await _firestore
          .collection('exchange_requests')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = doc.id;
        return DuplicateExchangeRequest.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('送信交換リクエスト取得に失敗: $e');
    }
  }

  /// 交換リクエストを承認
  Future<void> acceptExchangeRequest(String requestId) async {
    try {
      await _firestore
          .collection('exchange_requests')
          .doc(requestId)
          .update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('交換リクエスト承認に失敗: $e');
    }
  }

  /// 交換リクエストをキャンセル
  Future<void> cancelExchangeRequest(String requestId) async {
    try {
      await _firestore
          .collection('exchange_requests')
          .doc(requestId)
          .update({
        'status': 'cancelled',
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('交換リクエストキャンセルに失敗: $e');
    }
  }
}
