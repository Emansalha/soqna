import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

/// Default EU sizes when the API provides none
const _defaultSizes = ['36', '37', '38', '39', '40', '41', '42', '43', '44', '45'];

class ProductScreen extends StatefulWidget {
  final String productId;
  final Product? preview;
  final String? heroTag;
  const ProductScreen(
      {super.key, required this.productId, this.preview, this.heroTag});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? _p;
  bool _full = false;
  List<Review> _reviews = [];
  String? _error;
  int _img = 0, _qty = 1;
  final Map<String, String> _selected = {};
  String? _size;
  bool _adding = false, _added = false, _expanded = false;
  final _pager = PageController();

  @override
  void initState() {
    super.initState();
    _p = widget.preview;
    _load();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await ApiClient.instance.product(widget.productId);
      final p = Product.fromJson(r.data);
      for (final g in p.options) {
        if (g.key != 'size') _selected[g.key] = g.values.first;
      }
      setState(() {
        _p = p;
        _full = true;
      });
      _loadReviews();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      final r = await ApiClient.instance.reviews(widget.productId);
      setState(() =>
          _reviews = asList(r.data).map(Review.fromJson).take(5).toList());
    } catch (_) {}
  }

  List<String> get _sizes {
    final g = _p?.options.where((o) => o.key == 'size');
    return g != null && g.isNotEmpty ? g.first.values : _defaultSizes;
  }

  Future<void> _addToCart() async {
    if (_size == null) {
      HapticFeedback.heavyImpact();
      showMsg(context, 'Pick your size first 👟', error: true);
      return;
    }
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    setState(() => _adding = true);
    try {
      await context.read<AppState>().addToCart(_p!.id, _qty,
          options: {..._selected, 'size': _size!});
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() => _added = true);
      Future.delayed(const Duration(milliseconds: 1600),
          () => mounted ? setState(() => _added = false) : null);
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _p == null) {
      return Scaffold(
          appBar: AppBar(), body: ErrorView(_error!, onRetry: _load));
    }
    if (_p == null) return const Scaffold(body: Loader());
    final p = _p!;
    final app = context.watch<AppState>();
    final images = p.images.isEmpty ? [''] : p.images;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _stage(p, images, h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (images.length > 1) _thumbs(images),
                    _titleBlock(p, app),
                    if (!_full)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Loader(),
                      )
                    else ...[
                      for (final g in p.options.where((o) => o.key != 'size'))
                        _optionGroup(g),
                      _sizeBlock(),
                      _perks(app),
                      if (p.description.isNotEmpty) _description(p),
                      _reviewsBlock(p),
                      if (p.related.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        Text('You may also like',
                            style: AppTheme.font(
                                size: 19, weight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 260,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: p.related.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) => ProductCard(p.related[i],
                                index: i + 1, width: 165, section: 'related'),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        // Floating top buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              CircleBtn(Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context)),
              const Spacer(),
              CircleBtn(Icons.shopping_bag_outlined,
                  badge: app.cart.count,
                  onTap: () {
                    app.setTab(3);
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }),
              const SizedBox(width: 8),
              FavButton(p, size: 46),
            ]),
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar(p, app)),
      ]),
    );
  }

  // ───── Stage: image gallery ─────
  Widget _stage(Product p, List<String> images, double h) {
    return Container(
      height: h * .52,
      decoration: BoxDecoration(
        color: AppColors.tint(p.id.hashCode),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        PageView.builder(
          controller: _pager,
          itemCount: images.length,
          onPageChanged: (i) {
            HapticFeedback.selectionClick();
            setState(() => _img = i);
          },
          itemBuilder: (_, i) {
            final img = NetImage(images[i]);
            return i == 0 && widget.heroTag != null
                ? Hero(tag: widget.heroTag!, child: img)
                : img;
          },
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x55111014), Colors.transparent, Color(0x66111014)],
                stops: [0, .3, 1],
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final on = i == _img;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: on ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _thumbs(List<String> images) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => Pressable(
              onTap: () => _pager.animateToPage(i,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 64,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: i == _img ? AppColors.ink : Colors.transparent,
                      width: 2),
                ),
                child: Opacity(
                  opacity: i == _img ? 1 : .6,
                  child: NetImage(images[i], radius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _titleBlock(Product p, AppState app) {
    final kicker = p.brand.isNotEmpty ? p.brand : p.categoryName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (kicker.isNotEmpty)
            Text(kicker.toUpperCase(),
                style: AppTheme.font(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AppColors.ember,
                    spacing: 1.5)),
          const Spacer(),
          _stockBadge(p),
        ]),
        const SizedBox(height: 4),
        Text(p.name,
            style:
                AppTheme.font(size: 26, weight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: PriceTag(
                price: p.price,
                old: p.oldPrice,
                currency: app.currency,
                big: true),
          ),
          if (p.reviewsCount > 0 || p.rating > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.star_rounded, color: AppColors.ember, size: 18),
                const SizedBox(width: 3),
                Text(p.rating.toStringAsFixed(1),
                    style: AppTheme.font(weight: FontWeight.w700)),
                Text('  (${p.reviewsCount})',
                    style: AppTheme.font(size: 12, color: AppColors.muted)),
              ]),
            ),
        ]),
      ],
    );
  }

  Widget _stockBadge(Product p) {
    final ok = p.inStock;
    final low = ok && p.stock > 0 && p.stock <= 5;
    final c = !ok ? AppColors.danger : (low ? AppColors.ember : AppColors.success);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(!ok ? 'Sold out' : (low ? 'Only ${p.stock} left' : 'In stock'),
          style: AppTheme.font(size: 12, weight: FontWeight.w600, color: c)),
    ]);
  }

  Widget _optionGroup(OptionGroup g) {
    final isColor = g.key == 'color';
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(
                text: '${g.label}: ',
                style: AppTheme.font(weight: FontWeight.w700)),
            TextSpan(
                text: _selected[g.key] ?? '',
                style: AppTheme.font(color: AppColors.muted)),
          ])),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: g.values.map((v) {
              final on = _selected[g.key] == v;
              final color = isColor ? _parseColor(v) : null;
              return Pressable(
                onTap: () => setState(() => _selected[g.key] = v),
                child: color != null
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: on ? AppColors.ink : Colors.transparent,
                              width: 2),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.line),
                          ),
                        ),
                      )
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: on ? AppColors.ink : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(v,
                            style: AppTheme.font(
                                weight: FontWeight.w600,
                                color: on ? Colors.white : AppColors.text)),
                      ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String v) {
    var s = v.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(s)) {
      return Color(int.parse('FF$s', radix: 16));
    }
    const names = <String, Color>{
      'black': Color(0xFF1B1B1B), 'أسود': Color(0xFF1B1B1B),
      'white': Color(0xFFFAFAFA), 'أبيض': Color(0xFFFAFAFA),
      'red': Color(0xFFD7263D), 'أحمر': Color(0xFFD7263D),
      'blue': Color(0xFF2F5BEA), 'أزرق': Color(0xFF2F5BEA),
      'navy': Color(0xFF1E2A4A), 'كحلي': Color(0xFF1E2A4A),
      'green': Color(0xFF2E7D4F), 'أخضر': Color(0xFF2E7D4F),
      'pink': Color(0xFFE8A0B4), 'وردي': Color(0xFFE8A0B4), 'زهري': Color(0xFFE8A0B4),
      'grey': Color(0xFF9A9A9A), 'gray': Color(0xFF9A9A9A), 'رمادي': Color(0xFF9A9A9A),
      'beige': Color(0xFFD9C7A7), 'بيج': Color(0xFFD9C7A7),
      'cream': Color(0xFFEFE6D2), 'كريمي': Color(0xFFEFE6D2),
      'brown': Color(0xFF6B4A35), 'بني': Color(0xFF6B4A35),
      'orange': AppColors.ember, 'برتقالي': AppColors.ember,
      'yellow': Color(0xFFF2C94C), 'أصفر': Color(0xFFF2C94C),
      'purple': Color(0xFF6D4AFF), 'موف': Color(0xFF6D4AFF),
    };
    return names[s.toLowerCase()];
  }

  // ───── Sizes ─────
  Widget _sizeBlock() {
    final sizes = _sizes;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Size', style: AppTheme.font(size: 16, weight: FontWeight.w700)),
            Text('  EU',
                style: AppTheme.font(size: 12, color: AppColors.muted)),
            const Spacer(),
            Pressable(
              onTap: _sizeGuide,
              child: Row(children: [
                const Icon(Icons.straighten_rounded,
                    size: 17, color: AppColors.ember),
                const SizedBox(width: 4),
                Text('Size guide',
                    style: AppTheme.font(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.ember)
                        .copyWith(decoration: TextDecoration.underline,
                            decorationColor: AppColors.ember)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: sizes.map((s) {
              final on = _size == s;
              return Pressable(
                onTap: () => setState(() => _size = on ? null : s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: on ? AppColors.ink : AppColors.line),
                  ),
                  child: Text(s,
                      style: AppTheme.font(
                          size: 15,
                          weight: FontWeight.w600,
                          color: on ? Colors.white : AppColors.text)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _sizeGuide() {
    const rows = [
      ['36', '4', '3.5', '22.5'],
      ['37', '5', '4', '23.5'],
      ['38', '6', '5', '24'],
      ['39', '6.5', '5.5', '24.5'],
      ['40', '7', '6', '25'],
      ['41', '8', '7', '26'],
      ['42', '8.5', '7.5', '26.5'],
      ['43', '9.5', '8.5', '27.5'],
      ['44', '10', '9', '28'],
      ['45', '11', '10', '29'],
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetTitle('Size guide'),
            Text('Measure your foot from heel to longest toe, then pick the closest size in centimeters.',
                style: AppTheme.font(color: AppColors.muted, height: 1.6)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.ink),
                    children: ['EU', 'US', 'UK', 'cm']
                        .map((h) => _cell(h, header: true))
                        .toList(),
                  ),
                  for (int i = 0; i < rows.length; i++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: rows[i][0] == _size
                            ? AppColors.emberSoft
                            : (i.isEven ? AppColors.surface : AppColors.bone),
                      ),
                      children: rows[i].map((c) => _cell(c)).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String t, {bool header = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Text(t,
            textAlign: TextAlign.center,
            style: AppTheme.font(
                size: 13.5,
                weight: header ? FontWeight.w700 : FontWeight.w500,
                color: header ? Colors.white : AppColors.text)),
      );

  Widget _perks(AppState app) {
    final fee = app.store?.deliveryFee ?? 0;
    final items = [
      (Icons.local_shipping_outlined, 'Delivery',
          fee == 0 ? 'Free' : money(fee, currency: app.currency)),
      (Icons.verified_outlined, 'Authenticity', 'Genuine product'),
      (Icons.payments_outlined, 'Payment', 'Cash on delivery'),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: AppColors.bone, shape: BoxShape.circle),
                child: Icon(it.$1, size: 20),
              ),
              const SizedBox(height: 6),
              Text(it.$2,
                  style: AppTheme.font(size: 11, color: AppColors.muted)),
              Text(it.$3,
                  style: AppTheme.font(size: 12.5, weight: FontWeight.w600)),
            ]),
          ),
      ]),
    );
  }

  Widget _description(Product p) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About this pair',
                style: AppTheme.font(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              alignment: Alignment.topCenter,
              child: Text(p.description,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: AppTheme.font(
                      color: AppColors.body, height: 1.75)),
            ),
            if (p.description.length > 140)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_expanded ? 'Show less' : 'Read more',
                      style: AppTheme.font(
                          weight: FontWeight.w700, color: AppColors.ink)),
                ),
              ),
          ],
        ),
      );

  Widget _reviewsBlock(Product p) {
    return Container(
      margin: const EdgeInsets.only(top: 26),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Reviews',
                  style: AppTheme.font(size: 16, weight: FontWeight.w700)),
            ),
            Pressable(
              onTap: _writeReview,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bone,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 15),
                  const SizedBox(width: 4),
                  Text('Rate', style: AppTheme.font(size: 12.5, weight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          if (p.rating > 0) ...[
            const SizedBox(height: 10),
            Row(children: [
              Text(p.rating.toStringAsFixed(1),
                  style: AppTheme.font(size: 38, weight: FontWeight.w800, height: 1)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stars(p.rating.round(), 18),
                  Text('from ${p.reviewsCount} reviews',
                      style: AppTheme.font(size: 12, color: AppColors.muted)),
                ],
              ),
            ]),
          ],
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('No reviews yet — be the first to rate!',
                  style: AppTheme.font(color: AppColors.muted)),
            ),
          for (final r in _reviews) ...[
            const Divider(height: 26, color: AppColors.line),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.ink,
                child: Text(r.name.isNotEmpty ? r.name.characters.first : '?',
                    style: AppTheme.font(
                        weight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(r.name,
                            style: AppTheme.font(weight: FontWeight.w600)),
                      ),
                      _stars(r.rating, 14),
                    ]),
                    if (r.date.isNotEmpty)
                      Text(r.date,
                          style: AppTheme.font(size: 11, color: AppColors.muted)),
                    if (r.comment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(r.comment,
                            style: AppTheme.font(
                                size: 13.5,
                                color: AppColors.body,
                                height: 1.6)),
                      ),
                  ],
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _stars(int n, double s) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
            5,
            (i) => Icon(Icons.star_rounded,
                size: s, color: i < n ? AppColors.ember : AppColors.sand2)),
      );

  Future<void> _writeReview() async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    int rating = 5;
    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              22, 0, 22, MediaQuery.of(ctx).viewInsets.bottom + 26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SheetTitle('How was your experience?'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Pressable(
                  scale: .8,
                  onTap: () => set(() => rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.star_rounded,
                        size: 42,
                        color: i < rating ? AppColors.ember : AppColors.sand2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Tell us what you think of this pair...'),
            ),
            const SizedBox(height: 18),
            AppButton(label: 'Submit review', onTap: () => Navigator.pop(ctx, true)),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.addReview(_p!.id, rating, ctrl.text.trim());
      if (mounted) showMsg(context, 'Thanks for your review 🧡');
      _loadReviews();
    } on ApiException catch (e) {
      if (!mounted) return;
      showMsg(
        context,
        e.code == 'REVIEW_REQUIRES_PURCHASE'
            ? 'You can review after receiving an order with this pair'
            : e.friendly,
        error: true,
      );
    }
  }

  // ───── Bottom bar ─────
  Widget _bottomBar(Product p, AppState app) => Container(
        margin: EdgeInsets.fromLTRB(
            14, 0, 14, MediaQuery.of(context).padding.bottom + 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(children: [
          QtyStepper(
            dark: true,
            value: _qty,
            onChanged: (v) => setState(() => _qty = v.clamp(1, 20).toInt()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _added
                  ? Container(
                      key: const ValueKey('ok'),
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('Added to bag',
                              style: AppTheme.font(
                                  weight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    )
                  : AppButton(
                      key: const ValueKey('add'),
                      height: 52,
                      style: AppButtonStyle.ember,
                      label: _size == null
                          ? 'Select size'
                          : 'Add · ${money(p.price * _qty, currency: app.currency)}',
                      loading: _adding,
                      onTap: p.inStock && _full ? _addToCart : null,
                    ),
            ),
          ),
        ]),
      );
}
