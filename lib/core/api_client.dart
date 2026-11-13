import 'dart:convert';
import 'package:http/http.dart' as http;

/// Store settings — from the Postman collection
class ApiConfig {
  static const baseUrl = 'https://souqna.toldpath.com/api/v1';
  static const storeSlug = 'emans';
  static String get store => '$baseUrl/stores/$storeSlug';
}

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? status;
  final dynamic details;
  ApiException(this.message, {this.code, this.status, this.details});

  /// First field validation message, if any
  String get friendly {
    if (details is Map && (details as Map).isNotEmpty) {
      final first = (details as Map).values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String) return first;
    }
    return message;
  }

  @override
  String toString() => friendly;
}

/// Unified response: { success, message, data, meta }
class ApiResponse {
  final dynamic data;
  final Map<String, dynamic> meta;
  final String message;
  ApiResponse(this.data, this.meta, this.message);
}

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  String? token;

  Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        'Accept-Language': 'en',
        if (json) 'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    final full = path.startsWith('http') ? path : '${ApiConfig.store}$path';
    return Uri.parse(full).replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers()));

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) =>
      _send(() => http.post(_uri(path),
          headers: _headers(json: true), body: jsonEncode(body ?? {})));

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) =>
      _send(() => http.put(_uri(path),
          headers: _headers(json: true), body: jsonEncode(body ?? {})));

  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) =>
      _send(() => http.patch(_uri(path),
          headers: _headers(json: true), body: jsonEncode(body ?? {})));

  Future<ApiResponse> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers()));

  Future<ApiResponse> _send(Future<http.Response> Function() call) async {
    http.Response res;
    try {
      res = await call().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('Can\'t reach the server. Check your connection.');
    }
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException('Unexpected server response (${res.statusCode})',
          status: res.statusCode);
    }
    if (body is Map && body['success'] == true) {
      return ApiResponse(
        body['data'],
        body['meta'] is Map ? Map<String, dynamic>.from(body['meta']) : {},
        body['message']?.toString() ?? '',
      );
    }
    final err = body is Map ? body['error'] : null;
    throw ApiException(
      (body is Map ? body['message']?.toString() : null) ?? 'Something went wrong',
      code: err is Map ? err['code']?.toString() : null,
      details: err is Map ? err['details'] : null,
      status: res.statusCode,
    );
  }

  // ───── Endpoints ─────
  Future<bool> ping() async {
    try {
      final r = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/ping'), headers: _headers())
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<ApiResponse> storeInfo() => get('');
  Future<ApiResponse> home() => get('/home');
  Future<ApiResponse> categories() => get('/categories');
  Future<ApiResponse> products({
    String? categoryId,
    String? q,
    num? minPrice,
    num? maxPrice,
    bool? inStock,
    bool? featured,
    String? sort,
    String? order,
    int page = 1,
    int perPage = 15,
  }) =>
      get('/products', query: {
        'category_id': categoryId,
        'q': q,
        'min_price': minPrice,
        'max_price': maxPrice,
        if (inStock == true) 'in_stock': 1,
        if (featured == true) 'featured': 1,
        'sort': sort,
        'order': order,
        'page': page,
        'per_page': perPage,
      });
  Future<ApiResponse> product(String id) => get('/products/$id');
  Future<ApiResponse> reviews(String id, {int page = 1}) =>
      get('/products/$id/reviews', query: {'page': page});
  Future<ApiResponse> addReview(String id, int rating, String comment) =>
      post('/products/$id/reviews',
          body: {'rating': rating, 'comment': comment});

  // Auth
  Future<ApiResponse> register(Map<String, dynamic> body) =>
      post('/auth/register', body: {...body, 'device_name': 'flutter'});
  Future<ApiResponse> login(String email, String password) => post(
      '/auth/login',
      body: {'email': email, 'password': password, 'device_name': 'flutter'});
  Future<ApiResponse> me() => get('/auth/me');
  Future<ApiResponse> updateProfile(String name, String phone) =>
      put('/auth/profile', body: {'name': name, 'phone': phone});
  Future<ApiResponse> logout() => post('/auth/logout');

  // Cart
  Future<ApiResponse> cart() => get('/cart');
  Future<ApiResponse> addToCart(String productId, int qty,
          {Map<String, dynamic>? options}) =>
      post('/cart/items', body: {
        'product_id': productId,
        'quantity': qty,
        if (options != null && options.isNotEmpty) 'options': options,
      });
  Future<ApiResponse> updateCartItem(String itemId, int qty) =>
      patch('/cart/items/$itemId', body: {'quantity': qty});
  Future<ApiResponse> removeCartItem(String itemId) =>
      delete('/cart/items/$itemId');
  Future<ApiResponse> clearCart() => delete('/cart');
  Future<ApiResponse> applyCoupon(String code) =>
      post('/cart/coupon', body: {'code': code});
  Future<ApiResponse> removeCoupon() => delete('/cart/coupon');

  // Orders
  Future<ApiResponse> checkout(Map<String, dynamic> body) =>
      post('/checkout', body: body);
  Future<ApiResponse> orders() => get('/orders');
  Future<ApiResponse> order(String id) => get('/orders/$id');
  Future<ApiResponse> cancelOrder(String id) => post('/orders/$id/cancel');

  // Favorites
  Future<ApiResponse> toggleFavorite(String productId) =>
      post('/favorites/$productId');
  Future<ApiResponse> favorites() => get('/favorites');
}
