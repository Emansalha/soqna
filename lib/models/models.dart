import '../core/sneaker_images.dart';

// Data models — lenient parsing to tolerate varying API field names

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> asList(dynamic v) {
  if (v is List) return v;
  if (v is Map) {
    for (final k in ['items', 'data', 'products', 'list', 'results']) {
      if (v[k] is List) return v[k];
    }
  }
  return const [];
}

String pickStr(Map j, List<String> keys, [String def = '']) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is Map) {
      // Translated text {en:..., ar:...} or image {url: ...}
      final inner = v['en'] ?? v['url'] ?? v['original'] ?? v['ar'];
      if (inner != null && inner.toString().isNotEmpty) return inner.toString();
      continue;
    }
    final s = v.toString();
    if (s.isNotEmpty && s != 'null') return s;
  }
  return def;
}

num? pickNum(Map j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is num) return v;
    if (v is Map) {
      final inner = v['amount'] ?? v['value'];
      if (inner is num) return inner;
      final p = num.tryParse('$inner');
      if (p != null) return p;
    }
    final p = num.tryParse(v.toString().replaceAll(',', ''));
    if (p != null) return p;
  }
  return null;
}

bool pickBool(Map j, List<String> keys, [bool def = false]) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return def;
}

List<String> pickImages(Map j) {
  final out = <String>[];
  void add(dynamic v) {
    if (v == null) return;
    if (v is String && v.isNotEmpty) out.add(v);
    if (v is Map) add(v['url'] ?? v['original'] ?? v['src'] ?? v['path']);
    if (v is List) v.forEach(add);
  }

  for (final k in [
    'image', 'image_url', 'thumbnail', 'cover', 'main_image', 'photo',
    'images', 'gallery', 'photos'
  ]) {
    add(j[k]);
  }
  return out.toSet().toList();
}

/// Product images: from the API, or curated demo sneaker shots
List<String> productImages(Map j, String id) {
  final api = pickImages(j);
  if (SneakerImages.forceDemoPhotos || api.isEmpty) {
    return SneakerImages.galleryFor(id.isEmpty ? '${j['name']}' : id);
  }
  return api;
}

class StoreInfo {
  final String name, description, logo, cover, phone, email, whatsapp, address,
      instagram, facebook, currency;
  final num deliveryFee, minOrder;
  final String? primaryColor;
  final Map<String, dynamic> raw;

  StoreInfo({
    required this.name,
    required this.description,
    required this.logo,
    required this.cover,
    required this.phone,
    required this.email,
    required this.whatsapp,
    required this.address,
    required this.instagram,
    required this.facebook,
    required this.currency,
    required this.deliveryFee,
    required this.minOrder,
    required this.primaryColor,
    required this.raw,
  });

  factory StoreInfo.fromJson(dynamic d) {
    final j = asMap(d);
    final contact = asMap(j['contact']);
    final social = asMap(j['social'] ?? contact['social']);
    final delivery = asMap(j['delivery']);
    final theme = asMap(j['theme']);
    return StoreInfo(
      name: pickStr(j, ['name', 'title'], 'My Store'),
      description: pickStr(j, ['description', 'about', 'bio']),
      logo: pickStr(j, ['logo', 'logo_url']),
      cover: pickStr(j, ['cover', 'cover_url', 'banner']),
      phone: pickStr(contact, ['phone', 'mobile'], pickStr(j, ['phone'])),
      email: pickStr(contact, ['email'], pickStr(j, ['email'])),
      whatsapp: pickStr(contact, ['whatsapp'], pickStr(j, ['whatsapp'])),
      address: pickStr(contact, ['address', 'location'],
          pickStr(j, ['address', 'city'])),
      instagram: pickStr(social, ['instagram'], pickStr(contact, ['instagram'])),
      facebook: pickStr(social, ['facebook'], pickStr(contact, ['facebook'])),
      currency: pickStr(j, ['currency_symbol', 'currency'], '₪'),
      deliveryFee: pickNum(delivery, ['fee', 'delivery_fee']) ??
          pickNum(j, ['delivery_fee']) ??
          0,
      minOrder: pickNum(delivery, ['min_order', 'minimum_order']) ??
          pickNum(j, ['min_order', 'minimum_order']) ??
          0,
      primaryColor: theme['primary_color']?.toString(),
      raw: j,
    );
  }
}

