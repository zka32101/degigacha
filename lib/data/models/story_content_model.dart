import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_content_model.freezed.dart';
part 'story_content_model.g.dart';

/// ストーリー段
///
/// ストーリーコンテンツ内の個別の段落/シーン
@freezed
class StoryChapter with _$StoryChapter {
  const factory StoryChapter({
    required int chapterNumber,
    required String title,
    required List<String> content, // 各文
    required String? characterImageUrl,
    required String? backgroundImageUrl,
  }) = _StoryChapter;

  factory StoryChapter.fromJson(Map<String, dynamic> json) =>
      _$StoryChapterFromJson(json);
}

/// ストーリーコンテンツ
///
/// ナラティブコンテンツ、キャラクター背景設定等
@freezed
class StoryContent with _$StoryContent {
  const factory StoryContent({
    required String id,
    required String title,
    required String description,
    required String storyType, // 'character', 'event', 'world' 等
    required List<StoryChapter> chapters,
    required String? thumbnailImageUrl,
    required int totalChapters,
    required bool isUnlocked,
    required DateTime unlockedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StoryContent;

  factory StoryContent.fromJson(Map<String, dynamic> json) =>
      _$StoryContentFromJson(json);
}

/// ストーリーコンテンツ DTO
@freezed
class StoryContentDTO with _$StoryContentDTO {
  const factory StoryContentDTO({
    required String id,
    required String title,
    required String description,
    required String storyType,
    required List<Map<String, dynamic>> chapters,
    required String? thumbnailImageUrl,
    required int totalChapters,
    required bool isUnlocked,
    required Timestamp unlockedAt,
    required Timestamp createdAt,
    required Timestamp updatedAt,
  }) = _StoryContentDTO;

  factory StoryContentDTO.fromJson(Map<String, dynamic> json) =>
      _$StoryContentDTOFromJson(json);

  factory StoryContentDTO.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return StoryContentDTO.fromJson(data);
  }
}

/// ユーザーストーリー進捗
///
/// ユーザーのストーリー読破状況を追跡
@freezed
class UserStoryProgress with _$UserStoryProgress {
  const factory UserStoryProgress({
    required String userId,
    required String storyId,
    required int lastReadChapter,
    required bool isCompleted,
    required DateTime firstReadAt,
    required DateTime lastReadAt,
  }) = _UserStoryProgress;

  factory UserStoryProgress.fromJson(Map<String, dynamic> json) =>
      _$UserStoryProgressFromJson(json);
}

/// ユーザーストーリー進捗 DTO
@freezed
class UserStoryProgressDTO with _$UserStoryProgressDTO {
  const factory UserStoryProgressDTO({
    required String userId,
    required String storyId,
    required int lastReadChapter,
    required bool isCompleted,
    required Timestamp firstReadAt,
    required Timestamp lastReadAt,
  }) = _UserStoryProgressDTO;

  factory UserStoryProgressDTO.fromJson(Map<String, dynamic> json) =>
      _$UserStoryProgressDTOFromJson(json);

  factory UserStoryProgressDTO.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return UserStoryProgressDTO.fromJson(data);
  }
}

/// ストーリーコンテンツ拡張
extension StoryContentExtensions on StoryContent {
  /// 完了率を計算
  double get completionRate {
    if (totalChapters == 0) return 0;
    return chapters.length / totalChapters;
  }

  /// DTO に変換
  StoryContentDTO toDTO() {
    return StoryContentDTO(
      id: id,
      title: title,
      description: description,
      storyType: storyType,
      chapters: chapters
          .map((c) => {
                'chapterNumber': c.chapterNumber,
                'title': c.title,
                'content': c.content,
                'characterImageUrl': c.characterImageUrl,
                'backgroundImageUrl': c.backgroundImageUrl,
              })
          .toList(),
      thumbnailImageUrl: thumbnailImageUrl,
      totalChapters: totalChapters,
      isUnlocked: isUnlocked,
      unlockedAt: Timestamp.fromDate(unlockedAt),
      createdAt: Timestamp.fromDate(createdAt),
      updatedAt: Timestamp.fromDate(updatedAt),
    );
  }
}

/// ユーザーストーリー進捗拡張
extension UserStoryProgressExtensions on UserStoryProgress {
  /// DTO に変換
  UserStoryProgressDTO toDTO() {
    return UserStoryProgressDTO(
      userId: userId,
      storyId: storyId,
      lastReadChapter: lastReadChapter,
      isCompleted: isCompleted,
      firstReadAt: Timestamp.fromDate(firstReadAt),
      lastReadAt: Timestamp.fromDate(lastReadAt),
    );
  }
}

/// DTO から モデル に変換
extension StoryContentDTOExtensions on StoryContentDTO {
  /// ストーリーコンテンツ に変換
  StoryContent toModel() {
    return StoryContent(
      id: id,
      title: title,
      description: description,
      storyType: storyType,
      chapters: chapters
          .map((c) => StoryChapter.fromJson(c))
          .toList(),
      thumbnailImageUrl: thumbnailImageUrl,
      totalChapters: totalChapters,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt.toDate(),
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }
}

/// ユーザーストーリー進捗 DTO から モデル に変換
extension UserStoryProgressDTOExtensions on UserStoryProgressDTO {
  /// ユーザーストーリー進捗 に変換
  UserStoryProgress toModel() {
    return UserStoryProgress(
      userId: userId,
      storyId: storyId,
      lastReadChapter: lastReadChapter,
      isCompleted: isCompleted,
      firstReadAt: firstReadAt.toDate(),
      lastReadAt: lastReadAt.toDate(),
    );
  }
}
