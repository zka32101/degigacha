import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../riverpod/providers.dart';
import '../../data/models/daily_spin_model.dart';
import '../../data/models/gacha_item_model.dart';

/// 日次スピン画面
///
/// 毎日1回無料でガチャが引ける
/// スピンアニメーションと結果表示機能
class DailySpinScreen extends ConsumerStatefulWidget {
  final String userId;

  const DailySpinScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<DailySpinScreen> createState() => _DailySpinScreenState();
}

class _DailySpinScreenState extends ConsumerState<DailySpinScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _scaleController;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 初回取得
    Future.microtask(() {
      final notifier = ref.read(dailySpinProvider(widget.userId).notifier);
      notifier.fetchDailySpin(widget.userId);
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailySpinAsync = ref.watch(dailySpinProvider(widget.userId));

    return dailySpinAsync.when(
      data: (spin) => _buildContent(context, spin),
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildError(context, error),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'スピン情報を読み込み中...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DailySpin? spin) {
    if (spin == null) {
      return _buildNoSpinContent(context);
    }

    final canSpin = spin.spinCount < spin.maxSpinsPerDay;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // スピン上限表示
            _buildSpinLimitCard(context, spin),
            const SizedBox(height: 32),

            // スピンホイール
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
              ),
              child: _buildSpinWheel(context, spin),
            ),
            const SizedBox(height: 48),

            // スピンボタン
            if (canSpin)
              _buildSpinButton(context, spin)
            else
              _buildSpinLimitReachedCard(context, spin),

            const SizedBox(height: 32),

            // 最新の結果表示
            if (spin.resultHistory.isNotEmpty)
              Column(
                children: [
                  Text(
                    '最新の結果',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildResultCard(context, spin.resultHistory.first),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSpinContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'スピン情報がありません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSpinLimitCard(BuildContext context, DailySpin spin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.casino,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日のスピン',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${spin.spinCount} / ${spin.maxSpinsPerDay}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
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

  Widget _buildSpinWheel(BuildContext context, DailySpin spin) {
    final rarities = [
      (Rarity.n, '46%'),
      (Rarity.r, '34%'),
      (Rarity.sr, '17%'),
      (Rarity.ssr, '3%'),
    ];

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ホイール背景
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // セグメント表示
          RotationTransition(
            turns: _isSpinning
                ? Tween<double>(begin: 0, end: 4).animate(
                    CurvedAnimation(parent: _spinController, curve: Curves.linear),
                  )
                : AlwaysStoppedAnimation(0),
            child: Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: CustomPaint(
                  painter: SpinWheelPainter(
                    rarities: rarities,
                    context: context,
                  ),
                ),
              ),
            ),
          ),

          // 中央ポイント
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton(BuildContext context, DailySpin spin) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSpinning ? null : () => _handleSpin(context),
        icon: const Icon(Icons.casino),
        label: const Text('スピンを回す'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildSpinLimitReachedCard(BuildContext context, DailySpin spin) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本日のスピン上限に達しました',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'また明日スピンできます',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
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

  Widget _buildResultCard(BuildContext context, SpinResult result) {
    final rarityColor = _getRarityColor(result.rarity, context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  result.itemName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.rarity.value,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'シリーズ: ${result.series}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${result.spinnedAt.hour}:${result.spinnedAt.minute}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSpin(BuildContext context) async {
    setState(() {
      _isSpinning = true;
    });

    _spinController.repeat();

    try {
      final notifier = ref.read(dailySpinProvider(widget.userId).notifier);
      final result = await notifier.performSpin(widget.userId);

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        _spinController.stop();
        setState(() {
          _isSpinning = false;
        });

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${result.itemName} をゲットしました！'),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _spinController.stop();
        setState(() {
          _isSpinning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getRarityColor(Rarity rarity, BuildContext context) {
    return switch (rarity) {
      Rarity.ssr => const Color(0xFFFFD700),
      Rarity.sr => const Color(0xFF9C27B0),
      Rarity.r => const Color(0xFF2196F3),
      Rarity.n => Colors.grey,
    };
  }
}

/// スピンホイール描画用カスタムペイント
class SpinWheelPainter extends CustomPainter {
  final List<(Rarity, String)> rarities;
  final BuildContext context;

  SpinWheelPainter({
    required this.rarities,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()..style = PaintingStyle.stroke;

    for (int i = 0; i < rarities.length; i++) {
      final angle = (2 * pi / rarities.length) * i;
      final nextAngle = (2 * pi / rarities.length) * (i + 1);

      final startOffset = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final endOffset = Offset(
        center.dx + radius * cos(nextAngle),
        center.dy + radius * sin(nextAngle),
      );

      // セグメント描画
      paint.color = _getRaritySegmentColor(rarities[i].$1).withOpacity(0.7);
      paint.strokeWidth = 2;
      canvas.drawLine(startOffset, center, paint);
      canvas.drawLine(endOffset, center, paint);

      // テキスト描画
      final textAngle = (angle + nextAngle) / 2;
      final textOffset = Offset(
        center.dx + (radius * 0.6) * cos(textAngle),
        center.dy + (radius * 0.6) * sin(textAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: rarities[i].$2,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textOffset.dx - textPainter.width / 2,
          textOffset.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(SpinWheelPainter oldDelegate) => false;

  Color _getRaritySegmentColor(Rarity rarity) {
    return switch (rarity) {
      Rarity.ssr => const Color(0xFFFFD700),
      Rarity.sr => const Color(0xFF9C27B0),
      Rarity.r => const Color(0xFF2196F3),
      Rarity.n => Colors.grey,
    };
  }
}
