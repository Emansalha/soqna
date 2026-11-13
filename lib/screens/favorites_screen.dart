import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Product>? _items;
  String? _error;
  int _lastSig = -1;

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.favorites();
      if (!mounted) return;
      setState(() {
        _items = asList(r.data).map(Product.fromJson).toList();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Reload when favorites or auth change
    final sig = Object.hashAll([app.loggedIn, ...app.favoriteIds]);
    if (app.loggedIn && sig != _lastSig) {
      _lastSig = sig;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    final count = _items?.length ?? 0;

    final header = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WISHLIST',
                    style: AppTheme.font(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.ember,
                        spacing: 3)),
                Text('Wishlist',
                    style: AppTheme.font(size: 30, weight: FontWeight.w800)),
              ],
            ),
          ),
          if (count > 0)
            Text('$count pairs',
                style: AppTheme.font(color: AppColors.muted)),
        ]),
      ),
    );

    Widget body;
    if (!app.loggedIn) {
      body = const LoginRequired(title: 'Sign in to save your favorite sneakers');
    } else if (_error != null && _items == null) {
      body = ErrorView(_error!, onRetry: _load);
    } else if (_items == null) {
      body = const Loader();
    } else if (_items!.isEmpty) {
      body = EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Your wishlist is empty',
        subtitle: 'Tap ♡ on any sneaker to save it here',
        action: 'Discover sneakers',
        onAction: () => app.setTab(0),
      );
    } else {
      return Scaffold(
        body: RefreshIndicator(
          color: AppColors.ember,
          onRefresh: _load,
          child: ProductGrid(_items!, header: header),
        ),
      );
    }
    return Scaffold(
      body: Column(children: [header, Expanded(child: body)]),
    );
  }
}
