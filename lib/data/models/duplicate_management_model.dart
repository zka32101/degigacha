import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'duplicate_management_model.freezed.dart';
part 'duplicate_management_model.g.dart';

/// 重複アイテム検出結果
@freezed
class DuplicateItem with _$DuplicateItem {
  const factory DuplicateItem({
    required String itemId,
    required String itemName,
    required String series,
    required String rarity,
    required int duplicateCount,
    required DateTime firstAcquisitionDate,
    required DateTime lastAcquisitionDate,
    required List<String> duplicateIds,
    String? notes,
  }) = _DuplicateItem;

  factory DuplicateItem.fromJson(Map<String, dynamic> json) =>
      _$DuplicateItemFromJson(json);
}

/// 重複統計情報
@freezed
class DuplicateStatistics with _$DuplicateStatistics {
  const factory DuplicateStatistics({
    required int totalDuplicateItems,
    required int totalDuplicateCount,
    required Map<String, int> duplicateCountByRarity,
    required Map<String, int> duplicateCountBySeries,
    required double averageDuplicateCount,
    required DateTime lastUpdated,
  }) = _DuplicateStatistics;

  factory DuplicateStatistics.fromJson(Map<String, dynamic> json) =>
      _$DuplicateStatisticsFromJson(json);
}

/// 重複アイテムグループ
@freezed
class DuplicateGroup with _$DuplicateGroup {
  const factory DuplicateGroup({
    required String groupId,
    required String itemId,
    required String itemName,
    required String series,
    required String rarity,
    required int totalCount,
    required List<DuplicateEntry> entries,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DuplicateGroup;

  factory DuplicateGroup.fromJson(Map<String, dynamic> json) =>
      _$DuplicateGroupFromJson(json);
}

/// 個別の重複エントリ
@freezed
class DuplicateEntry with _$DuplicateEntry {
  const factory DuplicateEntry({
    required String id,
    required DateTime acquisitionDate,
    required String acquisitionMethod,
    required bool isSelected,
  }) = _DuplicateEntry;

  factory DuplicateEntry.fromJson(Map<String, dynamic> json) =>
      _$DuplicateEntryFromJson(json);
}

/// 重複交換リクエスト
@freezed
class DuplicateExchangeRequest with _$DuplicateExchangeRequest {
  const factory DuplicateExchangeRequest({
    required String requestId,
    required String fromUserId,
    required String toUserId,
    required String duplicateItemId,
    required int quantityOffered,
    required String requestedItemId,
    required String status, // pending, accepted, completed, cancelled
    required DateTime createdAt,
    required DateTime? completedAt,
  }) = _DuplicateExchangeRequest;

  factory DuplicateExchangeRequest.fromJson(Map<String, dynamic> json) =>
      _$DuplicateExchangeRequestFromJson(json);
}

extension DuplicateItemExtension on DuplicateItem {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'series': series,
      'rarity': rarity,
      'duplicateCount': duplicateCount,
      'firstAcquisitionDate': Timestamp.fromDate(firstAcquisitionDate),
      'lastAcquisitionDate': Timestamp.fromDate(lastAcquisitionDate),
      'duplicateIds': duplicateIds,
      'notes': notes,
    };
  }

  /// DTOから変換
  static DuplicateItem fromDTO(Map<String, dynamic> dto) {
    return DuplicateItem(
      itemId: dto['itemId'] as String,
      itemName: dto['itemName'] as String,
      series: dto['series'] as String,
      rarity: dto['rarity'] as String,
      duplicateCount: dto['duplicateCount'] as int,
      firstAcquisitionDate: (dto['firstAcquisitionDate'] as Timestamp).toDate(),
      lastAcquisitionDate: (dto['lastAcquisitionDate'] as Timestamp).toDate(),
      duplicateIds: List<String>.from(dto['duplicateIds'] as List),
      notes: dto['notes'] as String?,
    );
  }
}

extension DuplicateGroupExtension on DuplicateGroup {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'groupId': groupId,
      'itemId': itemId,
      'itemName': itemName,
      'series': series,
      'rarity': rarity,
      'totalCount': totalCount,
      'entries': entries.map((e) => {
        'id': e.id,
        'acquisitionDate': Timestamp.fromDate(e.acquisitionDate),
        'acquisitionMethod': e.acquisitionMethod,
        'isSelected': e.isSelected,
      }).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// DTOから変換
  static DuplicateGroup fromDTO(Map<String, dynamic> dto) {
    return DuplicateGroup(
      groupId: dto['groupId'] as String,
      itemId: dto['itemId'] as String,
      itemName: dto['itemName'] as String,
      series: dto['series'] as String,
      rarity: dto['rarity'] as String,
      totalCount: dto['totalCount'] as int,
      entries: (dto['entries'] as List).map((e) {
        final entry = e as Map<String, dynamic>;
        return DuplicateEntry(
          id: entry['id'] as String,
          acquisitionDate: (entry['acquisitionDate'] as Timestamp).toDate(),
          acquisitionMethod: entry['acquisitionMethod'] as String,
          isSelected: entry['isSelected'] as bool,
        );
      }).toList(),
      createdAt: (dto['createdAt'] as Timestamp).toDate(),
      updatedAt: (dto['updatedAt'] as Timestamp).toDate(),
    );
  }
}
