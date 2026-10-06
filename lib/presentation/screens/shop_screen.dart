import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payment_model.dart';
import '../riverpod/providers.dart';

/// ショップ画面
class ShopScreen extends ConsumerStatefulWidget {
  final String userId;

  const ShopScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  String _selectedCategory = 'gem';

  final categories = [
    {'id': 'gem', 'label': 'プレミアムジェム'},
    {'id': 'coin', 'label': 'ゲームコイン'},
    {'id': 'bundle', 'label': 'バンドル'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iapProductsProvider.notifier).loadProducts();
      ref.read(userBalanceProvider(widget.userId).notifier)
          .loadBalance(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: DefaultTabController(
        length: 3,
        controller: _tabController,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ショップ'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'ジェム', icon: Icon(Icons.diamond)),
                Tab(text: 'コイン', icon: Icon(Icons.monetization_on)),
                Tab(text: 'バンドル', icon: Icon(Icons.card_giftcard)),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildBalanceBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGemTab(),
                    _buildCoinTab(),
                    _buildBundleTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 残高バー
  Widget _buildBalanceBar() {
    return Consumer(
      builder: (context, ref, _) {
        final balanceAsync = ref.watch(userBalanceProvider(widget.userId));
        return balanceAsync.when(
          loading: () => const SizedBox(height: 60),
          error: (error, stack) => SizedBox(
            height: 60,
            child: Center(child: Text('エラー: $error')),
          ),
          data: (balance) {
            if (balance == null) {
              return const SizedBox(height: 60);
            }

            return Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBalanceItem(
                    label: 'ジェム',
                    amount: balance.gemBalance,
                    icon: Icons.diamond,
                    color: Colors.purple,
                  ),
                  _buildBalanceItem(
                    label: 'コイン',
                    amount: balance.coinBalance,
                    icon: Icons.monetization_on,
                    color: Colors.amber,
                  ),
                  _buildBalanceItem(
                    label: '購入額',
                    amount: balance.totalSpent,
                    icon: Icons.paid,
                    color: Colors.green,
                    suffix: '円',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 残高アイテム
  Widget _buildBalanceItem({
    required String label,
    required int amount,
    required IconData icon,
    required Color color,
    String suffix = '',
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$amount$suffix',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// ジェムタブ
  Widget _buildGemTab() {
    return _buildCategoryTab('gem');
  }

  /// コインタブ
  Widget _buildCoinTab() {
    return _buildCategoryTab('coin');
  }

  /// バンドルタブ
  Widget _buildBundleTab() {
    return _buildCategoryTab('bundle');
  }

  /// カテゴリタブを構築
  Widget _buildCategoryTab(String category) {
    return Consumer(
      builder: (context, ref, _) {
        final productsAsync = ref.watch(iapProductsProvider);
        return productsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('エラー: $error'),
          ),
          data: (products) {
            final filtered = products
                .where((p) => p.category == category)
                .toList();

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '商品がありません',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _buildProductCard(filtered[index]);
              },
            );
          },
        );
      },
    );
  }

  /// 商品カード
  Widget _buildProductCard(IAPProduct product) {
    return Card(
      child: InkWell(
        onTap: () => _showPurchaseDialog(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タグ
              if (product.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.tag!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              // 商品名
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 付与ポイント
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(product.category),
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${product.amount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 価格と購入ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '¥${product.price}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showPurchaseDialog(product),
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('購入'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 購入ダイアログ
  void _showPurchaseDialog(IAPProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('説明: ${product.description}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('付与額:'),
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(product.category),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.amount}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('価格:'),
                Text(
                  '¥${product.price}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userBalanceProvider(widget.userId).notifier).purchase(
                userId: widget.userId,
                productId: product.productId,
                productName: product.name,
                amount: product.amount,
                price: product.price,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name}を購入しました')),
              );
            },
            child: const Text('購入'),
          ),
        ],
      ),
    );
  }

  /// カテゴリアイコンを取得
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'gem':
        return Icons.diamond;
      case 'coin':
        return Icons.monetization_on;
      case 'bundle':
        return Icons.card_giftcard;
      default:
        return Icons.shopping_bag;
    }
  }
}
