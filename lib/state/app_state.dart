import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/firebase_auth_service.dart';
import '../models/models.dart';

/// Global app state: store, account, cart, favorites
class AppState extends ChangeNotifier {
  final api = ApiClient.instance;

  StoreInfo? store;
  Customer? customer;
  Cart cart = Cart.empty();
  final Set<String> favoriteIds = {};
  int tab = 0;

  bool get loggedIn => (api.token ?? '').isNotEmpty;
  String get currency => store?.currency ?? '₪';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString('token');
    try {
      store = StoreInfo.fromJson((await api.storeInfo()).data);
    } catch (_) {}
    if (loggedIn) {
      try {
        customer = Customer.fromJson((await api.me()).data);
        await Future.wait([refreshCart(), refreshFavorites()]);
      } on ApiException catch (e) {
        if (e.status == 401) await _clearToken();
      }
    }
    notifyListeners();
  }

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  Future<void> _saveToken(String t) async {
    api.token = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);
  }

  Future<void> _clearToken() async {
    api.token = null;
    customer = null;
    cart = Cart.empty();
    favoriteIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> _afterAuth(ApiResponse r) async {
    final d = asMap(r.data);
    final t = d['token'] ?? d['access_token'];
    if (t == null) throw ApiException('No auth token received');
    await _saveToken(t.toString());
    customer = Customer.fromJson(d);
    await Future.wait([refreshCart(), refreshFavorites()]);
    notifyListeners();
  }

  final gate = FirebaseGate.instance;

  /// Sign in = Firebase identity check (verified email) → store API session.
  /// Throws [EmailNotVerified] when the user still has to confirm the email.
  Future<void> login(String email, String password) async {
    final user = await gate.signIn(email, password);
    if (user == null) {
      // No Firebase account yet: maybe an older store account.
      // Check the credentials with the store, then mirror it into Firebase
      // and ask for verification. Wrong credentials throw here.
      final r = await api.login(email, password);
      await gate.createAccount(Customer.fromJson(r.data).name, email, password);
      throw EmailNotVerified(email);
    }
    if (!await gate.isVerified()) throw EmailNotVerified(email);
    await _afterAuth(await api.login(email, password));
  }

  /// Sign up = create the Firebase account (sends the verification email)
  /// + create the store account. The store session starts only after the
  /// email is verified (see [login]).
  Future<void> register(Map<String, dynamic> body) async {
    final email = '${body['email']}';
    await gate.createAccount('${body['name']}', email, '${body['password']}');
    try {
      await api.register(body);
    } catch (_) {
      await gate.deleteCurrentUser(); // keep both systems in sync
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}
    await gate.signOut();
    await _clearToken();
    notifyListeners();
  }

  Future<void> updateProfile(String name, String phone) async {
    final r = await api.updateProfile(name, phone);
    customer = Customer.fromJson(r.data);
    if (customer!.name.isEmpty) {
      customer = Customer(name, customer!.email, phone);
    }
    notifyListeners();
  }

  // ───── Cart ─────
  void _setCart(ApiResponse r) {
    cart = Cart.fromJson(r.data);
    notifyListeners();
  }

  Future<void> refreshCart() async {
    if (!loggedIn) return;
    try {
      _setCart(await api.cart());
    } catch (_) {}
  }

  Future<void> addToCart(String productId, int qty,
          {Map<String, dynamic>? options}) async =>
      _setCart(await api.addToCart(productId, qty, options: options));

  Future<void> setQty(CartItem item, int qty) async {
    if (qty < 1) return removeItem(item);
    _setCart(await api.updateCartItem(item.id, qty));
  }

  Future<void> removeItem(CartItem item) async =>
      _setCart(await api.removeCartItem(item.id));

  Future<void> clearCart() async => _setCart(await api.clearCart());

  Future<void> applyCoupon(String code) async =>
      _setCart(await api.applyCoupon(code));

  Future<void> removeCoupon() async => _setCart(await api.removeCoupon());

  // ───── Favorites ─────
  Future<void> refreshFavorites() async {
    if (!loggedIn) return;
    try {
      final list = asList((await api.favorites()).data)
          .map(Product.fromJson)
          .toList();
      favoriteIds
        ..clear()
        ..addAll(list.map((e) => e.id));
      notifyListeners();
    } catch (_) {}
  }

  bool isFav(Product p) => favoriteIds.contains(p.id) || p.isFavorite;

  Future<bool> toggleFavorite(Product p) async {
    final r = await api.toggleFavorite(p.id);
    final d = asMap(r.data);
    final fav = d.containsKey('is_favorite')
        ? pickBool(d, ['is_favorite'])
        : !isFav(p);
    p.isFavorite = fav;
    fav ? favoriteIds.add(p.id) : favoriteIds.remove(p.id);
    notifyListeners();
    return fav;
  }
}
