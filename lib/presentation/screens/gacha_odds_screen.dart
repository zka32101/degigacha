import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ガチャ確率表示・シミュレータ画面 (Phase 6A UI/UX最終)
///
/// 機能：
/// - ガチャ確率の可視化（表形式・円グラフ）
/// - シミュレータ（「○回引いたら？」）
/// - 獲得予想（「このキャラを獲得するまで」）
class GachaOddsScreen extends ConsumerStatefulWidget {
  final String? seriesId;

  const GachaOddsScreen({
    Key? key,
    this.seriesId,
  }) : super(key: key);

  @override
  ConsumerState<GachaOddsScreen> createState() => _GachaOddsScreenState();
}

class _GachaOddsScreenState extends ConsumerState<GachaOddsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _simulationCount = 10;
  double _targetProbability = 0.03; // SSR確率 3%

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ確率'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '確率表'),
            Tab(text: 'シミュレータ'),
            Tab(text: '獲得予想'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // タブ1: 確率表表示
          _buildOddsTable(context),
          // タブ2: シミュレータ
          _buildSimulator(context),
          // タブ3: 獲得予想
          _buildTargetCalculator(context),
        ],
      ),
    );
  }

  /// 確率表表示
  Widget _buildOddsTable(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'レアリティ別確率',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // 円グラフ表示（簡易版）
            _buildOddsVisualization(context),
            const SizedBox(height: 32),
            // 詳細テーブル
            Text(
              '詳細確率',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildOddsDetailTable(context),
            const SizedBox(height: 24),
            // 説明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '※ こちらの確率は例示です。\n実際のガチャシステムはゲーム側の設定に従います。',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 確率ビジュアライゼーション（円グラフ風）
  Widget _buildOddsVisualization(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 簡易円グラフ（カラーリング）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOddsPie('N', 0.46, Colors.grey[600] ?? Colors.grey),
                _buildOddsPie('R', 0.34, Colors.blue[600] ?? Colors.blue),
                _buildOddsPie('SR', 0.17, Colors.purple[600] ?? Colors.purple),
                _buildOddsPie('SSR', 0.03, Colors.amber[700] ?? Colors.amber),
              ],
            ),
            const SizedBox(height: 24),
            // 凡例
            Column(
              children: [
                _buildLegendItem('N (通常)', 46, Colors.grey[600]),
                _buildLegendItem('R (レア)', 34, Colors.blue[600]),
                _buildLegendItem('SR (スーパーレア)', 17,
                    Colors.purple[600]),
                _buildLegendItem('SSR (スーパースーパーレア)', 3,
                    Colors.amber[700]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 確率円パイス
  Widget _buildOddsPie(String label, double percentage, Color color) {
    final size = 20.0 + (percentage * 100);
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  /// 凡例アイテム
  Widget _buildLegendItem(String label, int percentage, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $percentage%',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  /// 確率詳細テーブル
  Widget _buildOddsDetailTable(BuildContext context) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      children: [
        // ヘッダー
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          children: [
            _buildTableCell('レアリティ', isHeader: true),
            _buildTableCell('確率', isHeader: true),
            _buildTableCell('期待値', isHeader: true),
          ],
        ),
        // N
        TableRow(
          children: [
            _buildTableCell('N (通常)'),
            _buildTableCell('46%'),
            _buildTableCell('46/100'),
          ],
        ),
        // R
        TableRow(
          children: [
            _buildTableCell('R (レア)'),
            _buildTableCell('34%'),
            _buildTableCell('34/100'),
          ],
        ),
        // SR
        TableRow(
          children: [
            _buildTableCell('SR (スーパーレア)'),
            _buildTableCell('17%'),
            _buildTableCell('17/100'),
          ],
        ),
        // SSR
        TableRow(
          children: [
            _buildTableCell('SSR (スーパースーパーレア)'),
            _buildTableCell('3%'),
            _buildTableCell('3/100'),
          ],
        ),
      ],
    );
  }

  /// テーブルセル
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: isHeader
            ? Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
            : Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  /// シミュレータ
  Widget _buildSimulator(BuildContext context) {
    final result = _calculateSimulation(_simulationCount);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ガチャシミュレータ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            // 引く回数入力
            Text(
              '引く回数: $_simulationCount 回',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Slider(
              value: _simulationCount.toDouble(),
              min: 1,
              max: 500,
              divisions: 49,
              label: '$_simulationCount回',
              onChanged: (value) {
                setState(() {
                  _simulationCount = value.toInt();
                });
              },
            ),
            const SizedBox(height: 32),
            // 結果表示
            Text(
              'シミュレーション結果',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSimulationResults(context, result),
            const SizedBox(height: 24),
            // 説明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '結果はシミュレーションです。\n実際のガチャ結果とは異なる場合があります。',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// シミュレーション結果表示
  Widget _buildSimulationResults(
    BuildContext context,
    Map<String, int> result,
  ) {
    return Column(
      children: [
        _buildResultCard(
          context,
          'SSR (スーパースーパーレア)',
          result['ssr'] ?? 0,
          Colors.amber[700],
        ),
        const SizedBox(height: 12),
        _buildResultCard(
          context,
          'SR (スーパーレア)',
          result['sr'] ?? 0,
          Colors.purple[600],
        ),
        const SizedBox(height: 12),
        _buildResultCard(
          context,
          'R (レア)',
          result['r'] ?? 0,
          Colors.blue[600],
        ),
        const SizedBox(height: 12),
        _buildResultCard(
          context,
          'N (通常)',
          result['n'] ?? 0,
          Colors.grey[600],
        ),
      ],
    );
  }

  /// 結果カード
  Widget _buildResultCard(
    BuildContext context,
    String label,
    int count,
    Color? color,
  ) {
    final percentage = (count / _simulationCount * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color?.withOpacity(0.5) ?? Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            '$count回 ($percentage%)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  /// 獲得予想計算
  Widget _buildTargetCalculator(BuildContext context) {
    final expectedPulls = _calculateExpectedPulls(_targetProbability);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'キャラ獲得予想',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'ターゲット確率: ${(_targetProbability * 100).toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Slider(
              value: _targetProbability,
              min: 0.001,
              max: 0.5,
              divisions: 99,
              label:
                  '${(_targetProbability * 100).toStringAsFixed(2)}%',
              onChanged: (value) {
                setState(() {
                  _targetProbability = value;
                });
              },
            ),
            const SizedBox(height: 32),
            // 結果表示
            Text(
              '予想獲得回数',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '平均引回数',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$expectedPulls回',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '説明',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'この確率のキャラを1体獲得するまでに、平均して $expectedPulls 回ガチャを引く必要があります。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 確率分布
            Text(
              '獲得パターン例',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildProbabilityDistribution(context, expectedPulls),
          ],
        ),
      ),
    );
  }

  /// 確率分布表示
  Widget _buildProbabilityDistribution(BuildContext context, int expectedPulls) {
    return Column(
      children: [
        _buildDistributionItem(context, '50%の確率で獲得', (expectedPulls * 0.693).toInt()),
        const SizedBox(height: 8),
        _buildDistributionItem(context, '90%の確率で獲得', (expectedPulls * 2.303).toInt()),
        const SizedBox(height: 8),
        _buildDistributionItem(context, '99%の確率で獲得', (expectedPulls * 4.605).toInt()),
      ],
    );
  }

  /// 分布アイテム
  Widget _buildDistributionItem(
    BuildContext context,
    String label,
    int pulls,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            '$pulls回',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// ユーティリティ: シミュレーション計算
  Map<String, int> _calculateSimulation(int count) {
    int n = 0, r = 0, sr = 0, ssr = 0;

    for (int i = 0; i < count; i++) {
      final random = (i * 7919) % 100; // 簡易乱数生成
      if (random < 46) {
        n++;
      } else if (random < 80) {
        r++;
      } else if (random < 97) {
        sr++;
      } else {
        ssr++;
      }
    }

    return {'n': n, 'r': r, 'sr': sr, 'ssr': ssr};
  }

  /// ユーティリティ: 獲得予想計算
  int _calculateExpectedPulls(double probability) {
    return (1 / probability).toInt();
  }
}
