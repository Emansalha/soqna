import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

/// Sneaker list: category / search / filter & sort — with infinite paging
class ProductsScreen extends StatefulWidget {
  final String title;
  final String? categoryId, sort;
  final bool featured, searchMode, openFilters;
  const ProductsScreen({
    super.key,
    required this.title,
    this.categoryId,
    this.sort,
    this.featured = false,
    this.searchMode = false,
    this.openFilters = false,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<Product> _items = [];
  int _page = 1, _lastPage = 1, _total = 0;
  bool _loading = false, _first = true;
  String? _error;

  late String? _sort = widget.sort;
  String _order = 'desc';
  RangeValues? _price;
  bool _inStock = false;

  /// Quick sort options: (sort, order, label)
  static const _quick = [
    ('newest', 'desc', 'Newest'),
    ('best_selling', 'desc', 'Best selling'),
    ('price', 'asc', 'Price ↑'),
    ('price', 'desc', 'Price ↓'),
    ('rating', 'desc', 'Top rated'),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
    if (!widget.searchMode) _reload();
    if (widget.openFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilters());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    _page = 1;
    _lastPage = 1;
    _items.clear();
    setState(() => _first = true);
    await _fetch();
  }

  Future<void> _loadMore() async {
    if (_loading || _page >= _lastPage) return;
    _page++;
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiClient.instance.products(
        categoryId: widget.categoryId,
        q: _searchCtrl.text.trim(),
        sort: _sort,
        order: _sort == null ? null : _order,
        featured: widget.featured,
        inStock: _inStock,
        minPrice: _price?.start.round(),
        maxPrice: _price?.end.round(),
        page: _page,
      );
      final list = asList(r.data).map(Product.fromJson).toList();
      _lastPage =
          (pickNum(r.meta, ['last_page', 'total_pages']) ?? _page).toInt();
      _total = (pickNum(r.meta, ['total']) ?? 0).toInt();
      setState(() => _items.addAll(list));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _first = false;
        });
      }
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (_searchCtrl.text.trim().isEmpty) {
        setState(_items.clear);
      } else {
        _reload();
      }
    });
  }

  int get _activeFilters => (_price != null ? 1 : 0) + (_inStock ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _topBar(),
          _quickSort(),
          Expanded(child: _body()),
        ]),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(children: [
          CircleBtn(Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: widget.searchMode
                ? SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      onChanged: _onSearch,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _reload(),
                      style: AppTheme.font(),
                      decoration: InputDecoration(
                        hintText: 'Search models, brands...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.font(
                              size: 20, weight: FontWeight.w700)),
                      if (!_first)
                        Text(
                            '${_total > 0 ? _total : _items.length} products',
                            style: AppTheme.font(
                                size: 12, color: AppColors.muted)),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          Stack(clipBehavior: Clip.none, children: [
            CircleBtn(Icons.tune_rounded,
                bg: AppColors.ink, color: Colors.white, onTap: _showFilters),
            if (_activeFilters > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ember,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bone, width: 2),
                  ),
                  child: Text('$_activeFilters',
                      style: AppTheme.font(
                          size: 9, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
          ]),
        ]),
      );

  Widget _quickSort() => SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: _quick.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final q = _quick[i];
            final on = _sort == q.$1 && (_sort != 'price' || _order == q.$2);
            return Pressable(
              onTap: () {
                setState(() {
                  if (on) {
                    _sort = null;
                  } else {
                    _sort = q.$1;
                    _order = q.$2;
                  }
                });
                if (!widget.searchMode || _searchCtrl.text.isNotEmpty) {
                  _reload();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppColors.ink : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(q.$3,
                    style: AppTheme.font(
                        size: 13,
                        weight: FontWeight.w600,
                        color: on ? Colors.white : AppColors.text)),
              ),
            );
          },
        ),
      );

  Widget _body() {
    if (widget.searchMode &&
        _searchCtrl.text.trim().isEmpty &&
        _items.isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'What are you looking for?',
        subtitle: 'Type a model or brand name',
      );
    }
    if (_first && _loading) return const Loader();
    if (_error != null && _items.isEmpty) {
      return ErrorView(_error!, onRetry: _reload);
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.do_not_step_rounded,
        title: 'No matching sneakers',
        subtitle: _activeFilters > 0 ? 'Try loosening your filters' : '',
      );
    }
    return RefreshIndicator(
      color: AppColors.ember,
      onRefresh: _reload,
      child: ProductGrid(
        _items,
        controller: _scroll,
        footer: _loading
            ? const Padding(padding: EdgeInsets.all(16), child: Loader())
            : null,
      ),
    );
  }

  Future<void> _showFilters() async {
    RangeValues price = _price ?? const RangeValues(0, 1000);
    bool priceOn = _price != null;
    bool inStock = _inStock;

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetTitle('Filters',
                  trailing: TextButton(
                    onPressed: () => set(() {
                      priceOn = false;
                      inStock = false;
                    }),
                    child: Text('Clear all',
                        style: AppTheme.font(
                            color: AppColors.ember, weight: FontWeight.w600)),
                  )),
              _filterCard(
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Text('Price range',
                          style: AppTheme.font(weight: FontWeight.w600)),
                    ),
                    Switch(
                        value: priceOn,
                        onChanged: (v) => set(() => priceOn = v)),
                  ]),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: priceOn
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(children: [
                      SliderTheme(
                        data: SliderTheme.of(ctx).copyWith(
                          activeTrackColor: AppColors.ink,
                          inactiveTrackColor: AppColors.sand,
                          thumbColor: AppColors.ember,
                          trackHeight: 4,
                        ),
                        child: RangeSlider(
                          values: price,
                          min: 0,
                          max: 1000,
                          divisions: 50,
                          onChanged: (v) => set(() => price = v),
                        ),
                      ),
                      Row(children: [
                        _priceBox('Min', price.start.round()),
                        const SizedBox(width: 10),
                        _priceBox('Max', price.end.round()),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              _filterCard(
                child: Row(children: [
                  Expanded(
                    child: Text('In stock only',
                        style: AppTheme.font(weight: FontWeight.w600)),
                  ),
                  Switch(value: inStock, onChanged: (v) => set(() => inStock = v)),
                ]),
              ),
              const SizedBox(height: 20),
              AppButton(
                  label: 'Show results',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => Navigator.pop(ctx, true)),
            ],
          ),
        );
      }),
    );
    if (apply == true) {
      _price = priceOn ? price : null;
      _inStock = inStock;
      _reload();
    }
  }

  Widget _filterCard({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      );

  Widget _priceBox(String l, int v) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.bone,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Text(l, style: AppTheme.font(size: 12, color: AppColors.muted)),
            const Spacer(),
            Text('$v', style: AppTheme.font(weight: FontWeight.w700)),
          ]),
        ),
      );
}
