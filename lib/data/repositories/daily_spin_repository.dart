import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gacha_item_model.dart';
import '../models/daily_spin_model.dart';

/// 日次スピンのリポジトリ
class DailySpinRepository {
  final FirebaseFirestore _firestore;

  DailySpinRepository(this._firestore);

  /// ユーザーの日次スピン情報を取得
  Future<DailySpin?> getDailySpin(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailySpin')
          .doc('current')
          .get();

      if (!snapshot.exists) {
        return null;
      }

      return DailySpinDTO.fromJson(snapshot.data() as Map<String, dynamic>)
          .toDailySpin();
    } catch (e) {
      throw Exception('日次スピン情報の取得に失敗しました: $e');
    }
  }

  /// スピン情報を作成または更新
  Future<DailySpin> upsertDailySpin(DailySpin spin) async {
    try {
      final dto = DailySpinDTO.fromDailySpin(spin);
      await _firestore
          .collection('users')
          .doc(spin.userId)
          .collection('dailySpin')
          .doc('current')
          .set(dto.toJson());

      return spin;
    } catch (e) {
      throw Exception('日次スピン情報の更新に失敗しました: $e');
    }
  }

  /// スピンを実行し、結果を返す
  Future<SpinResult> performSpin(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 既存のスピン情報を取得
      var spin = await getDailySpin(userId);

      if (spin == null) {
        // 初めてのスピンの場合
        spin = DailySpin(
          id: 'daily_spin_$userId',
          userId: userId,
          lastSpinDate: today,
          spinCount: 0,
          maxSpinsPerDay: 1,
          resultHistory: [],
          createdAt: now,
          updatedAt: now,
        );
      } else {
        final lastSpin =
            DateTime(spin.lastSpinDate.year, spin.lastSpinDate.month, spin.lastSpinDate.day);

        // 日付が変わった場合、スピン回数をリセット
        if (lastSpin.isBefore(today)) {
          spin = spin.copyWith(
            lastSpinDate: today,
            spinCount: 0,
          );
        }
      }

      // スピン上限に達していないかチェック
      if (spin.spinCount >= spin.maxSpinsPerDay) {
        throw Exception('本日のスピン上限に達しています');
      }

      // スピン結果を生成
      final result = _generateSpinResult(userId, now);

      // スピン情報を更新
      spin = spin.copyWith(
        spinCount: spin.spinCount + 1,
        resultHistory: [result, ...spin.resultHistory],
        updatedAt: now,
      );

      await upsertDailySpin(spin);
      return result;
    } catch (e) {
      throw Exception('スピン実行に失敗しました: $e');
    }
  }

  /// 日付が変わったときにスピン回数をリセット
  Future<void> resetDailySpins(String userId) async {
    try {
      final spin = await getDailySpin(userId);
      if (spin != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        await upsertDailySpin(
          spin.copyWith(
            lastSpinDate: today,
            spinCount: 0,
            updatedAt: now,
          ),
        );
      }
    } catch (e) {
      throw Exception('日次リセットに失敗しました: $e');
    }
  }

  /// スピン結果を生成（確率に基づいた結果生成）
  SpinResult _generateSpinResult(String userId, DateTime now) {
    // 確率テーブル: N:46%, R:34%, SR:17%, SSR:3%
    final random = Random().nextDouble() * 100;
    Rarity rarity;

    if (random < 3) {
      rarity = Rarity.ssr;
    } else if (random < 20) {
      rarity = Rarity.sr;
    } else if (random < 54) {
      rarity = Rarity.r;
    } else {
      rarity = Rarity.n;
    }

    // ここではデモンストレーション用の仮のアイテム情報を生成
    // 実際にはデータベースから取得することを想定
    final itemName = _generateItemName(rarity);
    final series = _generateSeries();

    return SpinResult(
      id: 'spin_${userId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      itemName: itemName,
      series: series,
      rarity: rarity,
      spinnedAt: now,
      notes: 'Daily spin at ${now.toLocal()}',
    );
  }

  /// 仮のアイテム名を生成
  String _generateItemName(Rarity rarity) {
    final names = {
      Rarity.n: ['ノーマル キャラA', 'ノーマル キャラB', 'ノーマル キャラC'],
      Rarity.r: ['レア キャラD', 'レア キャラE', 'レア キャラF'],
      Rarity.sr: ['スーパーレア キャラG', 'スーパーレア キャラH'],
      Rarity.ssr: ['ウルトラレア キャラX', 'ウルトラレア キャラY'],
    };

    final candidates = names[rarity] ?? ['謎のアイテム'];
    return candidates[Random().nextInt(candidates.length)];
  }

  /// 仮のシリーズ名を生成
  String _generateSeries() {
    final series = ['シリーズA', 'シリーズB', 'シリーズC', 'シリーズD'];
    return series[Random().nextInt(series.length)];
  }
}
