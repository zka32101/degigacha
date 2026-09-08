import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gacha_item_model.dart';

/// アイテム詳細表示画面
///
/// ガチャアイテムの詳細情報を表示
/// レアリティ、シリーズ、取得日時、メモなど
class ItemDetailScreen extends ConsumerStatefulWidget {
  final GachaItem item;

  const ItemDetailScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  ConsumerState<ItemDetailScreen> createState() =>
      _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _memoController = TextEditingController(text: widget.item.notes ?? '');
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アイテム詳細'),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アイテム画像・プレビュー
              _buildImageSection(context),
              const SizedBox(height: 24),

              // 基本情報
              _buildBasicInfoSection(context),
              const SizedBox(height: 24),

              // レアリティ情報
              _buildRaritySection(context),
              const SizedBox(height: 24),

              // 取得情報
              _buildAcquisitionSection(context),
              const SizedBox(height: 24),

              // メモセクション
              _buildNotesSection(context),
              const SizedBox(height: 24),

              // アクションボタン
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.image,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'アイテム名',
              widget.item.itemName,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'シリーズ',
              widget.item.series,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'ID',
              widget.item.id,
              isCode: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaritySection(BuildContext context) {
    final rarityColor = _getRarityColor(widget.item.rarity);
    final rarityLabel = _getRarityLabel(widget.item.rarity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'レアリティ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                border: Border.all(color: rarityColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rarityLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: rarityColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Icon(
                    _getRarityIcon(widget.item.rarity),
                    color: rarityColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcquisitionSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '取得情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              '取得日',
              '${widget.item.dateAdded.year}年${widget.item.dateAdded.month}月${widget.item.dateAdded.day}日',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              '取得方法',
              widget.item.acquisitionMethod ?? '手動入力',
            ),
            if (widget.item.duplicateCount > 0) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                '重複数',
                '${widget.item.duplicateCount}個',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'メモ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'メモを入力...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // 共有機能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('共有機能: 実装予定')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('共有'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // 削除機能
              _showDeleteDialog(context);
            },
            icon: const Icon(Icons.delete),
            label: const Text('削除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isCode = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: isCode ? 'monospace' : null,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${widget.item.itemName}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('アイテムを削除しました')),
              );
            },
            child: Text(
              '削除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.n:
        return Colors.grey;
      case Rarity.r:
        return Colors.blue;
      case Rarity.sr:
        return Colors.purple;
      case Rarity.ssr:
        return const Color(0xFFFFD700);
    }
  }

  String _getRarityLabel(Rarity rarity) {
    switch (rarity) {
      case Rarity.n:
        return 'N（ノーマル）';
      case Rarity.r:
        return 'R（レア）';
      case Rarity.sr:
        return 'SR（スーパーレア）';
      case Rarity.ssr:
        return 'SSR（スーパースーパーレア）';
    }
  }

  IconData _getRarityIcon(Rarity rarity) {
    switch (rarity) {
      case Rarity.n:
        return Icons.star_border;
      case Rarity.r:
        return Icons.star_half;
      case Rarity.sr:
        return Icons.star;
      case Rarity.ssr:
        return Icons.stars;
    }
  }
}
