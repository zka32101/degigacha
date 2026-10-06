import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../riverpod/providers.dart';
import '../../data/models/login_bonus_model.dart';

/// ログインボーナス画面
///
/// 連続ログイン日数に基づいたボーナスシステム
/// - ブロンズ：7日未満、10ポイント
/// - シルバー：7-13日、25ポイント
/// - ゴールド：14-29日、50ポイント
/// - プラチナ：30日以上、100ポイント
class LoginBonusScreen extends ConsumerStatefulWidget {
  final String userId;

  const LoginBonusScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<LoginBonusScreen> createState() => _LoginBonusScreenState();
}

class _LoginBonusScreenState extends ConsumerState<LoginBonusScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 初回ボーナスプロバイダーの取得
    Future.microtask(() {
      final notifier = ref.read(loginBonusProvider(widget.userId).notifier);
      notifier.fetchLoginBonus(widget.userId);
      _scaleController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginBonusAsync = ref.watch(loginBonusProvider(widget.userId));

    return loginBonusAsync.when(
      data: (bonus) => _buildContent(context, bonus),
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
            'ボーナス情報を読み込み中...',
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
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LoginBonus? bonus) {
    if (bonus == null) {
      return _buildNoBonusContent(context);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ボーナスレベルの表示
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
              ),
              child: _buildBonusLevelCard(context, bonus),
            ),
            const SizedBox(height: 24),

            // 連続ログイン日数
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(
                CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
              ),
              child: _buildConsecutiveDaysCard(context, bonus),
            ),
            const SizedBox(height: 24),

            // ボーナスポイント情報
            _buildBonusPointsCard(context, bonus),
            const SizedBox(height: 24),

            // レベルアップまでの進捗
            _buildLevelProgressCard(context, bonus),
            const SizedBox(height: 32),

            // ボーナス請求ボタン
            _buildClaimButton(context, bonus),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBonusContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'ボーナス情報がありません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'ログインしてボーナスを獲得しましょう',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusLevelCard(BuildContext context, LoginBonus bonus) {
    final colors = _getBonusLevelColors(bonus.bonusLevel, context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors['light']!,
            colors['main']!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors['main']!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ボーナスレベル',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors['text']!.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _getBonusLevelLabel(bonus.bonusLevel),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors['text']!,
                  fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors['text']!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${bonus.bonusLevel.bonusPoints}ポイント/日',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors['text']!,
                    fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsecutiveDaysCard(BuildContext context, LoginBonus bonus) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '連続ログイン日数',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${bonus.consecutiveDays}',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '日',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '累計ボーナス',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${bonus.totalBonusPoints}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusPointsCard(BuildContext context, LoginBonus bonus) {
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
                Icons.card_giftcard,
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
                    '今日のボーナス',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bonus.isClaimedToday
                        ? '本日は既に請求済み'
                        : '+${bonus.bonusLevel.bonusPoints}ポイント',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: bonus.isClaimedToday
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (bonus.isClaimedToday)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgressCard(BuildContext context, LoginBonus bonus) {
    final nextLevel = _getNextBonusLevel(bonus.consecutiveDays);
    final daysToNextLevel = nextLevel - bonus.consecutiveDays;

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
                  '次のレベルまで',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$daysToNextLevel日',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: bonus.consecutiveDays / nextLevel,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimButton(BuildContext context, LoginBonus bonus) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: bonus.isClaimedToday
            ? null
            : () => _handleClaim(context),
        icon: const Icon(Icons.check_circle),
        label: Text(
          bonus.isClaimedToday ? 'ボーナス取得済み' : 'ボーナスを受け取る',
        ),
      ),
    );
  }

  Future<void> _handleClaim(BuildContext context) async {
    try {
      final notifier = ref.read(loginBonusProvider(widget.userId).notifier);
      final bonus = await notifier.claimBonus(widget.userId);

      if (bonus != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${bonus.bonusLevel.bonusPoints}ポイントを獲得しました！'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  String _getBonusLevelLabel(BonusLevel level) {
    return switch (level) {
      BonusLevel.bronze => 'ブロンズ',
      BonusLevel.silver => 'シルバー',
      BonusLevel.gold => 'ゴールド',
      BonusLevel.platinum => 'プラチナ',
    };
  }

  Map<String, Color> _getBonusLevelColors(BonusLevel level, BuildContext context) {
    return switch (level) {
      BonusLevel.bronze => {
        'main': const Color(0xFFCD7F32),
        'light': const Color(0xFFCD7F32).withOpacity(0.2),
        'text': Colors.brown[900]!,
      },
      BonusLevel.silver => {
        'main': const Color(0xFFC0C0C0),
        'light': const Color(0xFFC0C0C0).withOpacity(0.2),
        'text': Colors.grey[900]!,
      },
      BonusLevel.gold => {
        'main': const Color(0xFFFFD700),
        'light': const Color(0xFFFFD700).withOpacity(0.2),
        'text': Colors.amber[900]!,
      },
      BonusLevel.platinum => {
        'main': const Color(0xFF00D4FF),
        'light': const Color(0xFF00D4FF).withOpacity(0.2),
        'text': Colors.cyan[900]!,
      },
    };
  }

  int _getNextBonusLevel(int currentDays) {
    if (currentDays < 7) return 7;
    if (currentDays < 14) return 14;
    if (currentDays < 30) return 30;
    return currentDays + 30;
  }
}
