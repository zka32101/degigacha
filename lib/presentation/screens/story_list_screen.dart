import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../riverpod/providers.dart';
import '../../data/models/story_content_model.dart';

/// ストーリーリスト画面
///
/// 利用可能なストーリーコンテンツの一覧表示
/// ストーリーの進捗や種別表示
class StoryListScreen extends ConsumerStatefulWidget {
  final String userId;

  const StoryListScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<StoryListScreen> createState() =>
      _StoryListScreenState();
}

class _StoryListScreenState extends ConsumerState<StoryListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedType = 'all'; // all, character, event, world

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 初回取得
    Future.microtask(() {
      final notifier = ref.read(storyContentListProvider.notifier);
      notifier.fetchAllStories();
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
    final storiesAsync = ref.watch(storyContentListProvider);
    final progressListAsync =
        ref.watch(userStoryProgressListProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ストーリー'),
        centerTitle: true,
      ),
      body: storiesAsync.when(
        data: (stories) => _buildContent(context, stories, progressListAsync),
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
            'ストーリーを読み込み中...',
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
    List<StoryContent> stories,
    AsyncValue<List<UserStoryProgress>> progressListAsync,
  ) {
    if (stories.isEmpty) {
      return _buildNoStoriesContent(context);
    }

    // ストーリーをタイプでフィルタリング
    final filteredStories = stories.where((story) {
      if (_selectedType == 'all') return true;
      return story.storyType == _selectedType;
    }).toList();

    // 進捗マップを作成
    final progressMap = <String, UserStoryProgress>{};
    if (progressListAsync is AsyncData<List<UserStoryProgress>>) {
      for (final progress in progressListAsync.value) {
        progressMap[progress.storyId] = progress;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // タイプフィルター
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip(context, 'すべて', 'all'),
                  const SizedBox(width: 8),
                  _buildTypeChip(context, 'キャラクター', 'character'),
                  const SizedBox(width: 8),
                  _buildTypeChip(context, 'イベント', 'event'),
                  const SizedBox(width: 8),
                  _buildTypeChip(context, 'ワールド', 'world'),
                ],
              ),
            ),
          ),

          // ストーリーリスト
          if (filteredStories.isEmpty)
            _buildNoStoriesContent(context)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: List.generate(
                  filteredStories.length,
                  (index) => Padding(
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
                      child: _buildStoryCard(
                        context,
                        filteredStories[index],
                        progressMap[filteredStories[index].id],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    String label,
    String value,
  ) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = value;
        });
      },
      backgroundColor:
          isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildNoStoriesContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.library_books,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'ストーリーがありません',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '新しいストーリーをお待ちください',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(
    BuildContext context,
    StoryContent story,
    UserStoryProgress? progress,
  ) {
    final isCompleted = progress?.isCompleted ?? false;
    final isStarted = progress != null;

    return Card(
      child: InkWell(
        onTap: () {
          // ストーリーリーダーに移動
          // context.go('/story-reader/${story.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.library_books,
                      size: 60,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  if (isCompleted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '読破済み',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // コンテンツ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトルと種別
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStoryTypeName(story.storyType),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isStarted && !isCompleted)
                        Chip(
                          label: Text(
                            '読書中',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 説明
                  Text(
                    story.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 進捗バー
                  if (isStarted)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'チャプター ${progress!.lastReadChapter + 1} / ${story.totalChapters}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              '${(story.completionRate * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: story.completionRate,
                            minHeight: 4,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'チャプター数: ${story.totalChapters}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
      ),
    );
  }

  String _getStoryTypeName(String storyType) {
    switch (storyType) {
      case 'character':
        return 'キャラクター';
      case 'event':
        return 'イベント';
      case 'world':
        return 'ワールド';
      default:
        return storyType;
    }
  }
}
