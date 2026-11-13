import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/sneaker_images.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'products_screen.dart';

/// "Shop" tab: categories as large tiles
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future = _load();

  Future<List<Category>> _load() async =>
      asList((await ApiClient.instance.categories()).data)
          .map(Category.fromJson)
          .toList();

  void _open(String title, String? id) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProductsScreen(title: title, categoryId: id)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Loader();
          if (snap.hasError) {
            return ErrorView('${snap.error}',
                onRetry: () => setState(() => _future = _load()));
          }
          final cats = snap.data!;
          return RefreshIndicator(
            color: AppColors.ember,
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SHOP',
                              style: AppTheme.font(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: AppColors.ember,
                                  spacing: 3)),
                          Text('Shop by category',
                              style: AppTheme.font(
                                  size: 30, weight: FontWeight.w800)),
                          Text('${cats.length} categories picked for you',
                              style: AppTheme.font(color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _allTile()),
                if (cats.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                          icon: Icons.category_outlined,
                          title: 'No categories yet'),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _tile(cats[i], i),
                      childCount: cats.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: .86,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _allTile() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Pressable(
          scale: .98,
          onTap: () => _open('All sneakers', null),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(30),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 210,
                child: NetImage(SneakerImages.hero(1)),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.ink, AppColors.ink, Color(0x00111014)],
                      stops: [0, .42, .9],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('All sneakers',
                        style: AppTheme.font(
                            size: 24,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                    Text('Browse the full collection',
                        style: AppTheme.font(color: Colors.white60)),
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          color: AppColors.ember, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _tile(Category c, int i) => Pressable(
        onTap: () => _open(c.name, c.id),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.tint(i),
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            NetImage(c.image),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9111014)],
                  stops: [.45, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${c.count}',
                    style: AppTheme.font(size: 11, weight: FontWeight.w700)),
              ),
            ),
            Positioned(
              right: 14,
              left: 14,
              bottom: 14,
              child: Row(children: [
                Expanded(
                  child: Text(c.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                          size: 15.5,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25)),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ]),
            ),
          ]),
        ),
      );
}
