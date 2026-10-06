import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_gacha_model.dart';

/// イベントガチャのリポジトリ
class EventGachaRepository {
  final FirebaseFirestore _firestore;

  EventGachaRepository(this._firestore);

  /// アクティブなイベントガチャを取得
  Future<EventGacha?> getActiveEvent() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('eventGachas')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return EventGachaDTO.fromJson(querySnapshot.docs.first.data())
          .toEventGacha();
    } catch (e) {
      throw Exception('アクティブなイベントの取得に失敗しました: $e');
    }
  }

  /// 全イベントガチャを取得（期限を問わず）
  Future<List<EventGacha>> getAllEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('eventGachas')
          .orderBy('startDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventGachaDTO.fromJson(doc.data()).toEventGacha())
          .toList();
    } catch (e) {
      throw Exception('イベント一覧の取得に失敗しました: $e');
    }
  }

  /// ユーザーが特定のイベントで実行したスピン結果を取得
  Future<List<EventSpinResult>> getUserEventSpins(
    String userId,
    String eventId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('eventSpins')
          .where('eventId', isEqualTo: eventId)
          .orderBy('spinnedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventSpinResultDTO.fromJson(doc.data())
              .toEventSpinResult())
          .toList();
    } catch (e) {
      throw Exception('イベントスピン履歴の取得に失敗しました: $e');
    }
  }

  /// イベントガチャを実行
  Future<EventSpinResult> performEventSpin(
    String userId,
    String eventId,
    EventGacha event,
  ) async {
    try {
      final now = DateTime.now();

      // イベントがアクティブか確認
      if (!event.isActive) {
        throw Exception('このイベントはアクティブではありません');
      }

      // イベント限定キャラを取得
      if (event.limitedCharacters.isEmpty) {
        throw Exception('イベント限定キャラが登録されていません');
      }

      // スピン結果を生成
      final result = _generateEventSpinResult(
        userId: userId,
        eventId: eventId,
        event: event,
        now: now,
      );

      // Firestore に保存
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('eventSpins')
          .doc(result.id)
          .set(EventSpinResultDTO.fromEventSpinResult(result).toJson());

      // ユーザーのイベント統計を更新
      await _updateEventStatistics(userId, eventId);

      return result;
    } catch (e) {
      throw Exception('イベントスピンの実行に失敗しました: $e');
    }
  }

  /// ユーザーのイベント統計を更新
  Future<void> _updateEventStatistics(String userId, String eventId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('eventStatistics')
          .doc(eventId);

      final doc = await docRef.get();

      if (doc.exists) {
        // 既存のドキュメントを更新
        await docRef.update({
          'totalSpins': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
      } else {
        // 新しいドキュメントを作成
        await docRef.set({
          'userId': userId,
          'eventId': eventId,
          'totalSpins': 1,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('イベント統計の更新に失敗しました: $e');
    }
  }

  /// イベントスピン結果を生成
  EventSpinResult _generateEventSpinResult({
    required String userId,
    required String eventId,
    required EventGacha event,
    required DateTime now,
  }) {
    // イベント限定キャラからランダムに選択
    final random = Random();
    final randomValue = random.nextDouble() * 100;

    // 確率判定：イベントのSSR確率 vs 通常確率
    bool isLimited = false;
    if (randomValue < event.ssrProbability * 100) {
      // イベント限定キャラを取得
      final limitedCharacters =
          event.limitedCharacters.where((c) => c.isFeature).toList();
      if (limitedCharacters.isNotEmpty) {
        isLimited = true;
      }
    }

    // キャラクターを選択
    final selectedCharacter =
        event.limitedCharacters[random.nextInt(event.limitedCharacters.length)];

    return EventSpinResult(
      id: 'event_spin_${userId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      eventId: eventId,
      characterId: selectedCharacter.id,
      characterName: selectedCharacter.name,
      isLimited: isLimited,
      isFeature: selectedCharacter.isFeature,
      spinnedAt: now,
    );
  }

  /// デモ用イベントを作成（開発用）
  Future<EventGacha> createDemoEvent() async {
    try {
      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(const Duration(days: 14));

      final eventGacha = EventGacha(
        id: 'demo_event_${now.millisecondsSinceEpoch}',
        eventName: 'キャラクター大集合 〜ファンタジー編〜',
        eventDescription: '新作キャラクターが登場！期間限定で高確率でゲットできます。',
        bannerImageUrl: 'https://via.placeholder.com/1200x400?text=Event+Gacha',
        startDate: startDate,
        endDate: endDate,
        ssrProbability: 0.07, // 通常の7% vs 通常の3%
        limitedCharacters: [
          LimitedCharacter(
            id: 'char_001',
            name: 'ファンタジア・プリンセス',
            description: 'イベント限定の強力なSSRキャラクター',
            imageUrl: 'https://via.placeholder.com/300x300?text=Princess',
            isFeature: true,
          ),
          LimitedCharacter(
            id: 'char_002',
            name: '冒険者アリス',
            description: 'イベント限定のSRキャラクター',
            imageUrl: 'https://via.placeholder.com/300x300?text=Alice',
            isFeature: true,
          ),
          LimitedCharacter(
            id: 'char_003',
            name: '魔法使いボブ',
            description: '通常ガチャにも登場するRキャラクター',
            imageUrl: 'https://via.placeholder.com/300x300?text=Bob',
            isFeature: false,
          ),
        ],
        userSpins: 0,
        createdAt: now,
        updatedAt: now,
      );

      final dto = EventGachaDTO.fromEventGacha(eventGacha);
      await _firestore.collection('eventGachas').doc(eventGacha.id).set(
            dto.toJson(),
          );

      return eventGacha;
    } catch (e) {
      throw Exception('デモイベントの作成に失敗しました: $e');
    }
  }
}
