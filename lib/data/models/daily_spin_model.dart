import 'package:freezed_annotation/freezed_annotation.dart';
import 'gacha_item_model.dart';

part 'daily_spin_model.freezed.dart';
part 'daily_spin_model.g.dart';

/// スピン結果
@freezed
class SpinResult with _$SpinResult {
  const factory SpinResult({
    required String id,
    required String userId,
    required String itemName,
    required String series,
    required Rarity rarity,
    required DateTime spinnedAt,
    String? notes,
  }) = _SpinResult;

  factory SpinResult.fromJson(Map<String, dynamic> json) =>
      _$SpinResultFromJson(json);
}

/// 日次スピン情報
@freezed
class DailySpin with _$DailySpin {
  const factory DailySpin({
    required String id,
    required String userId,
    required DateTime lastSpinDate,
    required int spinCount,
    required int maxSpinsPerDay,
    required List<SpinResult> resultHistory,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DailySpin;

  factory DailySpin.fromJson(Map<String, dynamic> json) =>
      _$DailySpinFromJson(json);
}

/// Firestore用スピン結果DTO
@freezed
class SpinResultDTO with _$SpinResultDTO {
  const factory SpinResultDTO({
    required String id,
    required String userId,
    required String itemName,
    required String series,
    required String rarity,
    required int spinnedAtMillis,
    String? notes,
  }) = _SpinResultDTO;

  factory SpinResultDTO.fromJson(Map<String, dynamic> json) =>
      _$SpinResultDTOFromJson(json);

  factory SpinResultDTO.fromSpinResult(SpinResult result) {
    return SpinResultDTO(
      id: result.id,
      userId: result.userId,
      itemName: result.itemName,
      series: result.series,
      rarity: result.rarity.value,
      spinnedAtMillis: result.spinnedAt.millisecondsSinceEpoch,
      notes: result.notes,
    );
  }

  SpinResult toSpinResult() {
    return SpinResult(
      id: id,
      userId: userId,
      itemName: itemName,
      series: series,
      rarity: _parseRarity(rarity),
      spinnedAt: DateTime.fromMillisecondsSinceEpoch(spinnedAtMillis),
      notes: notes,
    );
  }
}

/// Firestore用日次スピン情報DTO
@freezed
class DailySpinDTO with _$DailySpinDTO {
  const factory DailySpinDTO({
    required String id,
    required String userId,
    required int lastSpinDateMillis,
    required int spinCount,
    required int maxSpinsPerDay,
    required List<Map<String, dynamic>> resultHistory,
    required int createdAtMillis,
    required int updatedAtMillis,
  }) = _DailySpinDTO;

  factory DailySpinDTO.fromJson(Map<String, dynamic> json) =>
      _$DailySpinDTOFromJson(json);

  factory DailySpinDTO.fromDailySpin(DailySpin spin) {
    return DailySpinDTO(
      id: spin.id,
      userId: spin.userId,
      lastSpinDateMillis: spin.lastSpinDate.millisecondsSinceEpoch,
      spinCount: spin.spinCount,
      maxSpinsPerDay: spin.maxSpinsPerDay,
      resultHistory: spin.resultHistory
          .map((result) => SpinResultDTO.fromSpinResult(result).toJson())
          .toList(),
      createdAtMillis: spin.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: spin.updatedAt.millisecondsSinceEpoch,
    );
  }

  DailySpin toDailySpin() {
    return DailySpin(
      id: id,
      userId: userId,
      lastSpinDate: DateTime.fromMillisecondsSinceEpoch(lastSpinDateMillis),
      spinCount: spinCount,
      maxSpinsPerDay: maxSpinsPerDay,
      resultHistory: resultHistory
          .map((json) => SpinResultDTO.fromJson(json).toSpinResult())
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }
}

Rarity _parseRarity(String value) {
  return Rarity.values.firstWhere(
    (rarity) => rarity.value == value,
    orElse: () => Rarity.n,
  );
}