class BannerItem {
  final String id, title, subtitle, image, link, productId, categoryId;
  BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.link,
    required this.productId,
    required this.categoryId,
  });
  /// [index] picks a distinct hero photo for banners that have no image.
  factory BannerItem.fromJson(dynamic d, [int index = 0]) {
    final j = asMap(d);
    final imgs = pickImages(j);
    final id = pickStr(j, ['id']);
    final fallback = SneakerImages.hero(index);
    return BannerItem(
      id: id,
      // "Solar Gold — Limited Edition" → two-line headline
      title: pickStr(j, ['title', 'name', 'heading']).replaceFirst(' — ', '\n'),
      subtitle: pickStr(j, ['subtitle', 'description', 'text', 'body']),
      image: SneakerImages.forceDemoPhotos || imgs.isEmpty
          ? fallback
          : imgs.first,
      link: pickStr(j, ['link', 'url', 'action_url']),
      productId: pickStr(j, ['product_id'],
          pickStr(j, ['link_type']) == 'product' ? pickStr(j, ['link_id']) : ''),
      categoryId: pickStr(j, ['category_id'],
          pickStr(j, ['link_type']) == 'category' ? pickStr(j, ['link_id']) : ''),
    );
  }
}

class Category {
  final String id, name, image;
  final int count;
  Category(
      {required this.id,
      required this.name,
      required this.image,
      required this.count});
  factory Category.fromJson(dynamic d) {
    final j = asMap(d);
    final imgs = pickImages(j);
    final id = pickStr(j, ['id', 'slug']);
    final name = pickStr(j, ['name', 'title'], 'Category');
    return Category(
      id: id,
      name: name,
      image: SneakerImages.forceDemoPhotos || imgs.isEmpty
          ? SneakerImages.forCategory(name, id.hashCode.abs())
          : imgs.first,
      count:
          (pickNum(j, ['products_count', 'product_count', 'count']) ?? 0).toInt(),
    );
  }
}

/// Product option group (e.g. size, color)
class OptionGroup {
  final String key, label;
  final List<String> values;
  OptionGroup(this.key, this.label, this.values);
}

class Product {
  final String id, name, description, categoryName, brand;
  final List<String> images;
  final num price;
  final num? oldPrice;
  final double rating;
  final int reviewsCount, stock;
  final bool inStock, featured;
  bool isFavorite;
  final List<OptionGroup> options;
  final List<Product> related;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryName,
    required this.brand,
    required this.images,
    required this.price,
    required this.oldPrice,
    required this.rating,
    required this.reviewsCount,
    required this.stock,
    required this.inStock,
    required this.featured,
    required this.isFavorite,
    required this.options,
    required this.related,
  });

  String get image => images.isNotEmpty ? images.first : '';
  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  int get discountPercent =>
      hasDiscount ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;

  factory Product.fromJson(dynamic d) {
    final j = asMap(d);
    // Product nested under a `product` key (e.g. favorites)
    if (j['product'] is Map && j['name'] == null) {
      return Product.fromJson(j['product']);
    }
    final sale = pickNum(j, ['sale_price', 'discount_price', 'final_price']);
    final base = pickNum(j, ['price', 'regular_price']) ?? 0;
    num price = base;
    num? old = pickNum(j, ['old_price', 'compare_price', 'compare_at_price', 'original_price']);
    if (sale != null && sale > 0 && sale < base) {
      price = sale;
      old = base;
    }
    final summary = asMap(j['reviews_summary']);
    final cat = j['category'];
    final stock = (pickNum(j, ['stock', 'quantity', 'stock_quantity']) ?? 999).toInt();
    final id = pickStr(j, ['id']);
    final b = j['brand'];

    return Product(
      id: id,
      name: pickStr(j, ['name', 'title'], 'Product'),
      description: pickStr(j, ['description', 'short_description', 'details']),
      categoryName: cat is Map
          ? pickStr(cat, ['name'])
          : pickStr(j, ['category_name']),
      brand: b is Map ? pickStr(b, ['name']) : pickStr(j, ['brand', 'brand_name']),
      images: productImages(j, id),
      price: price,
      oldPrice: old,
      rating: (pickNum(summary, ['average', 'avg', 'rating']) ??
              pickNum(j, ['rating', 'average_rating', 'rating_avg']) ??
              0)
          .toDouble(),
      reviewsCount: (pickNum(summary, ['count', 'total']) ??
              pickNum(j, ['reviews_count', 'rating_count']) ??
              0)
          .toInt(),
      stock: stock,
      inStock: pickBool(j, ['in_stock', 'is_available', 'available'], stock > 0),
      featured: pickBool(j, ['featured', 'is_featured']),
      isFavorite: pickBool(j, ['is_favorite', 'favorited']),
      options: _parseOptions(j),
      related: asList(j['related']).map(Product.fromJson).toList(),
    );
  }

  static List<OptionGroup> _parseOptions(Map<String, dynamic> j) {
    final out = <OptionGroup>[];
    const labels = {
      'size': 'Size',
      'sizes': 'Size',
      'color': 'Color',
      'colors': 'Color',
      // Arabic keys coming from the dashboard → English labels
      'المقاس': 'Size',
      'مقاس': 'Size',
      'اللون': 'Color',
      'لون': 'Color',
    };
    String keyOf(String k) => k.endsWith('s') ? k.substring(0, k.length - 1) : k;
    List<String> vals(dynamic v) => v is List
        ? v
            .map<String>(
                (e) => e is Map ? pickStr(e, ['value', 'name', 'label']) : '$e')
            .where((e) => e.isNotEmpty)
            .toList()
        : v is String
            ? v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : <String>[];

    final o = j['options'];
    if (o is Map) {
      o.forEach((k, v) {
        final values = vals(v is Map ? v['values'] : v);
        if (values.isNotEmpty) {
          out.add(OptionGroup(keyOf('$k'), labels['$k'] ?? '$k', values));
        }
      });
    } else if (o is List) {
      for (final g in o) {
        if (g is Map) {
          final name = pickStr(g, ['key', 'name', 'label']);
          final values = vals(g['values'] ?? g['options']);
          if (name.isNotEmpty && values.isNotEmpty) {
            out.add(OptionGroup(keyOf(name.toLowerCase()),
                labels[name.toLowerCase()] ?? pickStr(g, ['label', 'name']), values));
          }
        }
      }
    }
    if (out.isEmpty) {
      final attrs = asMap(j['attributes']);
      for (final k in ['sizes', 'colors']) {
        final values = vals(j[k] ?? attrs[k]);
        if (values.isNotEmpty) out.add(OptionGroup(keyOf(k), labels[k]!, values));
      }
    }
    // Shoe store: clothing sizes (XS…XXL / Free Size) are meaningless for
    // sneakers — drop them so the product page uses EU shoe sizes instead.
    out.removeWhere((g) =>
        g.key == 'size' &&
        !g.values.any((v) => RegExp(r'^\d{2}(\.5)?$').hasMatch(v.trim())));
    return out;
  }
}

