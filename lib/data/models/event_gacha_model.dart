import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_gacha_model.freezed.dart';
part 'event_gacha_model.g.dart';

/// イベント限定キャラクター
@freezed
class LimitedCharacter with _$LimitedCharacter {
  const factory LimitedCharacter({
    required String id,
    required String name,
    required String description,
    required String imageUrl,
    required bool isFeature,
  }) = _LimitedCharacter;

  factory LimitedCharacter.fromJson(Map<String, dynamic> json) =>
      _$LimitedCharacterFromJson(json);
}

/// イベントガチャ情報
@freezed
class EventGacha with _$EventGacha {
  const factory EventGacha({
    required String id,
    required String eventName,
    required String eventDescription,
    required String bannerImageUrl,
    required DateTime startDate,
    required DateTime endDate,
    required double ssrProbability,
    required List<LimitedCharacter> limitedCharacters,
    required int userSpins,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _EventGacha;

  factory EventGacha.fromJson(Map<String, dynamic> json) =>
      _$EventGachaFromJson(json);

  /// イベントが現在アクティブか判定
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// イベント終了まで残り日数
  int get daysRemaining {
    final now = DateTime.now();
    if (!isActive) return 0;
    return endDate.difference(now).inDays + 1;
  }

  /// 終了日時フォーマット
  String get formattedEndDate =>
      '${endDate.month}/${endDate.day} ${endDate.hour}:${endDate.minute}';
}

/// Firestore用イベントガチャDTO
@freezed
class EventGachaDTO with _$EventGachaDTO {
  const factory EventGachaDTO({
    required String id,
    required String eventName,
    required String eventDescription,
    required String bannerImageUrl,
    required int startDateMillis,
    required int endDateMillis,
    required double ssrProbability,
    required List<Map<String, dynamic>> limitedCharacters,
    required int userSpins,
    required int createdAtMillis,
    required int updatedAtMillis,
  }) = _EventGachaDTO;

  factory EventGachaDTO.fromJson(Map<String, dynamic> json) =>
      _$EventGachaDTOFromJson(json);

  factory EventGachaDTO.fromEventGacha(EventGacha event) {
    return EventGachaDTO(
      id: event.id,
      eventName: event.eventName,
      eventDescription: event.eventDescription,
      bannerImageUrl: event.bannerImageUrl,
      startDateMillis: event.startDate.millisecondsSinceEpoch,
      endDateMillis: event.endDate.millisecondsSinceEpoch,
      ssrProbability: event.ssrProbability,
      limitedCharacters: event.limitedCharacters
          .map((char) => char.toJson())
          .toList(),
      userSpins: event.userSpins,
      createdAtMillis: event.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: event.updatedAt.millisecondsSinceEpoch,
    );
  }

  EventGacha toEventGacha() {
    return EventGacha(
      id: id,
      eventName: eventName,
      eventDescription: eventDescription,
      bannerImageUrl: bannerImageUrl,
      startDate: DateTime.fromMillisecondsSinceEpoch(startDateMillis),
      endDate: DateTime.fromMillisecondsSinceEpoch(endDateMillis),
      ssrProbability: ssrProbability,
      limitedCharacters: limitedCharacters
          .map((json) => LimitedCharacter.fromJson(json))
          .toList(),
      userSpins: userSpins,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }
}

/// イベントガチャ結果
@freezed
class EventSpinResult with _$EventSpinResult {
  const factory EventSpinResult({
    required String id,
    required String userId,
    required String eventId,
    required String characterId,
    required String characterName,
    required bool isLimited,
    required bool isFeature,
    required DateTime spinnedAt,
  }) = _EventSpinResult;

  factory EventSpinResult.fromJson(Map<String, dynamic> json) =>
      _$EventSpinResultFromJson(json);
}

/// Firestore用イベントスピン結果DTO
@freezed
class EventSpinResultDTO with _$EventSpinResultDTO {
  const factory EventSpinResultDTO({
    required String id,
    required String userId,
    required String eventId,
    required String characterId,
    required String characterName,
    required bool isLimited,
    required bool isFeature,
    required int spinnedAtMillis,
  }) = _EventSpinResultDTO;

  factory EventSpinResultDTO.fromJson(Map<String, dynamic> json) =>
      _$EventSpinResultDTOFromJson(json);

  factory EventSpinResultDTO.fromEventSpinResult(EventSpinResult result) {
    return EventSpinResultDTO(
      id: result.id,
      userId: result.userId,
      eventId: result.eventId,
      characterId: result.characterId,
      characterName: result.characterName,
      isLimited: result.isLimited,
      isFeature: result.isFeature,
      spinnedAtMillis: result.spinnedAt.millisecondsSinceEpoch,
    );
  }

  EventSpinResult toEventSpinResult() {
    return EventSpinResult(
      id: id,
      userId: userId,
      eventId: eventId,
      characterId: characterId,
      characterName: characterName,
      isLimited: isLimited,
      isFeature: isFeature,
      spinnedAt: DateTime.fromMillisecondsSinceEpoch(spinnedAtMillis),
    );
  }
}
