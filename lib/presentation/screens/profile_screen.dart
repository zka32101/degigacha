import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../riverpod/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(userProfileProvider(widget.userId));
    final statsAsyncValue = ref.watch(userStatsProvider(widget.userId));
    final achievementsAsyncValue = ref.watch(userAchievementsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'プロフィール'),
            Tab(text: '統計'),
            Tab(text: '実績'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(profileAsyncValue),
          _buildStatsTab(statsAsyncValue),
          _buildAchievementsTab(achievementsAsyncValue),
        ],
      ),
    );
  }

  Widget _buildProfileTab(AsyncValue<UserProfile> profileAsyncValue) {
    return profileAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
      data: (profile) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (profile.avatarUrl != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profile.avatarUrl!),
                )
              else
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person),
                ),
              const SizedBox(height: 16),
              Text(
                profile.displayName ?? profile.username,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '@${profile.username}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (profile.bio != null && profile.bio!.isNotEmpty)
                Text(profile.bio!),
              const SizedBox(height: 24),
              _buildProfileStatsRow(profile),
              const SizedBox(height: 24),
              _buildPreferencesSection(profile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileStatsRow(UserProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('総アイテム', profile.totalItems.toString()),
        _buildStatCard('総価値', '¥${profile.totalValue}'),
        _buildStatCard('フォロワー', profile.followersCount.toString()),
        _buildStatCard('フォロー中', profile.followingCount.toString()),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '好み',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text('好みのレアリティ: ${profile.favoriteRarity}'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (profile.favoriteSeries.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '好みのシリーズ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: profile.favoriteSeries
                    .map((series) => Chip(label: Text(series)))
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsTab(AsyncValue<UserStats> statsAsyncValue) {
    return statsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatSection('取引統計', [
                ('総トレード数', stats.totalTrades.toString()),
                ('総購入数', stats.totalPurchases.toString()),
                ('総使用金額', '¥${stats.totalSpent}'),
              ]),
              const SizedBox(height: 24),
              _buildStatSection('収集統計', [
                ('獲得アイテム', stats.itemsObtained.toString()),
                ('完了シリーズ', stats.seriesCompleted.toString()),
                ('平均評価', '${stats.averageRating.toStringAsFixed(2)}'),
              ]),
              const SizedBox(height: 24),
              if (stats.itemsByRarity.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'レアリティ別アイテム',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...stats.itemsByRarity.entries.map((entry) =>
                        _buildStatItem(entry.key, entry.value.toString())),
                  ],
                ),
              const SizedBox(height: 24),
              if (stats.itemsBySeries.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'シリーズ別アイテム',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...stats.itemsBySeries.entries.map((entry) =>
                        _buildStatItem(entry.key, entry.value.toString())),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatSection(String title, List<(String, String)> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...stats.map((stat) => _buildStatItem(stat.$1, stat.$2)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(AsyncValue<List<UserAchievement>> achievementsAsyncValue) {
    return achievementsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラー: $error'),
      ),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const Center(
            child: Text('実績がまだありません'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _buildAchievementCard(achievement);
          },
        );
      },
    );
  }

  Widget _buildAchievementCard(UserAchievement achievement) {
    return Card(
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.badge,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(UserAchievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                achievement.badge,
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'カテゴリ: ${achievement.category}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
