import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/marketplace_model.dart';
import '../riverpod/providers.dart';

/// マーケットプレイス画面
class MarketplaceScreen extends ConsumerStatefulWidget {
  final String userId;

  const MarketplaceScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  String _selectedRarity = 'all';
  String _selectedSeries = 'all';

  final rarities = ['全部', '☆☆☆☆☆', '☆☆☆☆', '☆☆☆', '☆☆'];
  final rarityValues = ['all', 'SSR', 'SR', 'R', 'N'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allListingsProvider.notifier).loadListings();
      ref.read(marketplaceStatisticsProvider.notifier).loadStatistics();
    });
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
      child: DefaultTabController(
        length: 3,
        controller: _tabController,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('マーケットプレイス'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '全アイテム', icon: Icon(Icons.shopping_bag)),
                Tab(text: '購入履歴', icon: Icon(Icons.history)),
                Tab(text: '統計', icon: Icon(Icons.analytics)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAllItemsTab(),
              _buildPurchaseHistoryTab(),
              _buildStatisticsTab(),
            ],
          ),
        ),
      ),
    );
  }

  /// 全アイテムタブ
  Widget _buildAllItemsTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final listingsAsync = ref.watch(allListingsProvider);
              return listingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('エラー: $error'),
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'アイテムがありません',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }

                  final filtered = _filterListings(listings);

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      return _buildListingCard(filtered[index]);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// フィルターバー
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // レアリティフィルター
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: rarities.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedRarity == rarityValues[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(rarities[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRarity = rarityValues[index];
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// リスティングカード
  Widget _buildListingCard(MarketListing listing) {
    final rarityColor = _getRarityColor(listing.rarity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showPurchaseDialog(listing),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // アイテム情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.itemName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rarityColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                listing.rarity,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              listing.series,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 価格と数量
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${listing.price} G',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '在庫: ${listing.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // セラー情報
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'セラー: ${listing.sellerName}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${listing.sellerRating.toStringAsFixed(1)} (${listing.soldCount})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showPurchaseDialog(listing),
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('購入'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 購入ダイアログ
  void _showPurchaseDialog(MarketListing listing) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(listing.itemName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('価格: ${listing.price} G'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('数量:'),
                StatefulBuilder(
                  builder: (context, setState) => Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () {
                          setState(() => quantity--);
                        }
                            : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: quantity < listing.quantity
                            ? () {
                          setState(() => quantity++);
                        }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '合計: ${listing.price * quantity} G',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(transactionHistoryProvider(widget.userId).notifier)
                  .purchaseItem(
                listingId: listing.listingId,
                buyerId: widget.userId,
                sellerId: listing.sellerId,
                itemId: listing.itemId,
                itemName: listing.itemName,
                quantity: quantity,
                pricePerUnit: listing.price,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('購入しました')),
              );
            },
            child: const Text('購入'),
          ),
        ],
      ),
    );
  }

  /// 購入履歴タブ
  Widget _buildPurchaseHistoryTab() {
    return Consumer(
      builder: (context, ref, _) {
        final transactionsAsync =
            ref.watch(transactionHistoryProvider(widget.userId));
        return transactionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('エラー: $error'),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'トランザクションがありません',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: transactions.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                return _buildTransactionCard(transactions[index]);
              },
            );
          },
        );
      },
    );
  }

  /// トランザクションカード
  Widget _buildTransactionCard(MarketTransaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.itemName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: transaction.status == 'completed'
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.status,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '数量: ${transaction.quantity} × ${transaction.pricePerUnit} G',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '合計: ${transaction.totalPrice} G',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(transaction.purchasedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// 統計タブ
  Widget _buildStatisticsTab() {
    return Consumer(
      builder: (context, ref, _) {
        final statsAsync = ref.watch(marketplaceStatisticsProvider);
        return statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('エラー: $error'),
          ),
          data: (stats) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 概要統計
                  _buildStatisticsSummary(stats),
                  const SizedBox(height: 24),
                  // レアリティ別統計
                  Text(
                    'レアリティ別',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildRarityStatistics(stats),
                  const SizedBox(height: 24),
                  // シリーズ別統計
                  Text(
                    'シリーズ別',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildSeriesStatistics(stats),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 統計サマリー
  Widget _buildStatisticsSummary(MarketplaceStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: 'リスティング数',
            value: '${stats.totalListings}',
            icon: Icons.storefront,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatItem(
            label: 'トランザクション',
            value: '${stats.totalTransactions}',
            icon: Icons.receipt,
          ),
        ),
      ],
    );
  }

  /// レアリティ別統計
  Widget _buildRarityStatistics(MarketplaceStatistics stats) {
    return Column(
      children: stats.listingsByRarity.entries.map((entry) {
        final rarity = entry.key;
        final count = entry.value;
        final avgPrice = stats.avgPriceByRarity[rarity] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRarityColor(rarity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rarity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('出品数: $count'),
                    Text(
                      '平均価格: ${avgPrice.toStringAsFixed(0)} G',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// シリーズ別統計
  Widget _buildSeriesStatistics(MarketplaceStatistics stats) {
    final seriesList = stats.listingsBySeries.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: seriesList.take(5).map((entry) {
        final series = entry.key;
        final count = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(series),
              Text('$count出品'),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// フィルター適用
  List<MarketListing> _filterListings(List<MarketListing> listings) {
    return listings.where((listing) {
      if (_selectedRarity != 'all' && listing.rarity != _selectedRarity) {
        return false;
      }
      return true;
    }).toList();
  }

  /// レアリティ色取得
  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'SSR':
        return Colors.purple;
      case 'SR':
        return Colors.orange;
      case 'R':
        return Colors.blue;
      case 'N':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 日付フォーマット
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 統計アイテム
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
