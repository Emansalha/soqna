import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _pages = [
    HomeScreen(),
    CategoriesScreen(),
    FavoritesScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  /// Bottom bar hides while scrolling down and returns on scroll up
  bool _barVisible = true;

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final show = n.direction == ScrollDirection.forward ||
        (n.direction == ScrollDirection.idle && n.metrics.extentAfter < 40) ||
        n.metrics.pixels <= 0;
    final hide = n.direction == ScrollDirection.reverse;
    if (hide && _barVisible) setState(() => _barVisible = false);
    if (show && !_barVisible) setState(() => _barVisible = true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: IndexedStack(index: app.tab, children: _pages),
      ),
      bottomNavigationBar: SneakerBottomBar(
        index: app.tab,
        cartCount: app.cart.count,
        visible: _barVisible,
        onTap: (i) {
          HapticFeedback.selectionClick();
          if (!_barVisible) setState(() => _barVisible = true);
          app.setTab(i);
          if (i == 3) app.refreshCart();
          if (i == 2) app.refreshFavorites();
        },
      ),
    );
  }
}