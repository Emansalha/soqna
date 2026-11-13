import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/sneaker_images.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/product_card.dart';
import '../widgets/stacked_banners.dart';
import 'product_screen.dart';
import 'products_screen.dart';
import 'store_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<BannerItem> _banners = [];
  List<Category> _categories = [];
  List<Product> _featured = [], _newest = [], _best = [];
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  /// Default banners when none are set in the dashboard
  static final _defaultBanners = [
    BannerItem(id: 'd1', title: 'New season,\nnew energy', subtitle: 'Discover the latest sneaker drop',
        image: SneakerImages.hero(0), link: '', productId: '', categoryId: ''),
    BannerItem(id: 'd2', title: 'Timeless\nclassics', subtitle: 'Iconic designs for every day',
        image: SneakerImages.hero(1), link: '', productId: '', categoryId: ''),
    BannerItem(id: 'd3', title: 'Run the\ncity', subtitle: 'Lightweight runners built for speed',
        image: SneakerImages.hero(2), link: '', productId: '', categoryId: ''),
    BannerItem(id: 'd4', title: 'Up to\n30% off', subtitle: 'Limited time on selected styles',
        image: SneakerImages.hero(4), link: '', productId: '', categoryId: ''),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _newest.isEmpty && _featured.isEmpty;
      _error = null;
    });
    try {
      final d = asMap((await ApiClient.instance.home()).data);
      List<Product> prods(String k) =>
          asList(d[k]).map(Product.fromJson).toList();
      setState(() {
        final raw = asList(d['banners'] ?? d['sliders']);
        _banners = [
          for (int i = 0; i < raw.length; i++) BannerItem.fromJson(raw[i], i)
        ];
        _categories = asList(d['categories']).map(Category.fromJson).toList();
        _featured = prods('featured');
        _newest = prods('newest');
        _best = prods('best_sellers');
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openBanner(BannerItem b) {
    if (b.productId.isNotEmpty) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductScreen(productId: b.productId)));
    } else if (b.categoryId.isNotEmpty) {
      _push(ProductsScreen(title: b.title.replaceAll('\n', ' '), categoryId: b.categoryId));
    } else {
      _push(const ProductsScreen(title: 'All sneakers', sort: 'newest'));
    }
  }

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (_loading) return const Scaffold(body: Loader());
    if (_error != null && _newest.isEmpty && _featured.isEmpty) {
      return Scaffold(body: ErrorView(_error!, onRetry: _load));
    }
    final trending = _best.isNotEmpty ? _best : _featured;
    final grid = _newest.isNotEmpty ? _newest : _featured;

    return Scaffold(
      body: Stack(children: [
      RefreshIndicator(
        color: AppColors.ember,
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _header(app)),
            SliverToBoxAdapter(child: _search()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: StackedBanners(
                  banners: _banners.isNotEmpty ? _banners : _defaultBanners,
                  onOpen: _openBanner,
                ),
              ),
            ),
            if (_categories.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader('Shop by category',
                    kicker: 'Categories', onMore: () => app.setTab(1)),
              ),
              SliverToBoxAdapter(child: _categoryChips()),
            ],
            if (trending.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader('Trending now',
                    kicker: 'Trending now',
                    onMore: () => _push(const ProductsScreen(
                        title: 'Trending now', sort: 'best_selling'))),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: trending.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => TrendCard(trending[i], rank: i + 1),
                  ),
                ),
              ),
            ],
            if (_featured.isNotEmpty && _best.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader('Editor\'s picks',
                    kicker: 'Editor\'s pick',
                    onMore: () => _push(const ProductsScreen(
                        title: 'Editor\'s picks', featured: true))),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 270,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => ProductCard(_featured[i],
                        index: i + 2, width: 170, section: 'featured'),
                  ),
                ),
              ),
            ],
            if (grid.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader('New arrivals',
                    kicker: 'New arrivals',
                    onMore: () => _push(const ProductsScreen(
                        title: 'New arrivals', sort: 'newest'))),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) =>
                        ProductCard(grid[i], index: i, section: 'newest'),
                    childCount: grid.length > 6 ? 6 : grid.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 14,
                    childAspectRatio: .62,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      // Compact frosted app bar that slides in while scrolling
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: ValueListenableBuilder<double>(
          valueListenable: _offset,
          builder: (_, off, __) => CollapsingTopBar(
            offset: off,
            child: _compactBar(app),
          ),
        ),
      ),
      ]),
    );
  }

  Widget _compactBar(AppState app) => Row(children: [
        SpinningRing(size: 34, child: _logo(app, 34)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(app.store?.name ?? 'Souqna',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(size: 16, weight: FontWeight.w700)),
        ),
        CircleBtn(Icons.search_rounded,
            size: 40,
            onTap: () => _push(
                const ProductsScreen(title: 'Search', searchMode: true))),
        const SizedBox(width: 8),
        CircleBtn(Icons.shopping_bag_outlined,
            size: 40, badge: app.cart.count, onTap: () => app.setTab(3)),
      ]);

  Widget _logo(AppState app, double size) {
    final s = app.store;
    return Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: s != null && s.logo.isNotEmpty
          ? NetImage(s.logo)
          : Center(
              child: Text((s?.name ?? 'S').characters.first.toUpperCase(),
                  style: AppTheme.font(
                      size: size * .43,
                      weight: FontWeight.w700,
                      color: Colors.white)),
            ),
    );
  }

  Widget _header(AppState app) {
    final s = app.store;
    final first = app.customer?.name.split(' ').first;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EntryMotion(
              child: Row(children: [
              SpinningRing(child: _logo(app, 46)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(first != null && first.isNotEmpty ? 'Hi, $first 👋' : 'Welcome 👋',
                        style: AppTheme.font(size: 12.5, color: AppColors.muted)),
                    Text(s?.name ?? 'Souqna',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.font(size: 16, weight: FontWeight.w700)),
                  ],
                ),
              ),
              CircleBtn(Icons.storefront_outlined,
                  onTap: () => _push(const StoreInfoScreen())),
              const SizedBox(width: 8),
              CircleBtn(Icons.shopping_bag_outlined,
                  badge: app.cart.count, onTap: () => app.setTab(3)),
              ]),
            ),
            const SizedBox(height: 22),
            EntryMotion(
              delay: const Duration(milliseconds: 180),
              from: const Offset(-.08, 0),
              child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Find your\n'),
                TextSpan(
                    text: 'perfect',
                    style: AppTheme.font(
                        size: 34,
                        weight: FontWeight.w800,
                        color: AppColors.ember,
                        height: 1.15)),
                const TextSpan(text: ' pair'),
              ]),
              style: AppTheme.font(size: 34, weight: FontWeight.w800, height: 1.15),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _search() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Row(children: [
          Expanded(
            child: Pressable(
              scale: .98,
              onTap: () => _push(
                  const ProductsScreen(title: 'Search', searchMode: true)),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: AppColors.text),
                  const SizedBox(width: 10),
                  Text('Search models, brands...',
                      style: AppTheme.font(color: AppColors.muted)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleBtn(Icons.tune_rounded,
              size: 56,
              bg: AppColors.ink,
              color: Colors.white,
              onTap: () => _push(const ProductsScreen(
                  title: 'All sneakers', openFilters: true))),
        ]),
      );

  Widget _categoryChips() => SizedBox(
        height: 58,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final all = i == 0;
            final c = all ? null : _categories[i - 1];
            return Pressable(
              onTap: () => _push(all
                  ? const ProductsScreen(title: 'All sneakers')
                  : ProductsScreen(title: c!.name, categoryId: c.id)),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 18, 6),
                decoration: BoxDecoration(
                  color: all ? AppColors.ink : AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: all ? AppColors.ember : AppColors.tint(i),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: all
                        ? const Icon(Icons.grid_view_rounded,
                            color: Colors.white, size: 20)
                        : NetImage(c!.image),
                  ),
                  const SizedBox(width: 10),
                  Text(all ? 'All' : c!.name,
                      style: AppTheme.font(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: all ? Colors.white : AppColors.text)),
                ]),
              ),
            );
          },
        ),
      );
}
