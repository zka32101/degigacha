import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../riverpod/providers.dart';
import '../../data/models/character_progression_model.dart';

/// キャラクター育成進捗画面
///
/// ユーザーが所有するキャラクターを管理・育成
/// レベルアップ、スキル獲得、経験値管理
class CharacterProgressionScreen extends ConsumerStatefulWidget {
  final String userId;

  const CharacterProgressionScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<CharacterProgressionScreen> createState() =>
      _CharacterProgressionScreenState();
}

class _CharacterProgressionScreenState
    extends ConsumerState<CharacterProgressionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 初回取得
    Future.microtask(() {
      final notifier = ref.read(characterProgressionProvider(widget.userId).notifier);
      notifier.fetchCharacters(widget.userId);
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(characterProgressionProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター'),
        centerTitle: true,
      ),
      body: charactersAsync.when(
        data: (characters) => _buildContent(context, characters),
        loading: () => _buildLoading(context),
        error: (error, stack) => _buildError(context, error),
      ),
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
            'キャラクター情報を読み込み中...',
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

  Widget _buildContent(
    BuildContext context,
    List<CharacterProgression> characters,
  ) {
    if (characters.isEmpty) {
      return _buildNoCharactersContent(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  (index * 0.1) + 0.8,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: _buildCharacterCard(context, characters[index]),
          ),
        );
      },
    );
  }

  Widget _buildNoCharactersContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'キャラクターがいません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'ガチャでキャラクターを獲得しましょう',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(
    BuildContext context,
    CharacterProgression character,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // キャラクター名とレベル
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.characterName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '獲得日: ${character.acquiredAt.month}/${character.acquiredAt.day}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv. ${character.currentLevel}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 全体進捗
            Text(
              '全体進捗',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: character.overallProgress,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(character.overallProgress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),

            // 次のレベルまでの経験値
            Text(
              '次のレベルまでの経験値',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: character.progressToNextLevel,
                minHeight: 6,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${character.currentExperience} / ${character.experienceToNextLevel}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),

            // スキル情報
            _buildSkillsSection(context, character),
            const SizedBox(height: 16),

            // 経験値付与ボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleAddExperience(context, character),
                icon: const Icon(Icons.add),
                label: const Text('経験値を追加（テスト用）'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(
    BuildContext context,
    CharacterProgression character,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'スキル',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (character.availableSkillsCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${character.availableSkillsCount}個新規獲得',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: character.skills
              .map((skill) => _buildSkillChip(context, skill))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSkillChip(
    BuildContext context,
    CharacterSkill skill,
  ) {
    return Tooltip(
      message: skill.description,
      child: Chip(
        label: Text(skill.name),
        avatar: Icon(
          skill.isUnlocked ? Icons.lock_open : Icons.lock,
          size: 18,
        ),
        backgroundColor: skill.isUnlocked
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: skill.isUnlocked
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Future<void> _handleAddExperience(
    BuildContext context,
    CharacterProgression character,
  ) async {
    try {
      final notifier = ref.read(
        characterProgressionProvider(widget.userId).notifier,
      );
      await notifier.addExperience(widget.userId, character.id, 50);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✨ 50の経験値を獲得しました！'),
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
}
