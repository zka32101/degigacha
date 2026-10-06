import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/models/user_profile_model.dart';

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final UserProfileRepository _repository;
  final String _userId;

  UserProfileNotifier({
    required UserProfileRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  Future<void> fetchUserProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserProfile(_userId)
        .then((profile) => profile ?? UserProfile(
          userId: _userId,
          username: 'Anonymous',
          email: '',
          favoriteRarity: 'SSR',
          favoriteSeries: [],
          totalItems: 0,
          totalValue: 0,
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
          isPublic: true,
          followersCount: 0,
          followingCount: 0,
        )));
  }

  Future<void> updateUserProfile({
    required String username,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? favoriteRarity,
    List<String>? favoriteSeries,
  }) async {
    await _repository.updateUserProfile(
      userId: _userId,
      username: username,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      favoriteRarity: favoriteRarity,
      favoriteSeries: favoriteSeries,
    );
    await fetchUserProfile();
  }
}

class UserFriendsNotifier extends StateNotifier<AsyncValue<List<Friend>>> {
  final UserProfileRepository _repository;
  final String _userId;

  UserFriendsNotifier({
    required UserProfileRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  Future<void> fetchFriendsList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getFriendsList(_userId));
  }

  Future<void> removeFriend(String friendUserId) async {
    await _repository.removeFriend(_userId, friendUserId);
    await fetchFriendsList();
  }
}

class FriendRequestsNotifier extends StateNotifier<AsyncValue<List<FriendRequest>>> {
  final UserProfileRepository _repository;
  final String _userId;

  FriendRequestsNotifier({
    required UserProfileRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  Future<void> fetchReceivedRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getReceivedFriendRequests(_userId));
  }

  Future<void> sendFriendRequest({
    required String toUserId,
    String? message,
  }) async {
    await _repository.sendFriendRequest(
      fromUserId: _userId,
      toUserId: toUserId,
      message: message,
    );
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUserId,
  }) async {
    await _repository.acceptFriendRequest(requestId, _userId, fromUserId);
    await fetchReceivedRequests();
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _repository.declineFriendRequest(requestId);
    await fetchReceivedRequests();
  }
}

class UserStatsNotifier extends StateNotifier<AsyncValue<UserStats>> {
  final UserProfileRepository _repository;
  final String _userId;

  UserStatsNotifier({
    required UserProfileRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  Future<void> fetchUserStats() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserStats(_userId)
        .then((stats) => stats ?? UserStats(
          userId: _userId,
          totalTrades: 0,
          totalPurchases: 0,
          totalSpent: 0,
          itemsObtained: 0,
          seriesCompleted: 0,
          averageRating: 0.0,
          itemsByRarity: {},
          itemsBySeries: {},
          lastActive: DateTime.now(),
        )));
  }

  Future<void> updateUserStats({
    required int totalTrades,
    required int totalPurchases,
    required int itemsObtained,
  }) async {
    await _repository.updateUserStats(
      userId: _userId,
      totalTrades: totalTrades,
      totalPurchases: totalPurchases,
      itemsObtained: itemsObtained,
    );
    await fetchUserStats();
  }
}

class UserAchievementsNotifier extends StateNotifier<AsyncValue<List<UserAchievement>>> {
  final UserProfileRepository _repository;
  final String _userId;

  UserAchievementsNotifier({
    required UserProfileRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AsyncValue.loading());

  Future<void> fetchUserAchievements() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserAchievements(_userId));
  }

  Future<void> unlockAchievement({
    required String title,
    required String description,
    required String badge,
    required String category,
  }) async {
    await _repository.unlockAchievement(
      userId: _userId,
      title: title,
      description: description,
      badge: badge,
      category: category,
    );
    await fetchUserAchievements();
  }
}
