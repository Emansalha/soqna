import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../screens/product_screen.dart';
import 'common.dart';

void openProduct(BuildContext context, Product p, {String? heroTag}) =>
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) =>
            ProductScreen(productId: p.id, preview: p, heroTag: heroTag),
        transitionsBuilder: (_, a, __, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, .06), end: Offset.zero)
                  .animate(c),
              child: child,
            ),
          );
        },
      ),
    );

/// Heart button — shared
class FavButton extends StatelessWidget {
  final Product product;
  final double size;
  const FavButton(this.product, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fav = app.isFav(product);
    return Pressable(
      scale: .85,
      onTap: () async {
        if (!await ensureLoggedIn(context)) return;
        try {
          await app.toggleFavorite(product);
        } catch (e) {
          if (context.mounted) showMsg(context, '$e', error: true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fav ? AppColors.ember : Colors.white.withValues(alpha: .92),
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(
            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(fav),
            size: size * .5,
            color: fav ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Grid product card
class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final double? width;
  final String section;
  const ProductCard(this.product,
      {super.key, this.index = 0, this.width, this.section = 'grid'});

  @override
  Widget build(BuildContext context) {
    final cur = context.select<AppState, String>((a) => a.currency);
    final p = product;
    final tag = '$section-${p.id}';
    return Pressable(
      onTap: () => openProduct(context, p, heroTag: tag),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.tint(index),
                  borderRadius: BorderRadius.circular(26),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  Hero(tag: tag, child: NetImage(p.image)),
                  Positioned(top: 10, right: 10, child: FavButton(p, size: 34)),
                  if (p.hasDiscount)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _chip('-${p.discountPercent}%', AppColors.ember),
                    )
                  else if (!p.inStock)
                    Positioned(
                        top: 12, left: 12, child: _chip('Sold out', AppColors.ink)),
                  if (p.rating > 0)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.ember),
                          const SizedBox(width: 2),
                          Text(p.rating.toStringAsFixed(1),
                              style: AppTheme.font(
                                  size: 11, weight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (p.brand.isNotEmpty ? p.brand : p.categoryName).isEmpty
                        ? 'SNEAKERS'
                        : (p.brand.isNotEmpty ? p.brand : p.categoryName),
                    maxLines: 1,
                    style: AppTheme.font(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: AppColors.muted,
                        spacing: 1),
                  ),
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(size: 14.5, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(
                        child: PriceTag(
                            price: p.price, old: p.oldPrice, currency: cur)),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                          color: AppColors.ink, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_outward_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: AppTheme.font(
                size: 11, weight: FontWeight.w700, color: Colors.white)),
      );
}

/// "Trending" card — full-height image, big outlined rank number
class TrendCard extends StatelessWidget {
  final Product product;
  final int rank;
  const TrendCard(this.product, {super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    final cur = context.select<AppState, String>((a) => a.currency);
    final p = product;
    final tag = 'trend-${p.id}';
    return Pressable(
      onTap: () => openProduct(context, p, heroTag: tag),
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(30),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          Hero(tag: tag, child: NetImage(p.image)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6111014)],
                stops: [.42, 1],
              ),
            ),
          ),
          // Outlined rank number
          Positioned(
            top: -6,
            left: 12,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: AppTheme.outline(
                  size: 64,
                  height: 1,
                  stroke: 1.6,
                  color: Colors.white.withValues(alpha: .9)),
            ),
          ),
          Positioned(top: 12, right: 12, child: FavButton(p, size: 34)),
          Positioned(
            right: 16,
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                        size: 16,
                        weight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: PriceTag(
                        price: p.price,
                        old: p.oldPrice,
                        currency: cur,
                        light: true),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: AppColors.ember, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Two-column product grid
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ScrollController? controller;
  final Widget? header, footer;
  const ProductGrid(this.products,
      {super.key, this.controller, this.header, this.footer});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _Appear(
                  index: i, child: ProductCard(products[i], index: i)),
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 14,
              childAspectRatio: .62,
            ),
          ),
        ),
        if (footer != null) SliverToBoxAdapter(child: footer),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

/// Staggered fade-in for items
class _Appear extends StatelessWidget {
  final int index;
  final Widget child;
  const _Appear({required this.index, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 380 + (index % 6) * 70),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
        ),
        child: child,
      );
}
