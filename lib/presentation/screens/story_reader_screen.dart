import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../riverpod/providers.dart';
import '../../data/models/story_content_model.dart';

/// ストーリーリーダー画面
///
/// ストーリーコンテンツを読む画面
/// チャプター単位での進捗管理とナビゲーション
class StoryReaderScreen extends ConsumerStatefulWidget {
  final String storyId;
  final String userId;

  const StoryReaderScreen({
    Key? key,
    required this.storyId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<StoryReaderScreen> createState() =>
      _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late PageController _pageController;
  int _currentChapter = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pageController = PageController(initialPage: 0);

    // 初回取得
    Future.microtask(() {
      // ストーリーを取得
      ref
          .read(singleStoryContentProvider(widget.storyId).notifier)
          .fetchStoryById(widget.storyId);

      // 進捗を取得または初期化
      _initializeProgress();

      _fadeController.forward();
    });
  }

  void _initializeProgress() async {
    final progressNotifier = ref.read(
      userStoryProgressProvider((widget.userId, widget.storyId)).notifier,
    );

    try {
      await progressNotifier.fetchProgress(
        widget.userId,
        widget.storyId,
      );
    } catch (e) {
      // 初回読破時は進捗を初期化
      await progressNotifier.initializeProgress(
        widget.userId,
        widget.storyId,
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync =
        ref.watch(singleStoryContentProvider(widget.storyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ストーリー'),
        centerTitle: true,
      ),
      body: storyAsync.when(
        data: (story) => _buildContent(context, story),
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

  Widget _buildContent(BuildContext context, StoryContent? story) {
    if (story == null) {
      return Center(
        child: Text(
          'ストーリーが見つかりません',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    if (story.chapters.isEmpty) {
      return Center(
        child: Text(
          'チャプターがありません',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return Column(
      children: [
        // プログレスバー
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'チャプター ${_currentChapter + 1} / ${story.chapters.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    '${(story.completionRate * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentChapter + 1) / story.chapters.length,
                  minHeight: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ストーリーコンテンツ
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentChapter = index;
              });
              _updateProgress(story, index);
            },
            itemCount: story.chapters.length,
            itemBuilder: (context, index) {
              return _buildChapterPage(context, story.chapters[index]);
            },
          ),
        ),

        // ナビゲーションボタン
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentChapter > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('前へ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentChapter < story.chapters.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('次へ'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChapterPage(BuildContext context, StoryChapter chapter) {
    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // チャプタータイトル
            Text(
              'チャプター ${chapter.chapterNumber}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chapter.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // キャラクター画像
            if (chapter.characterImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

            // ストーリーテキスト
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                chapter.content.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    chapter.content[index],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProgress(StoryContent story, int chapterIndex) {
    final progressNotifier = ref.read(
      userStoryProgressProvider((widget.userId, widget.storyId)).notifier,
    );

    final isCompleted =
        chapterIndex == story.chapters.length - 1;

    progressNotifier.updateProgress(
      widget.userId,
      widget.storyId,
      chapterIndex,
      isCompleted,
    );
  }
}
