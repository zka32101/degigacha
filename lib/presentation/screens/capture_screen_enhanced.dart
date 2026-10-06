import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/gacha_item_model.dart';
import '../../domain/usecases/gacha_usecase.dart';
import '../../services/storage_service.dart';
import '../riverpod/auth_notifier.dart';
import '../riverpod/providers.dart';

/// 撮影・AI判定画面（改善版 - Phase 6A UI/UX強化）
///
/// 「Aha Moment」: 3タップの体験フロー + 演出強化
/// 1. 撮影：ガチャアイテムを撮影
/// 2. 判定：Claude Vision APIでAI判定 (Lottie演出)
/// 3. 自動登録：確認1タップでコレクション登録完了 (紙吹雪アニメ)
class CaptureScreenEnhanced extends ConsumerStatefulWidget {
  const CaptureScreenEnhanced({Key? key}) : super(key: key);

  @override
  ConsumerState<CaptureScreenEnhanced> createState() =>
      _CaptureScreenEnhancedState();
}

class _CaptureScreenEnhancedState extends ConsumerState<CaptureScreenEnhanced>
    with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isProcessing = false;
  AIResult? _aiResult;
  String? _errorMessage;
  bool _showConfetti = false;

  // アニメーションコントローラー
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アイテムを撮影'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // メインコンテンツ
          _selectedImage == null
              ? _buildCameraView(context)
              : _buildJudgmentView(context),

          // 紙吹雪演出（登録完了時）
          if (_showConfetti) _buildConfettiAnimation(context),
        ],
      ),
    );
  }

  /// カメラ撮影インターフェース
  Widget _buildCameraView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Instructions
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // アニメ付きカメラアイコン
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ガチャアイテムを撮影',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'アイテムが画面中央に映るように撮影してください',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Camera Buttons
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _capturePhoto,
                  icon: const Icon(Icons.camera),
                  label: const Text('撮影'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _selectFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('ギャラリーから選択'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// AI判定結果表示・登録確認インターフェース（強化版）
  Widget _buildJudgmentView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image Preview
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[300],
            child: Image.file(
              File(_selectedImage!.path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.error,
                    size: 40,
                    color: Theme.of(context).colorScheme.error,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // エラーメッセージ表示
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            )
          // AI判定中の表示（演出強化版）
          else if (_isProcessing)
            _buildProcessingView(context)
          // 判定結果表示
          else if (_aiResult != null)
            _buildResultView(context),
        ],
      ),
    );
  }

  /// AI判定中の表示（演出強化版）
  Widget _buildProcessingView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // スピナーアニメーション（拡大縮小）
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2).animate(
              CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
            ),
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI判定中...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '自動認識を処理しています',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// AI判定結果表示（演出強化版）
  Widget _buildResultView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judgment Result Card（スライドイン演出）
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _checkController,
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: _checkController,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'アイテム名',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _aiResult!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ],
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRarityColor(
                                _aiResult!.rarity,
                                context,
                              ),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              _aiResult!.rarity.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context,
                        'シリーズ',
                        _aiResult!.series,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        '信頼度',
                        '${(_aiResult!.confidence * 100).toStringAsFixed(0)}%',
                      ),
                      if (_aiResult!.notes != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          context,
                          'メモ',
                          _aiResult!.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Confidence Indicator（改善版）
          Text(
            'AI判定信頼度',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _aiResult!.confidence,
              minHeight: 12,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getConfidenceColor(_aiResult!.confidence, context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getConfidenceLabel(_aiResult!.confidence),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Manual Edit Option
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Show edit dialog
            },
            icon: const Icon(Icons.edit),
            label: const Text('情報を編集'),
          ),
          const SizedBox(height: 12),

          // Confirm Registration Button（拡張版）
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : _confirmRegistrationWithAnimation,
              icon: const Icon(Icons.check_circle),
              label: const Text('コレクションに追加'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .primary,
                foregroundColor:
                    Theme.of(context)
                        .colorScheme
                        .onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Retake Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () {
                      setState(() {
                        _selectedImage = null;
                        _aiResult = null;
                        _errorMessage = null;
                      });
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('再撮影'),
            ),
          ),
        ],
      ),
    );
  }

  /// 紙吹雪アニメーション演出
  Widget _buildConfettiAnimation(BuildContext context) {
    return Stack(
      children: [
        // 背景オーバーレイ
        Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            // 確認チェックマーク
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.2).animate(
                CurvedAnimation(
                  parent: _confettiController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),

        // 紙吹雪パーティクル
        ..._buildConfettiParticles(context),
      ],
    );
  }

  /// 紙吹雪パーティクルビルダー
  List<Widget> _buildConfettiParticles(BuildContext context) {
    final particles = <Widget>[];
    const particleCount = 40;

    for (int i = 0; i < particleCount; i++) {
      final delay = Duration(milliseconds: (i * 50).toInt());
      particles.add(
        _ConfettiParticle(
          controller: _confettiController,
          delay: delay,
          color: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.tertiary,
          ][i % 3],
        ),
      );
    }
    return particles;
  }

  /// ユーティリティ: レアリティ色取得
  Color _getRarityColor(Rarity rarity, BuildContext context) {
    switch (rarity) {
      case Rarity.ssr:
        return Colors.amber[700] ?? Colors.amber;
      case Rarity.sr:
        return Colors.purple[600] ?? Colors.purple;
      case Rarity.r:
        return Colors.blue[600] ?? Colors.blue;
      case Rarity.n:
        return Colors.grey[600] ?? Colors.grey;
    }
  }

  /// ユーティリティ: 信頼度色取得
  Color _getConfidenceColor(double confidence, BuildContext context) {
    if (confidence >= 0.85) {
      return Colors.green;
    } else if (confidence >= 0.70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// ユーティリティ: 信頼度ラベル
  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.85) {
      return '信頼度が高い - 自信あり';
    } else if (confidence >= 0.70) {
      return '信頼度が中程度 - 確認推奨';
    } else {
      return '信頼度が低い - 要確認';
    }
  }

  /// ユーティリティ: 詳細行表示
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// 撮影実行
  Future<void> _capturePhoto() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _isProcessing = true;
      });
      await _processImage();
    }
  }

  /// ギャラリーから選択
  Future<void> _selectFromGallery() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _isProcessing = true;
      });
      await _processImage();
    }
  }

  /// 画像処理（AI判定）
  Future<void> _processImage() async {
    try {
      // TODO: AI判定処理を実装
      // final result = await aiService.identifyGachaItem(_selectedImage!.path);
      // setState(() {
      //   _aiResult = result;
      //   _isProcessing = false;
      // });
      // アニメーション開始
      _checkController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'AI判定に失敗しました: $e';
        _isProcessing = false;
      });
    }
  }

  /// 登録確認（アニメーション付き）
  Future<void> _confirmRegistrationWithAnimation() async {
    // ハプティクスフィードバック
    await HapticFeedback.heavyImpact();

    // アニメーション開始
    _confettiController.forward();

    setState(() {
      _showConfetti = true;
    });

    // 登録処理を実行
    try {
      // TODO: 登録処理実装
      // await _confirmRegistration();

      // アニメーション終了後、次画面へ遷移
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        context.go('/collection');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '登録に失敗しました: $e';
        _showConfetti = false;
      });
    }
  }

  /// 登録確認（元の実装）
  Future<void> _confirmRegistration() async {
    // TODO: 実装
  }
}

/// 紙吹雪パーティクルウィジェット
class _ConfettiParticle extends StatefulWidget {
  final AnimationController controller;
  final Duration delay;
  final Color color;

  const _ConfettiParticle({
    required this.controller,
    required this.delay,
    required this.color,
  });

  @override
  State<_ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<_ConfettiParticle>
    with TickerProviderStateMixin {
  late AnimationController _delayedController;

  @override
  void initState() {
    super.initState();
    _delayedController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _delayedController.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final offsetX = (random % 400) - 200;
    final offsetY = -(random % 400) - 100;

    return Positioned(
      left: MediaQuery.of(context).size.width / 2 + (offsetX / 2),
      top: MediaQuery.of(context).size.height / 2 + (offsetY / 2),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(offsetX / 100, offsetY / 100),
        ).animate(_delayedController),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: _delayedController,
              curve: Curves.easeOut,
            ),
          ),
          child: Icon(
            Icons.celebration,
            color: widget.color.withOpacity(0.8),
            size: 20,
          ),
        ),
      ),
    );
  }
}
