import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_content_model.dart';

/// ストーリーコンテンツ リポジトリ
///
/// Firestore のストーリーコンテンツデータを管理
class StoryContentRepository {
  final FirebaseFirestore _firestore;

  StoryContentRepository(this._firestore);

  /// すべてのストーリーコンテンツを取得
  Future<List<StoryContent>> getAllStories() async {
    try {
      final snapshot = await _firestore
          .collection('storyContents')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StoryContentDTO.fromFirestore(doc).toModel())
          .toList();
    } catch (e) {
      throw Exception('Failed to get all stories: $e');
    }
  }

  /// 特定の ID でストーリーコンテンツを取得
  Future<StoryContent?> getStoryById(String storyId) async {
    try {
      final snapshot =
          await _firestore.collection('storyContents').doc(storyId).get();

      if (!snapshot.exists) return null;

      final dto = StoryContentDTO.fromFirestore(snapshot);
      return dto.toModel();
    } catch (e) {
      throw Exception('Failed to get story by id: $e');
    }
  }

  /// ストーリータイプ別にストーリーを取得
  Future<List<StoryContent>> getStoriesByType(String storyType) async {
    try {
      final snapshot = await _firestore
          .collection('storyContents')
          .where('storyType', isEqualTo: storyType)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StoryContentDTO.fromFirestore(doc).toModel())
          .toList();
    } catch (e) {
      throw Exception('Failed to get stories by type: $e');
    }
  }

  /// ユーザーのストーリー進捗を取得
  Future<UserStoryProgress?> getUserStoryProgress(
    String userId,
    String storyId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('storyProgress')
          .doc(storyId)
          .get();

      if (!snapshot.exists) return null;

      final dto = UserStoryProgressDTO.fromFirestore(snapshot);
      return dto.toModel();
    } catch (e) {
      throw Exception('Failed to get user story progress: $e');
    }
  }

  /// ユーザーのすべてのストーリー進捗を取得
  Future<List<UserStoryProgress>> getUserStoryProgressList(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('storyProgress')
          .get();

      return snapshot.docs
          .map((doc) => UserStoryProgressDTO.fromFirestore(doc).toModel())
          .toList();
    } catch (e) {
      throw Exception('Failed to get user story progress list: $e');
    }
  }

  /// ストーリー進捗を更新
  Future<void> updateStoryProgress(
    String userId,
    String storyId,
    int lastReadChapter,
    bool isCompleted,
  ) async {
    try {
      final now = DateTime.now();
      final progressData = {
        'userId': userId,
        'storyId': storyId,
        'lastReadChapter': lastReadChapter,
        'isCompleted': isCompleted,
        'lastReadAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('storyProgress')
          .doc(storyId)
          .set(progressData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update story progress: $e');
    }
  }

  /// ストーリーを初回読破時に進捗を登録
  Future<void> initializeStoryProgress(
    String userId,
    String storyId,
  ) async {
    try {
      final now = DateTime.now();
      final progressData = {
        'userId': userId,
        'storyId': storyId,
        'lastReadChapter': 0,
        'isCompleted': false,
        'firstReadAt': Timestamp.fromDate(now),
        'lastReadAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('storyProgress')
          .doc(storyId)
          .set(progressData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to initialize story progress: $e');
    }
  }

  /// デモストーリーを作成（開発用）
  StoryContent createDemoStory() {
    return StoryContent(
      id: 'demo-story-001',
      title: 'デモストーリー：ガチャ帳の始まり',
      description: 'このストーリーはデモ用のストーリーコンテンツです。開発時に使用します。',
      storyType: 'world',
      chapters: [
        StoryChapter(
          chapterNumber: 1,
          title: '第1章 新しい冒険',
          content: [
            'ある日、あなたはデジタルガチャ帳という不思議なアイテムを手にした。',
            'このガチャ帳には、世界中のあらゆるアイテムが集められるという。',
            'あなたの大冒険がここから始まるのだった。',
          ],
          characterImageUrl: null,
          backgroundImageUrl: null,
        ),
        StoryChapter(
          chapterNumber: 2,
          title: '第2章 最初の出会い',
          content: [
            'ガチャボタンを押すと、光が舞い散った。',
            '最初のアイテムが現れた。',
            'これが、すべての始まりだった。',
          ],
          characterImageUrl: null,
          backgroundImageUrl: null,
        ),
      ],
      thumbnailImageUrl: 'https://via.placeholder.com/200x300?text=Demo+Story',
      totalChapters: 2,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
