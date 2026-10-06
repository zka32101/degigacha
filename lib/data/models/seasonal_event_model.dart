import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'seasonal_event_model.freezed.dart';
part 'seasonal_event_model.g.dart';

/// シーズナルイベント
///
/// 期間限定のゲーム内イベント（季節イベント、記念日イベント等）
@freezed
class SeasonalEvent with _$SeasonalEvent {
  const factory SeasonalEvent({
    required String id,
    required String title,
    required String description,
    required String eventType, // 'seasonal', 'anniversary', 'campaign' 等
    required DateTime startDate,
    required DateTime endDate,
    required String bannerImageUrl,
    required List<String> rewardIds, // 報酬アイテムID
    required double bonusMultiplier, // ガチャ確率ボーナス倍率
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SeasonalEvent;

  factory SeasonalEvent.fromJson(Map<String, dynamic> json) =>
      _$SeasonalEventFromJson(json);
}

/// シーズナルイベント DTO
@freezed
class SeasonalEventDTO with _$SeasonalEventDTO {
  const factory SeasonalEventDTO({
    required String id,
    required String title,
    required String description,
    required String eventType,
    required Timestamp startDate,
    required Timestamp endDate,
    required String bannerImageUrl,
    required List<String> rewardIds,
    required double bonusMultiplier,
    required bool isActive,
    required Timestamp createdAt,
    required Timestamp updatedAt,
  }) = _SeasonalEventDTO;

  factory SeasonalEventDTO.fromJson(Map<String, dynamic> json) =>
      _$SeasonalEventDTOFromJson(json);

  factory SeasonalEventDTO.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return SeasonalEventDTO.fromJson(data);
  }
}

/// シーズナルイベント拡張
extension SeasonalEventExtensions on SeasonalEvent {
  /// 日数残り
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays + 1;
  }

  /// イベントが現在進行中か
  bool get isRunning {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// DTO に変換
  SeasonalEventDTO toDTO() {
    return SeasonalEventDTO(
      id: id,
      title: title,
      description: description,
      eventType: eventType,
      startDate: Timestamp.fromDate(startDate),
      endDate: Timestamp.fromDate(endDate),
      bannerImageUrl: bannerImageUrl,
      rewardIds: rewardIds,
      bonusMultiplier: bonusMultiplier,
      isActive: isActive,
      createdAt: Timestamp.fromDate(createdAt),
      updatedAt: Timestamp.fromDate(updatedAt),
    );
  }
}

/// DTO から モデル に変換
extension SeasonalEventDTOExtensions on SeasonalEventDTO {
  /// セッションオブジェクト に変換
  SeasonalEvent toModel() {
    return SeasonalEvent(
      id: id,
      title: title,
      description: description,
      eventType: eventType,
      startDate: startDate.toDate(),
      endDate: endDate.toDate(),
      bannerImageUrl: bannerImageUrl,
      rewardIds: rewardIds,
      bonusMultiplier: bonusMultiplier,
      isActive: isActive,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }
}
