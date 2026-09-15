import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../riverpod/providers.dart';

/// トレード画面
///
/// ユーザー間のトレード機能を管理する画面
/// - トレード要求の表示・管理
/// - トレード履歴
/// - トレード統計
class TradingScreen extends ConsumerStatefulWidget {
  final String userId;

  const TradingScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends ConsumerState<TradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    return FadeTransition(
      opacity: _animationController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('トレード'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '受け取り'),
              Tab(text: '送信'),
              Tab(text: '履歴'),
              Tab(text: '統計'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // 受け取ったトレード要求タブ
            _buildReceivedRequestsTab(context),

            // 送信したトレード要求タブ
            _buildSentRequestsTab(context),

            // トレード履歴タブ
            _buildTradeHistoryTab(context),

            // トレード統計タブ
            _buildStatisticsTab(context),
          ],
        ),
      ),
    );
  }

  /// 受け取ったトレード要求タブ
  Widget _buildReceivedRequestsTab(BuildContext context) {
    final requestsAsync = ref.watch(receivedTradeRequestsProvider(widget.userId));

    return requestsAsync.when(
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
                  'トレード要求がありません',
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
              child: _buildTradeRequestCard(context, request, isReceived: true),
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

  /// 送信したトレード要求タブ
  Widget _buildSentRequestsTab(BuildContext context) {
    final requestsAsync = ref.watch(sentTradeRequestsProvider(widget.userId));

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '送信中のトレード要求がありません',
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
              child: _buildTradeRequestCard(context, request, isReceived: false),
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

  /// トレード履歴タブ
  Widget _buildTradeHistoryTab(BuildContext context) {
    final historyAsync = ref.watch(tradeHistoryProvider(widget.userId));

    return historyAsync.when(
      data: (histories) {
        if (histories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'トレード履歴がありません',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: histories.length,
          itemBuilder: (context, index) {
            final history = histories[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTradeHistoryCard(context, history),
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

  /// トレード統計タブ
  Widget _buildStatisticsTab(BuildContext context) {
    final statisticsAsync = ref.watch(tradeStatisticsProvider(widget.userId));

    return statisticsAsync.when(
      data: (statistics) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // サマリーカード
              _buildStatisticsSummary(context, statistics),
              const SizedBox(height: 24),

              // レアリティ別統計
              _buildRarityStatistics(context, statistics),
              const SizedBox(height: 24),

              // よくトレードする相手
              _buildFavoritePartners(context, statistics),
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

  /// トレード要求カード
  Widget _buildTradeRequestCard(
    BuildContext context,
    dynamic request, {
    required bool isReceived,
  }) {
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
                        'トレード要求',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${request.requestId.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: request.status == 'pending'
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status == 'pending' ? '保留中' : request.status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: request.status == 'pending'
                              ? Colors.orange[700]
                              : Colors.blue[700],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (request.message != null) ...[
              Text(
                'メッセージ:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                request.message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isReceived)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('キャンセルしました')),
                      );
                    },
                    child: const Text('キャンセル'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('却下しました')),
                      );
                    },
                    child: const Text('却下'),
                  ),
                const SizedBox(width: 12),
                if (isReceived)
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('承認しました')),
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

  /// トレード履歴カード
  Widget _buildTradeHistoryCard(BuildContext context, dynamic history) {
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
                        history.item1Name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        history.item1Rarity,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.compare_arrows,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        history.item2Name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        history.item2Rarity,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '完了日: ${history.completedAt.year}年${history.completedAt.month}月${history.completedAt.day}日',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  /// 統計サマリー
  Widget _buildStatisticsSummary(BuildContext context, dynamic statistics) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'トレード統計',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: '完了トレード',
                    value: '${statistics.completedTrades}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _StatItem(
                    label: '保留中',
                    value: '${statistics.pendingTrades}',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatItem(
                    label: '交換アイテム',
                    value: '${statistics.totalItemsTraded}',
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
            'レアリティ別トレード',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: (statistics.tradesByRarity as Map).isEmpty
                  ? Text(
                      'トレード履歴がありません',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Column(
                      children: (statistics.tradesByRarity as Map)
                          .entries
                          .map((entry) {
                        final rarity = entry.key as String;
                        final count = entry.value as int;
                        final color = rarityColors[rarity] ?? Colors.grey;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
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

  /// よくトレードする相手
  Widget _buildFavoritePartners(BuildContext context, dynamic statistics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'よくトレードする相手',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: (statistics.favoriteTradePartners as List).isEmpty
                  ? Text(
                      'トレード相手がいません',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Column(
                      children: (statistics.favoriteTradePartners as List)
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key + 1;
                        final partnerId = entry.value as String;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$index',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'ユーザー ID: ${partnerId.substring(0, 8)}...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
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
