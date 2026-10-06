import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../riverpod/providers.dart';

/// 重複アイテム管理画面
///
/// ユーザーのコレクション内の重複アイテムを管理する画面
/// - 重複統計情報の表示
/// - 重複アイテム一覧
/// - レアリティ別・シリーズ別フィルタリング
class DuplicateManagementScreen extends ConsumerStatefulWidget {
  final String userId;

  const DuplicateManagementScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<DuplicateManagementScreen> createState() =>
      _DuplicateManagementScreenState();
}

class _DuplicateManagementScreenState
    extends ConsumerState<DuplicateManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statisticsAsync = ref.watch(duplicateStatisticsProvider(widget.userId));
    final duplicatesAsync = ref.watch(duplicateDetectionProvider(widget.userId));

    return FadeTransition(
      opacity: _animationController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('重複アイテム管理'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '統計情報'),
              Tab(text: '全アイテム'),
              Tab(text: 'リクエスト'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // 統計情報タブ
            _buildStatisticsTab(context, statisticsAsync, duplicatesAsync),

            // 全アイテムタブ
            _buildAllItemsTab(context, duplicatesAsync),

            // リクエストタブ
            _buildRequestsTab(context),
          ],
        ),
      ),
    );
  }

  /// 統計情報タブ
  Widget _buildStatisticsTab(
    BuildContext context,
    AsyncValue statisticsAsync,
    AsyncValue duplicatesAsync,
  ) {
    return statisticsAsync.when(
      data: (statistics) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // サマリーカード
              _buildSummaryCard(context, statistics),
              const SizedBox(height: 24),

              // レアリティ別統計
              _buildRarityStatistics(context, statistics),
              const SizedBox(height: 24),

              // シリーズ別統計
              _buildSeriesStatistics(context, statistics),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }

  /// サマリーカード
  Widget _buildSummaryCard(BuildContext context, dynamic statistics) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                '重複統計',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: '重複アイテム数',
                    value: '${statistics.totalDuplicateItems}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _StatItem(
                    label: '重複総数',
                    value: '${statistics.totalDuplicateCount}',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatItem(
                    label: '平均重複数',
                    value: '${statistics.averageDuplicateCount.toStringAsFixed(1)}',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// レアリティ別統計
  Widget _buildRarityStatistics(BuildContext context, dynamic statistics) {
    final rarityColors = {
      'N': Colors.grey[600],
      'R': Colors.blue[600],
      'SR': Colors.purple[600],
      'SSR': Colors.amber[700],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'レアリティ別重複',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: (statistics.duplicateCountByRarity as Map).entries
                    .map((entry) {
                  final rarity = entry.key as String;
                  final count = entry.value as int;
                  final color = rarityColors[rarity] ?? Colors.grey;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildRarityRow(context, rarity, count, color),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// レアリティ行
  Widget _buildRarityRow(
    BuildContext context,
    String rarity,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            rarity,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '× $count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  /// シリーズ別統計
  Widget _buildSeriesStatistics(BuildContext context, dynamic statistics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'シリーズ別重複',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: (statistics.duplicateCountBySeries as Map).isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'シリーズ別の重複アイテムはありません',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : Column(
                      children: (statistics.duplicateCountBySeries as Map)
                          .entries
                          .map((entry) {
                        final series = entry.key as String;
                        final count = entry.value as int;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                series,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '× $count',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 全アイテムタブ
  Widget _buildAllItemsTab(BuildContext context, AsyncValue duplicatesAsync) {
    return duplicatesAsync.when(
      data: (duplicates) {
        if (duplicates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '重複アイテムはありません',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'コレクションが完全です！',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: duplicates.length,
          itemBuilder: (context, index) {
            final duplicate = duplicates[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildDuplicateItemCard(context, duplicate),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }

  /// 重複アイテムカード
  Widget _buildDuplicateItemCard(BuildContext context, dynamic duplicate) {
    final rarityColors = {
      'N': Colors.grey[600],
      'R': Colors.blue[600],
      'SR': Colors.purple[600],
      'SSR': Colors.amber[700],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        duplicate.itemName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        duplicate.series,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (rarityColors[duplicate.rarity] ?? Colors.grey)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    duplicate.rarity,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: rarityColors[duplicate.rarity] ?? Colors.grey,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('重複数:'),
                  Text(
                    '${duplicate.duplicateCount}個',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// リクエストタブ
  Widget _buildRequestsTab(BuildContext context) {
    final receivedAsync = ref.watch(receivedExchangeRequestsProvider(widget.userId));

    return receivedAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '交換リクエストがありません',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildRequestCard(context, request),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }

  /// リクエストカード
  Widget _buildRequestCard(BuildContext context, dynamic request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '交換リクエスト',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'ユーザーから交換リクエストを受けています',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('リクエストをキャンセルしました')),
                    );
                  },
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('リクエストを承認しました')),
                    );
                  },
                  child: const Text('承認'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 統計アイテム
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
