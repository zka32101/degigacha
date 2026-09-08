import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../riverpod/providers.dart';
import '../../data/models/gacha_item_model.dart';
import 'item_detail_screen.dart';

/// コレクション表示画面（改善版 - Phase 6A）
///
/// 特定のシリーズに属するガチャアイテムを表示します。
/// ソート・フィルタ機能、GridView/ListView切り替え、詳細表示を実装。
class CollectionDisplayScreenEnhanced extends ConsumerStatefulWidget {
  final String seriesId;

  const CollectionDisplayScreenEnhanced({
    Key? key,
    required this.seriesId,
  }) : super(key: key);

  @override
  ConsumerState<CollectionDisplayScreenEnhanced> createState() =>
      _CollectionDisplayScreenEnhancedState();
}

class _CollectionDisplayScreenEnhancedState
    extends ConsumerState<CollectionDisplayScreenEnhanced> {
  // ソート・フィルタ状態
  late SortOption _sortOption;
  late Set<Rarity> _rarityFilter;
  late bool _showOnlyCollected;
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _sortOption = SortOption.dateAdded;
    _rarityFilter = {Rarity.n, Rarity.r, Rarity.sr, Rarity.ssr};
    _showOnlyCollected = false;
    _isGridView = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesByIdProvider(widget.seriesId));
    final selectedSeries = ref.watch(selectedSeriesProvider);

    return seriesAsync.when(
      data: (series) {
        final displayedSeries = selectedSeries ?? series;

        return Scaffold(
          appBar: AppBar(
            title: Text(displayedSeries.name),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/onboarding'),
            ),
            actions: [
              // GridView/ListView切り替え
              IconButton(
                icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_3x3),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                tooltip: _isGridView ? 'リストビュー' : 'グリッドビュー',
              ),
              // フィルタ・ソートメニュー
              PopupMenuButton<String>(
                onSelected: (value) {
                  _handleMenuSelection(value);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'sort_date',
                    child: Text('獲得日時でソート'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sort_rarity',
                    child: Text('レアリティでソート'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sort_name',
                    child: Text('名前でソート'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'filter_rarity',
                    child: Text('レアリティでフィルタ'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'filter_collected',
                    child: Text('所持のみ表示'),
                  ),
                ],
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          body: _buildEnhancedContent(context, ref, displayedSeries),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('読み込み中...'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/onboarding'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('エラー'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/onboarding'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'シリーズが見つかりません',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('シリーズ選択に戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// メニュー選択処理
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'sort_date':
        setState(() => _sortOption = SortOption.dateAdded);
        break;
      case 'sort_rarity':
        setState(() => _sortOption = SortOption.rarity);
        break;
      case 'sort_name':
        setState(() => _sortOption = SortOption.name);
        break;
      case 'filter_rarity':
        _showRarityFilterDialog();
        break;
      case 'filter_collected':
        setState(() => _showOnlyCollected = !_showOnlyCollected);
        break;
    }
  }

  /// レアリティフィルタダイアログ
  void _showRarityFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レアリティでフィルタ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Rarity.values
              .map((rarity) => CheckboxListTile(
                    title: Text(rarity.value),
                    value: _rarityFilter.contains(rarity),
                    onChanged: (value) {
                      setState(() {
                        if (value ?? false) {
                          _rarityFilter.add(rarity);
                        } else {
                          _rarityFilter.remove(rarity);
                        }
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// 改善されたコンテンツビルダー
  Widget _buildEnhancedContent(
    BuildContext context,
    WidgetRef ref,
    dynamic series,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // シリーズ情報ヘッダー
          _buildSeriesHeader(context, series),

          // コレクション統計
          _buildStatistics(context, series),

          // アクションボタン
          _buildActionButtons(context),

          const SizedBox(height: 24),

          // ソート・フィルタ表示バー
          _buildFilterBar(context),

          const SizedBox(height: 16),

          // アイテムグリッド/リスト表示
          _buildItemsList(context),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  /// シリーズヘッダー
  Widget _buildSeriesHeader(BuildContext context, dynamic series) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.collections_bookmark,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            series.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            series.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          // 進捗バー（改善版）
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: series.collectedItems / series.totalItems,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${series.collectedItems} / ${series.totalItems} (${((series.collectedItems / series.totalItems) * 100).toStringAsFixed(1)}%)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// 統計情報
  Widget _buildStatistics(BuildContext context, dynamic series) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'コレクション統計',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                label: '所持数',
                value: '${series.collectedItems}',
                icon: Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              _StatCard(
                label: '完成度',
                value:
                    '${((series.collectedItems / series.totalItems) * 100).toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: Theme.of(context).colorScheme.secondary,
              ),
              _StatCard(
                label: '残り',
                value: '${series.totalItems - series.collectedItems}',
                icon: Icons.playlist_add,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/capture'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('ガチャを撮る'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/series-completion/${widget.seriesId}'),
              icon: const Icon(Icons.assessment),
              label: const Text('シリーズ完成度を見る'),
            ),
          ),
        ],
      ),
    );
  }

  /// ソート・フィルタ表示バー
  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'フィルタ・ソート設定',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // ソート表示
              Chip(
                label: Text('ソート: ${_getSortLabel()}'),
                onDeleted: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('ソート順序'),
                      children: SortOption.values
                          .map((option) => SimpleDialogOption(
                                onPressed: () {
                                  setState(() => _sortOption = option);
                                  Navigator.pop(context);
                                },
                                child: Text(_getSortLabel(option)),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
              // レアリティフィルタ表示
              Chip(
                label: Text(
                  'レアリティ: ${_rarityFilter.length}個',
                ),
                onDeleted: _showRarityFilterDialog,
              ),
              // 所持フィルタ
              if (_showOnlyCollected)
                Chip(
                  label: const Text('所持のみ'),
                  onDeleted: () {
                    setState(() => _showOnlyCollected = false);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// アイテムリスト/グリッド表示
  Widget _buildItemsList(BuildContext context) {
    // TODO: アイテムデータを取得してフィルタ・ソート処理
    // 現在はプレースホルダー表示
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: _isGridView
          ? _buildGridView(context)
          : _buildListView(context),
    );
  }

  /// グリッドビュー
  Widget _buildGridView(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(
        12,
        (index) => _buildItemCard(context, index),
      ),
    );
  }

  /// リストビュー
  Widget _buildListView(BuildContext context) {
    return Column(
      children: List.generate(
        12,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildItemListTile(context, index),
        ),
      ),
    );
  }

  /// アイテムカード（グリッド用）
  Widget _buildItemCard(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        final mockItem = _createMockGachaItem(index);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(item: mockItem),
          ),
        );
      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Item ${index + 1}',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRarityColor(index, context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getRarityLabel(index),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// アイテムリスト行（リスト用）
  Widget _buildItemListTile(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        final mockItem = _createMockGachaItem(index);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(item: mockItem),
          ),
        );
      },
      child: Card(
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text('Item ${index + 1}'),
          subtitle: Text(_getRarityLabel(index)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRarityColor(index, context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getRarityLabel(index),
              style: TextStyle(
                color: _getRarityColor(index, context),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ユーティリティ: ソートラベル取得
  String _getSortLabel([SortOption? option]) {
    switch (option ?? _sortOption) {
      case SortOption.dateAdded:
        return '獲得日時';
      case SortOption.rarity:
        return 'レアリティ';
      case SortOption.name:
        return '名前';
    }
  }

  /// ユーティリティ: レアリティラベル取得
  String _getRarityLabel(int index) {
    final rarities = ['N', 'R', 'SR', 'SSR'];
    return rarities[index % rarities.length];
  }

  /// ユーティリティ: レアリティ色取得
  Color _getRarityColor(int index, BuildContext context) {
    switch (index % 4) {
      case 0: // N
        return Colors.grey[600] ?? Colors.grey;
      case 1: // R
        return Colors.blue[600] ?? Colors.blue;
      case 2: // SR
        return Colors.purple[600] ?? Colors.purple;
      case 3: // SSR
        return Colors.amber[700] ?? Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// ユーティリティ: モック GachaItem を作成
  GachaItem _createMockGachaItem(int index) {
    final rarities = [Rarity.n, Rarity.r, Rarity.sr, Rarity.ssr];
    final rarity = rarities[index % rarities.length];

    return GachaItem(
      id: 'item_${widget.seriesId}_$index',
      itemName: 'アイテム ${index + 1}',
      series: widget.seriesId,
      rarity: rarity,
      dateAdded: DateTime.now().subtract(Duration(days: index)),
      acquisitionMethod: 'ガチャ',
      duplicateCount: index % 3,
      notes: 'このアイテムについてのメモです。',
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          ),
        ],
      ),
    );
  }
}

/// ソートオプション
enum SortOption {
  dateAdded,
  rarity,
  name,
}
