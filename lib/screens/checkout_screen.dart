import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'order_details_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  String _payment = 'cash';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<AppState>().customer;
    _name.text = c?.name ?? '';
    _phone.text = c?.phone ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _loading = true);
    final app = context.read<AppState>();
    try {
      final r = await ApiClient.instance.checkout({
        'customer_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'notes': _notes.text.trim(),
        'payment_method': _payment,
      });
      final order = Order.fromJson(r.data);
      await app.refreshCart();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(number: order.number),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(orderId: order.id)));
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cart = app.cart;
    String? req(String? v) =>
        (v == null || v.trim().isEmpty) ? 'This field is required' : null;

    return Scaffold(
      appBar: AppBar(
        leading: EntryMotion(
          from: const Offset(-.4, 0),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: CircleBtn(Icons.arrow_back_rounded,
                size: 40, onTap: () => Navigator.pop(context)),
          ),
        ),
        title: const AnimatedTitle('Checkout'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            _steps(),
            const SizedBox(height: 22),
            _label('01', 'Where should we deliver?'),
            _field(_name, 'Full name', Icons.person_outline_rounded, req),
            _field(_phone, 'Phone number', Icons.phone_outlined, req,
                type: TextInputType.phone, ltr: true),
            _field(_address, 'Address: city, district, street',
                Icons.location_on_outlined, req,
                lines: 2),
            _field(_notes, 'Notes for the courier (optional)',
                Icons.sticky_note_2_outlined, null),
            const SizedBox(height: 14),
            _label('02', 'Payment method'),
            Row(children: [
              _payOption('cash', 'Cash on delivery', Icons.payments_outlined),
              const SizedBox(width: 12),
              _payOption('card_demo', 'Card (demo)', Icons.credit_card_rounded),
            ]),
            const SizedBox(height: 24),
            _label('03', 'Order summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(children: [
                SizedBox(
                  height: 62,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 62,
                        decoration: BoxDecoration(
                          color: AppColors.tint(i),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: NetImage(cart.items[i].image),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('×${cart.items[i].quantity}',
                              style: AppTheme.font(
                                  size: 10, color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                ),
                const Divider(height: 26, color: AppColors.line),
                _sum('Subtotal', money(cart.subtotal, currency: app.currency)),
                if (cart.discount > 0)
                  _sum('Discount', '- ${money(cart.discount, currency: app.currency)}'),
                _sum('Delivery',
                    cart.deliveryFee == 0 ? 'Free' : money(cart.deliveryFee, currency: app.currency)),
                const SizedBox(height: 6),
                _sum('Total', money(cart.total, currency: app.currency), big: true),
              ]),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Place order',
              icon: Icons.check_rounded,
              style: AppButtonStyle.ember,
              loading: _loading,
              onTap: cart.items.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _steps() {
    Widget dot(IconData i, String t, bool done, bool active) => Column(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active ? AppColors.ember : (done ? AppColors.ink : AppColors.sand),
              shape: BoxShape.circle,
            ),
            child: Icon(i,
                size: 19,
                color: done || active ? Colors.white : AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(t, style: AppTheme.font(size: 11.5, weight: FontWeight.w600)),
        ]);
    Widget line(bool on) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 22),
            color: on ? AppColors.ink : AppColors.sand2,
          ),
        );
    return Row(children: [
      dot(Icons.shopping_bag_outlined, 'Bag', true, false),
      line(true),
      dot(Icons.local_shipping_outlined, 'Delivery', false, true),
      line(false),
      dot(Icons.check_rounded, 'Done', false, false),
    ]);
  }

  Widget _label(String n, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Text(n,
              style: AppTheme.font(
                  size: 13, weight: FontWeight.w700, color: AppColors.ember)),
          const SizedBox(width: 8),
          Text(t, style: AppTheme.font(size: 17, weight: FontWeight.w700)),
        ]),
      );

  Widget _field(TextEditingController c, String hint, IconData icon,
          String? Function(String?)? validator,
          {TextInputType? type, int lines = 1, bool ltr = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          validator: validator,
          keyboardType: type,
          maxLines: lines,
          textDirection: ltr ? TextDirection.ltr : null,
          style: AppTheme.font(),
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        ),
      );

  Widget _payOption(String v, String label, IconData icon) {
    final on = _payment == v;
    return Expanded(
      child: Pressable(
        onTap: () => setState(() => _payment = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 104,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: on ? AppColors.ember : AppColors.text),
                const Spacer(),
                Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 20, color: on ? AppColors.ember : AppColors.sand2),
              ]),
              const Spacer(),
              Text(label,
                  style: AppTheme.font(
                      weight: FontWeight.w600,
                      color: on ? Colors.white : AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sum(String l, String v, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
            child: Text(l,
                style: AppTheme.font(
                    color: big ? AppColors.text : AppColors.muted,
                    weight: big ? FontWeight.w700 : FontWeight.w400)),
          ),
          Text(v,
              style: AppTheme.font(
                  size: big ? 20 : 14,
                  weight: FontWeight.w700,
                  color: big ? AppColors.ember : AppColors.text)),
        ]),
      );
}

class _SuccessDialog extends StatelessWidget {
  final String number;
  const _SuccessDialog({required this.number});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (_, v, c) => Transform.scale(scale: v, child: c),
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                    color: AppColors.emberSoft, shape: BoxShape.circle),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                    color: AppColors.ember, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Your order is on its way!',
              style: AppTheme.font(size: 22, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Order #$number\nWe\'ll contact you to confirm delivery.',
              textAlign: TextAlign.center,
              style: AppTheme.font(color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 22),
          AppButton(
              label: 'Track order',
              icon: Icons.arrow_forward_rounded,
              onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}
