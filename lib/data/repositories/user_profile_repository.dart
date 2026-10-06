import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

/// ユーザープロフィールリポジトリ
class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ユーザープロフィールを取得
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['userId'] = doc.id;
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('プロフィール取得に失敗: $e');
    }
  }

  /// ユーザープロフィールを作成・更新
  Future<void> updateUserProfile({
    required String userId,
    required String username,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? favoriteRarity,
    List<String>? favoriteSeries,
  }) async {
    try {
      final profile = await getUserProfile(userId);

      if (profile == null) {
        await _firestore
            .collection('user_profiles')
            .doc(userId)
            .set({
          'userId': userId,
          'username': username,
          'email': email,
          'displayName': displayName ?? username,
          'avatarUrl': avatarUrl,
          'bio': bio,
          'favoriteRarity': favoriteRarity ?? 'SSR',
          'favoriteSeries': favoriteSeries ?? [],
          'totalItems': 0,
          'totalValue': 0,
          'createdAt': Timestamp.now(),
          'lastUpdatedAt': Timestamp.now(),
          'isPublic': true,
          'followersCount': 0,
          'followingCount': 0,
        });
      } else {
        await _firestore
            .collection('user_profiles')
            .doc(userId)
            .update({
          'displayName': displayName,
          'avatarUrl': avatarUrl,
          'bio': bio,
          'favoriteRarity': favoriteRarity,
          'favoriteSeries': favoriteSeries,
          'lastUpdatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('プロフィール更新に失敗: $e');
    }
  }

  /// フレンドリクエストを送信
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
    String? message,
  }) async {
    try {
      final requestId = _firestore.collection('friend_requests').doc().id;

      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .set({
        'requestId': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'sentAt': Timestamp.now(),
        'status': 'pending',
        'message': message,
      });
    } catch (e) {
      throw Exception('フレンドリクエスト送信に失敗: $e');
    }
  }

  /// フレンドリクエストを受け入れ
  Future<void> acceptFriendRequest(String requestId, String userId, String friendUserId) async {
    try {
      // リクエストのステータスを更新
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
      });

      // フレンドを追加（双方向）
      final friendId1 = _firestore.collection('friends').doc().id;
      await _firestore
          .collection('friends')
          .doc(friendId1)
          .set({
        'friendId': friendId1,
        'userId': userId,
        'friendUserId': friendUserId,
        'addedAt': Timestamp.now(),
        'status': 'accepted',
        'mutualFriends': 0,
      });

      final friendId2 = _firestore.collection('friends').doc().id;
      await _firestore
          .collection('friends')
          .doc(friendId2)
          .set({
        'friendId': friendId2,
        'userId': friendUserId,
        'friendUserId': userId,
        'addedAt': Timestamp.now(),
        'status': 'accepted',
        'mutualFriends': 0,
      });
    } catch (e) {
      throw Exception('フレンドリクエスト受け入れに失敗: $e');
    }
  }

  /// フレンドリクエストを拒否
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({
        'status': 'declined',
      });
    } catch (e) {
      throw Exception('フレンドリクエスト拒否に失敗: $e');
    }
  }

  /// フレンドを削除
  Future<void> removeFriend(String userId, String friendUserId) async {
    try {
      // userId から friendUserId へのフレンド関係を削除
      final query1 = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: userId)
          .where('friendUserId', isEqualTo: friendUserId)
          .get();

      for (final doc in query1.docs) {
        await doc.reference.delete();
      }

      // friendUserId から userId へのフレンド関係を削除
      final query2 = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: friendUserId)
          .where('friendUserId', isEqualTo: userId)
          .get();

      for (final doc in query2.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('フレンド削除に失敗: $e');
    }
  }

  /// フレンドリストを取得
  Future<List<Friend>> getFriendsList(String userId) async {
    try {
      final query = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['friendId'] = doc.id;
        return Friend.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('フレンドリスト取得に失敗: $e');
    }
  }

  /// 受け取ったフレンドリクエストを取得
  Future<List<FriendRequest>> getReceivedFriendRequests(String userId) async {
    try {
      final query = await _firestore
          .collection('friend_requests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('sentAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = doc.id;
        return FriendRequest.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('フレンドリクエスト取得に失敗: $e');
    }
  }

  /// ユーザー統計を取得
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('user_stats').doc(userId).get();

      if (!doc.exists) {
        return UserStats(
          userId: userId,
          totalTrades: 0,
          totalPurchases: 0,
          totalSpent: 0,
          itemsObtained: 0,
          seriesCompleted: 0,
          averageRating: 0.0,
          itemsByRarity: {},
          itemsBySeries: {},
          lastActive: DateTime.now(),
        );
      }

      final data = doc.data()!;
      data['userId'] = doc.id;
      return UserStats.fromJson(data);
    } catch (e) {
      throw Exception('ユーザー統計取得に失敗: $e');
    }
  }

  /// ユーザー統計を更新
  Future<void> updateUserStats({
    required String userId,
    required int totalTrades,
    required int totalPurchases,
    required int itemsObtained,
  }) async {
    try {
      final stats = await getUserStats(userId);

      if (stats == null) {
        await _firestore
            .collection('user_stats')
            .doc(userId)
            .set({
          'userId': userId,
          'totalTrades': totalTrades,
          'totalPurchases': totalPurchases,
          'totalSpent': 0,
          'itemsObtained': itemsObtained,
          'seriesCompleted': 0,
          'averageRating': 0.0,
          'itemsByRarity': {},
          'itemsBySeries': {},
          'lastActive': Timestamp.now(),
        });
      } else {
        await _firestore
            .collection('user_stats')
            .doc(userId)
            .update({
          'totalTrades': totalTrades,
          'totalPurchases': totalPurchases,
          'itemsObtained': itemsObtained,
          'lastActive': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('ユーザー統計更新に失敗: $e');
    }
  }

  /// ユーザー実績を獲得
  Future<void> unlockAchievement({
    required String userId,
    required String title,
    required String description,
    required String badge,
    required String category,
  }) async {
    try {
      final achievementId = _firestore.collection('achievements').doc().id;

      await _firestore
          .collection('achievements')
          .doc(achievementId)
          .set({
        'achievementId': achievementId,
        'userId': userId,
        'title': title,
        'description': description,
        'badge': badge,
        'unlockedAt': Timestamp.now(),
        'category': category,
      });
    } catch (e) {
      throw Exception('実績獲得に失敗: $e');
    }
  }

  /// ユーザーの実績を取得
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final query = await _firestore
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .orderBy('unlockedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['achievementId'] = doc.id;
        return UserAchievement.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('実績取得に失敗: $e');
    }
  }
}
