import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../riverpod/providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final String userId;

  const FriendsScreen({
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsyncValue = ref.watch(userFriendsProvider(widget.userId));
    final requestsAsyncValue = ref.watch(friendRequestsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'フレンド一覧'),
            Tab(text: 'フレンドリクエスト'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsListTab(friendsAsyncValue),
          _buildRequestsTab(requestsAsyncValue),
        ],
      ),
    );
  }

  Widget _buildFriendsListTab(AsyncValue<List<Friend>> friendsAsyncValue) {
    return friendsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
      data: (friends) {
        if (friends.isEmpty) {
          return const Center(
            child: Text('フレンドがまだいません'),
          );
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendTile(friend);
          },
        );
      },
    );
  }

  Widget _buildFriendTile(Friend friend) {
    return ListTile(
      leading: friend.friendAvatarUrl != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(friend.friendAvatarUrl!),
            )
          : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(friend.friendUsername),
      subtitle: Text('相互フレンド: ${friend.mutualFriends}'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Text('削除'),
            onTap: () => _showRemoveFriendDialog(friend),
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendDialog(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${friend.friendUsername}を削除しますか？'),
        content: const Text('このアクションは取り消せません'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(userFriendsProvider(widget.userId).notifier)
                  .removeFriend(friend.friendUserId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('フレンドを削除しました')),
              );
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(AsyncValue<List<FriendRequest>> requestsAsyncValue) {
    return requestsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(
            child: Text('フレンドリクエストがありません'),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestTile(request);
          },
        );
      },
    );
  }

  Widget _buildRequestTile(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: request.fromAvatarUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(request.fromAvatarUrl!),
              )
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(request.fromUsername),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.message != null && request.message!.isNotEmpty)
              Text(
                request.message!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _acceptFriendRequest(request),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _declineFriendRequest(request),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptFriendRequest(FriendRequest request) {
    ref
        .read(friendRequestsProvider(widget.userId).notifier)
        .acceptFriendRequest(
          requestId: request.requestId,
          fromUserId: request.fromUserId,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('フレンドリクエストを受け入れました')),
    );
  }

  void _declineFriendRequest(FriendRequest request) {
    ref
        .read(friendRequestsProvider(widget.userId).notifier)
        .declineFriendRequest(request.requestId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('フレンドリクエストを拒否しました')),
    );
  }
}