class Review {
  final String name, comment, date;
  final int rating;
  Review(this.name, this.comment, this.rating, this.date);
  factory Review.fromJson(dynamic d) {
    final j = asMap(d);
    final c = asMap(j['customer'] ?? j['user']);
    return Review(
      pickStr(c, ['name'], pickStr(j, ['customer_name', 'name'], 'Customer')),
      pickStr(j, ['comment', 'body', 'text']),
      (pickNum(j, ['rating', 'stars']) ?? 0).toInt(),
      pickStr(j, ['created_at_human', 'date', 'created_at']),
    );
  }
}

class CartItem {
  final String id, productId, name, image;
  final num unitPrice, lineTotal;
  final int quantity;
  final Map<String, dynamic> options;
  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.unitPrice,
    required this.lineTotal,
    required this.quantity,
    required this.options,
  });
  String get optionsText =>
      options.entries.map((e) => '${e.value}').join(' • ');

  factory CartItem.fromJson(dynamic d) {
    final j = asMap(d);
    final p = asMap(j['product']);
    final pid = pickStr(j, ['product_id'], pickStr(p, ['id']));
    final apiImgs = [...pickImages(j), ...pickImages(p)];
    final imgs = SneakerImages.forceDemoPhotos || apiImgs.isEmpty
        ? [SneakerImages.forId(pid)]
        : apiImgs;
    final qty = (pickNum(j, ['quantity', 'qty']) ?? 1).toInt();
    final unit = pickNum(j, ['unit_price', 'price']) ??
        pickNum(p, ['sale_price', 'price']) ??
        0;
    return CartItem(
      id: pickStr(j, ['id']),
      productId: pid,
      name: pickStr(j, ['product_name', 'name'], pickStr(p, ['name'], 'Product')),
      image: imgs.isNotEmpty ? imgs.first : '',
      unitPrice: unit,
      lineTotal: pickNum(j, ['total', 'line_total', 'subtotal']) ?? unit * qty,
      quantity: qty,
      options: asMap(j['options']),
    );
  }
}

class Cart {
  final List<CartItem> items;
  final num subtotal, discount, deliveryFee, total, minOrder;
  final bool meetsMinOrder;
  final String? coupon;
  Cart({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.minOrder,
    required this.meetsMinOrder,
    required this.coupon,
  });
  int get count => items.fold(0, (s, e) => s + e.quantity);

