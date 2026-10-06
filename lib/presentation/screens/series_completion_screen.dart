import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../riverpod/providers.dart';
import '../../data/models/gacha_series_model.dart';
import '../../data/models/gacha_item_model.dart';

/// シリーズ完成度追跡画面
///
/// 特定のシリーズの完成度と不足アイテムを表示
/// コレクション目標管理
class SeriesCompletionScreen extends ConsumerStatefulWidget {
  final String seriesId;
  final String userId;

  const SeriesCompletionScreen({
    Key? key,
    required this.seriesId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<SeriesCompletionScreen> createState() =>
      _SeriesCompletionScreenState();
}

class _SeriesCompletionScreenState
    extends ConsumerState<SeriesCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implement series completion data fetching
    // For now, using mock data structure
    return Scaffold(
      appBar: AppBar(
        title: const Text('シリーズ完成度'),
        centerTitle: true,
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 完成度サマリー
          _buildCompletionSummary(context),
          const SizedBox(height: 24),

          // 完成度詳細
          _buildCompletionDetails(context),
          const SizedBox(height: 24),

          // 不足アイテム
          _buildMissingItems(context),
          const SizedBox(height: 24),

          // リコメンデーション
          _buildRecommendations(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompletionSummary(BuildContext context) {
    const completionPercent = 75;
    const collectedCount = 15;
    const totalCount = 20;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 大きな進捗バー
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: completionPercent / 100,
                      strokeWidth: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$completionPercent%',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '完成度',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 収集数
              Text(
                '$collectedCount / $totalCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'アイテム収集済み',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '詳細情報',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'N（ノーマル）',
                    5,
                    5,
                    Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'R（レア）',
                    5,
                    5,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'SR（スーパーレア）',
                    4,
                    6,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'SSR（最高レア）',
                    1,
                    4,
                    const Color(0xFFFFD700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    int collected,
    int total,
    Color color,
  ) {
    final percent = (collected / total * 100).toStringAsFixed(1);
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: collected / total,
                  minHeight: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$collected/$total ($percent%)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissingItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '不足アイテム',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // SR不足アイテム
                  _buildMissingItemRow(
                    context,
                    'SR レアキャラA',
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildMissingItemRow(
                    context,
                    'SR レアキャラB',
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),

                  // SSR不足アイテム
                  _buildMissingItemRow(
                    context,
                    'SSR 限定キャラ（3個不足）',
                    const Color(0xFFFFD700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItemRow(
    BuildContext context,
    String itemName,
    Color rarityColor,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: rarityColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            itemName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'おすすめ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SSR キャラ獲得で 95% に！',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'あと 3 個の SSR 限定キャラを集めるだけで、このシリーズはほぼ完成です！',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // ガチャ画面に遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ガチャ画面へ移動')),
                        );
                      },
                      child: const Text('ガチャを引く'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
