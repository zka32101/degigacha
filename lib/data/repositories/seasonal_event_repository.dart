import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seasonal_event_model.dart';

/// シーズナルイベント リポジトリ
///
/// Firestore のシーズナルイベントデータを管理
class SeasonalEventRepository {
  final FirebaseFirestore _firestore;

  SeasonalEventRepository(this._firestore);

  /// 現在進行中のイベントを取得
  Future<SeasonalEvent?> getCurrentEvent() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('seasonalEvents')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final dto = SeasonalEventDTO.fromFirestore(snapshot.docs.first);
      return dto.toModel();
    } catch (e) {
      throw Exception('Failed to get current event: $e');
    }
  }

  /// すべてのイベントを取得（終了日でソート）
  Future<List<SeasonalEvent>> getAllEvents() async {
    try {
      final snapshot = await _firestore
          .collection('seasonalEvents')
          .where('isActive', isEqualTo: true)
          .orderBy('endDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SeasonalEventDTO.fromFirestore(doc).toModel())
          .toList();
    } catch (e) {
      throw Exception('Failed to get all events: $e');
    }
  }

  /// 特定のイベント ID でイベントを取得
  Future<SeasonalEvent?> getEventById(String eventId) async {
    try {
      final snapshot =
          await _firestore.collection('seasonalEvents').doc(eventId).get();

      if (!snapshot.exists) return null;

      final dto = SeasonalEventDTO.fromFirestore(snapshot);
      return dto.toModel();
    } catch (e) {
      throw Exception('Failed to get event by id: $e');
    }
  }

  /// 現在進行中のイベント一覧を取得
  Future<List<SeasonalEvent>> getRunningEvents() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('seasonalEvents')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('isActive', isEqualTo: true)
          .orderBy('endDate')
          .get();

      return snapshot.docs
          .map((doc) => SeasonalEventDTO.fromFirestore(doc).toModel())
          .toList();
    } catch (e) {
      throw Exception('Failed to get running events: $e');
    }
  }

  /// イベント タイプ別にイベントを取得
  Future<List<SeasonalEvent>> getEventsByType(String eventType) async {
    try {
      final snapshot = await _firestore
          .collection('seasonalEvents')
          .where('eventType', isEqualTo: eventType)
          .where('isActive', isEqualTo: true)
          .orderBy('endDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SeasonalEventDTO.fromFirestore(doc).toModel())
          .toList();
    } catch (e) {
      throw Exception('Failed to get events by type: $e');
    }
  }

  /// デモイベントを作成（開発用）
  SeasonalEvent createDemoEvent() {
    final now = DateTime.now();
    return SeasonalEvent(
      id: 'demo-event-001',
      title: 'デモシーズナルイベント',
      description: 'これはデモ用のシーズナルイベントです。開発時に使用します。',
      eventType: 'seasonal',
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 5)),
      bannerImageUrl: 'https://via.placeholder.com/400x200?text=Demo+Event',
      rewardIds: ['reward-001', 'reward-002', 'reward-003'],
      bonusMultiplier: 1.5,
      isActive: true,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now,
    );
  }
}