  factory Cart.empty() => Cart(
      items: [],
      subtotal: 0,
      discount: 0,
      deliveryFee: 0,
      total: 0,
      minOrder: 0,
      meetsMinOrder: true,
      coupon: null);

  factory Cart.fromJson(dynamic d) {
    final j = asMap(d);
    final c = j['coupon'];
    return Cart(
      items: asList(j['items']).map(CartItem.fromJson).toList(),
      subtotal: pickNum(j, ['subtotal']) ?? 0,
      discount: pickNum(j, ['discount', 'discount_amount']) ?? 0,
      deliveryFee: pickNum(j, ['delivery_fee', 'shipping']) ?? 0,
      total: pickNum(j, ['total']) ?? 0,
      minOrder: pickNum(j, ['min_order', 'minimum_order']) ?? 0,
      meetsMinOrder: pickBool(j, ['meets_min_order'], true),
      coupon: c is Map
          ? pickStr(c, ['code'])
          : (c?.toString().isNotEmpty == true
              ? c.toString()
              : (j['coupon_code']?.toString())),
    );
  }
}

class TimelineStep {
  final String status, label, at;
  final bool done;
  TimelineStep(this.status, this.label, this.at, this.done);
}

const orderStatusLabels = {
  'pending': 'Awaiting confirmation',
  'confirmed': 'Confirmed',
  'preparing': 'Preparing',
  'shipped': 'Shipped',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
  'canceled': 'Cancelled',
};

class Order {
  final String id, number, status, statusLabel, date, address, paymentMethod;
  final num subtotal, discount, deliveryFee, total;
  final bool canCancel;
  final List<CartItem> items;
  final List<TimelineStep> timeline;

  Order({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.date,
    required this.address,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.canCancel,
    required this.items,
    required this.timeline,
  });

  factory Order.fromJson(dynamic d) {
    final j = asMap(d);
    final rawStatus = j['status'];
    final status = rawStatus is Map
        ? pickStr(rawStatus, ['key', 'value', 'code'])
        : pickStr(j, ['status'], 'pending');
    // Prefer our English labels; fall back to whatever the API sends
    final label = orderStatusLabels[status] ??
        (rawStatus is Map
            ? pickStr(rawStatus, ['label', 'name'], status)
            : pickStr(j, ['status_label'], status));

    final steps = <TimelineStep>[];
    final tl = j['timeline'];
    if (tl is List) {
      for (final s in tl) {
        final m = asMap(s);
        final st = pickStr(m, ['status', 'key', 'code']);
        final at = pickStr(m, ['at', 'time', 'date', 'created_at', 'done_at']);
        steps.add(TimelineStep(
          st,
          orderStatusLabels[st] ?? pickStr(m, ['label', 'title', 'name'], st),
          at,
          pickBool(m, ['done', 'completed', 'is_done', 'reached', 'active'],
              at.isNotEmpty),
        ));
      }
    } else if (tl is Map) {
      tl.forEach((k, v) {
        final at = v is Map ? pickStr(v, ['at', 'time', 'date']) : (v?.toString() ?? '');
        steps.add(TimelineStep('$k', orderStatusLabels['$k'] ?? '$k',
            at == 'null' ? '' : at, at.isNotEmpty && at != 'null'));
      });
    }

    return Order(
      id: pickStr(j, ['id']),
      number: pickStr(j, ['number', 'order_number', 'code', 'id']),
      status: status,
      statusLabel: label,
      date: pickStr(j, ['created_at_human', 'date', 'created_at']),
      address: pickStr(j, ['address', 'shipping_address']),
      paymentMethod: pickStr(j, ['payment_method']),
      subtotal: pickNum(j, ['subtotal']) ?? 0,
      discount: pickNum(j, ['discount']) ?? 0,
      deliveryFee: pickNum(j, ['delivery_fee']) ?? 0,
      total: pickNum(j, ['total', 'grand_total']) ?? 0,
      canCancel: pickBool(j, ['can_cancel'], status == 'pending'),
      items: asList(j['items']).map(CartItem.fromJson).toList(),
      timeline: steps,
    );
  }
}

class Customer {
  final String name, email, phone;
  Customer(this.name, this.email, this.phone);
  factory Customer.fromJson(dynamic d) {
    var j = asMap(d);
    if (j['customer'] is Map) j = asMap(j['customer']);
    if (j['user'] is Map) j = asMap(j['user']);
    return Customer(pickStr(j, ['name']), pickStr(j, ['email']),
        pickStr(j, ['phone', 'mobile']));
  }
}
