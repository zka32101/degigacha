import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

/// ユーザープロフィール
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String username,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    required String favoriteRarity, // 好みのレアリティ
    required List<String> favoriteSeries, // 好みのシリーズ
    required int totalItems,
    required int totalValue,
    required DateTime createdAt,
    required DateTime lastUpdatedAt,
    required bool isPublic,
    required int followersCount,
    required int followingCount,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

/// フレンド
@freezed
class Friend with _$Friend {
  const factory Friend({
    required String friendId,
    required String userId,
    required String friendUserId,
    required String friendUsername,
    required String? friendAvatarUrl,
    required DateTime addedAt,
    required String status, // accepted, pending, blocked
    required int mutualFriends,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) =>
      _$FriendFromJson(json);
}

/// フレンドリクエスト
@freezed
class FriendRequest with _$FriendRequest {
  const factory FriendRequest({
    required String requestId,
    required String fromUserId,
    required String fromUsername,
    required String? fromAvatarUrl,
    required String toUserId,
    required DateTime sentAt,
    required String status, // pending, accepted, declined
    String? message,
  }) = _FriendRequest;

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestFromJson(json);
}

/// ユーザー統計
@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    required String userId,
    required int totalTrades,
    required int totalPurchases,
    required int totalSpent,
    required int itemsObtained,
    required int seriesCompleted,
    required double averageRating,
    required Map<String, int> itemsByRarity,
    required Map<String, int> itemsBySeries,
    required DateTime lastActive,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}

/// ユーザー実績
@freezed
class UserAchievement with _$UserAchievement {
  const factory UserAchievement({
    required String achievementId,
    required String userId,
    required String title,
    required String description,
    required String badge, // バッジアイコン
    required DateTime unlockedAt,
    required String category, // collection, trading, spending, etc.
  }) = _UserAchievement;

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserAchievementFromJson(json);
}

extension UserProfileExtension on UserProfile {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'favoriteRarity': favoriteRarity,
      'favoriteSeries': favoriteSeries,
      'totalItems': totalItems,
      'totalValue': totalValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isPublic': isPublic,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  /// DTOから変換
  static UserProfile fromDTO(Map<String, dynamic> dto) {
    return UserProfile(
      userId: dto['userId'] as String,
      username: dto['username'] as String,
      email: dto['email'] as String,
      displayName: dto['displayName'] as String?,
      avatarUrl: dto['avatarUrl'] as String?,
      bio: dto['bio'] as String?,
      favoriteRarity: dto['favoriteRarity'] as String? ?? 'SSR',
      favoriteSeries: List<String>.from(dto['favoriteSeries'] as List? ?? []),
      totalItems: dto['totalItems'] as int? ?? 0,
      totalValue: dto['totalValue'] as int? ?? 0,
      createdAt: (dto['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (dto['lastUpdatedAt'] as Timestamp).toDate(),
      isPublic: dto['isPublic'] as bool? ?? true,
      followersCount: dto['followersCount'] as int? ?? 0,
      followingCount: dto['followingCount'] as int? ?? 0,
    );
  }
}

extension FriendExtension on Friend {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'friendId': friendId,
      'userId': userId,
      'friendUserId': friendUserId,
      'friendUsername': friendUsername,
      'friendAvatarUrl': friendAvatarUrl,
      'addedAt': Timestamp.fromDate(addedAt),
      'status': status,
      'mutualFriends': mutualFriends,
    };
  }

  /// DTOから変換
  static Friend fromDTO(Map<String, dynamic> dto) {
    return Friend(
      friendId: dto['friendId'] as String,
      userId: dto['userId'] as String,
      friendUserId: dto['friendUserId'] as String,
      friendUsername: dto['friendUsername'] as String,
      friendAvatarUrl: dto['friendAvatarUrl'] as String?,
      addedAt: (dto['addedAt'] as Timestamp).toDate(),
      status: dto['status'] as String,
      mutualFriends: dto['mutualFriends'] as int? ?? 0,
    );
  }
}

extension UserStatsExtension on UserStats {
  /// FirestoreのDTOに変換
  Map<String, dynamic> toDTO() {
    return {
      'userId': userId,
      'totalTrades': totalTrades,
      'totalPurchases': totalPurchases,
      'totalSpent': totalSpent,
      'itemsObtained': itemsObtained,
      'seriesCompleted': seriesCompleted,
      'averageRating': averageRating,
      'itemsByRarity': itemsByRarity,
      'itemsBySeries': itemsBySeries,
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  /// DTOから変換
  static UserStats fromDTO(Map<String, dynamic> dto) {
    return UserStats(
      userId: dto['userId'] as String,
      totalTrades: dto['totalTrades'] as int? ?? 0,
      totalPurchases: dto['totalPurchases'] as int? ?? 0,
      totalSpent: dto['totalSpent'] as int? ?? 0,
      itemsObtained: dto['itemsObtained'] as int? ?? 0,
      seriesCompleted: dto['seriesCompleted'] as int? ?? 0,
      averageRating: (dto['averageRating'] as num? ?? 0).toDouble(),
      itemsByRarity: Map<String, int>.from(dto['itemsByRarity'] as Map? ?? {}),
      itemsBySeries: Map<String, int>.from(dto['itemsBySeries'] as Map? ?? {}),
      lastActive: (dto['lastActive'] as Timestamp).toDate(),
    );
  }
}
