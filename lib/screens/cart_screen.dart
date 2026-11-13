import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _coupon = TextEditingController();
  bool _busy = false;

  Future<void> _run(Future<void> Function() f, {String? ok}) async {
    setState(() => _busy = true);
    try {
      await f();
      if (ok != null && mounted) showMsg(context, ok);
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cart = app.cart;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MY BAG',
                        style: AppTheme.font(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.ember,
                            spacing: 3)),
                    Text('My Bag',
                        style:
                            AppTheme.font(size: 30, weight: FontWeight.w800)),
                  ],
                ),
              ),
              if (cart.items.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${cart.count} items',
                      style: AppTheme.font(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: Colors.white)),
                ),
                const SizedBox(width: 8),
                CircleBtn(Icons.delete_sweep_outlined,
                    size: 38, onTap: () => _confirmClear(app)),
              ],
            ]),
          ),
          if (_busy)
            const LinearProgressIndicator(
                color: AppColors.ember,
                backgroundColor: Colors.transparent,
                minHeight: 2),
          Expanded(child: _content(app, cart)),
        ]),
      ),
    );
  }

  Widget _content(AppState app, Cart cart) {
    if (!app.loggedIn) {
      return const LoginRequired(title: 'Sign in to view your bag');
    }
    if (cart.items.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your bag is empty',
        subtitle: 'Your perfect pair is waiting. Start shopping now.',
        action: 'Discover sneakers',
        onAction: () => app.setTab(0),
      );
    }
    return RefreshIndicator(
      color: AppColors.ember,
      onRefresh: app.refreshCart,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          for (int i = 0; i < cart.items.length; i++)
            _itemTile(app, cart.items[i], i),
          if (cart.minOrder > 0) _minOrderBar(app, cart),
          const SizedBox(height: 8),
          _couponBox(app, cart),
          const SizedBox(height: 16),
          _summary(app, cart),
        ],
      ),
    );
  }

  Future<void> _confirmClear(AppState app) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Empty your bag?',
            style: AppTheme.font(size: 18, weight: FontWeight.w700)),
        content: Text('All items will be removed from your bag.',
            style: AppTheme.font(color: AppColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Cancel', style: AppTheme.font())),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('Empty',
                  style: AppTheme.font(
                      color: AppColors.danger, weight: FontWeight.w700))),
        ],
      ),
    );
    if (yes == true) _run(app.clearCart);
  }

  Widget _itemTile(AppState app, CartItem it, int i) {
    return Dismissible(
      key: ValueKey(it.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _run(() => app.removeItem(it)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.tint(i),
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: NetImage(it.image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                            size: 15, weight: FontWeight.w600)),
                  ),
                  Pressable(
                    onTap: () => _run(() => app.removeItem(it)),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.muted),
                  ),
                ]),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: [
                  for (final e in it.options.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bone,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          e.key == 'size' ? 'Size ${e.value}' : '${e.value}',
                          style: AppTheme.font(
                              size: 11, color: AppColors.muted)),
                    ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Text(money(it.lineTotal, currency: app.currency),
                        style: AppTheme.font(
                            size: 16, weight: FontWeight.w700)),
                  ),
                  QtyStepper(
                    compact: true,
                    value: it.quantity,
                    onChanged: (v) => _run(() => app.setQty(it, v)),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _minOrderBar(AppState app, Cart cart) {
    final progress =
        (cart.subtotal / cart.minOrder).clamp(0.0, 1.0).toDouble();
    final left = cart.minOrder - cart.subtotal;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cart.meetsMinOrder ? AppColors.sand : AppColors.emberSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cart.meetsMinOrder
                ? 'Nice! You\'ve reached the minimum order ✓'
                : 'Add ${money(left, currency: app.currency)} more to reach the minimum order',
            style: AppTheme.font(size: 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 7,
                color: cart.meetsMinOrder ? AppColors.success : AppColors.ember,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _couponBox(AppState app, Cart cart) {
    if (cart.coupon != null && cart.coupon!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.emberSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ember.withValues(alpha: .4)),
        ),
        child: Row(children: [
          const Icon(Icons.local_offer_rounded, color: AppColors.ember),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Coupon ${cart.coupon} applied',
                style: AppTheme.font(weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => _run(app.removeCoupon, ok: 'Coupon removed'),
            child: Text('Remove',
                style: AppTheme.font(color: AppColors.danger)),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(children: [
        const Icon(Icons.confirmation_number_outlined, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _coupon,
            textCapitalization: TextCapitalization.characters,
            style: AppTheme.font(weight: FontWeight.w600, spacing: 1),
            decoration: const InputDecoration(
              hintText: 'Promo code',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        AppButton(
          label: 'Apply',
          height: 44,
          onTap: () {
            final c = _coupon.text.trim();
            if (c.isEmpty) return;
            FocusScope.of(context).unfocus();
            _run(() => app.applyCoupon(c), ok: 'Coupon applied 🎉');
            _coupon.clear();
          },
        ),
      ]),
    );
  }

  Widget _summary(AppState app, Cart cart) {
    final c = app.currency;
    Widget row(String l, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(
                child: Text(l,
                    style: AppTheme.font(size: 14, color: Colors.white60))),
            Text(v,
                style: AppTheme.font(
                    size: 14,
                    weight: FontWeight.w600,
                    color: color ?? Colors.white)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(children: [
        row('Subtotal', money(cart.subtotal, currency: c)),
        if (cart.discount > 0)
          row('Discount', '- ${money(cart.discount, currency: c)}',
              color: AppColors.mint),
        row('Delivery',
            cart.deliveryFee == 0 ? 'Free' : money(cart.deliveryFee, currency: c)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: List.generate(
              30,
              (_) => Expanded(
                child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: Colors.white24),
              ),
            ),
          ),
        ),
        Row(children: [
          Expanded(
            child: Text('Total',
                style: AppTheme.font(
                    size: 16, weight: FontWeight.w600, color: Colors.white)),
          ),
          Text(money(cart.total, currency: c),
              style: AppTheme.font(
                  size: 26, weight: FontWeight.w800, color: AppColors.ember)),
        ]),
        const SizedBox(height: 18),
        AppButton(
          label: 'Checkout',
          icon: Icons.arrow_forward_rounded,
          style: AppButtonStyle.light,
          onTap: cart.meetsMinOrder
              ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()))
              : null,
        ),
      ]),
    );
  }
}
