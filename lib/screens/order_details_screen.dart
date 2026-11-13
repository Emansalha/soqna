import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

const _flow = ['pending', 'confirmed', 'preparing', 'shipped', 'delivered'];
const _icons = {
  'pending': Icons.hourglass_top_rounded,
  'confirmed': Icons.verified_outlined,
  'preparing': Icons.inventory_2_outlined,
  'shipped': Icons.local_shipping_outlined,
  'delivered': Icons.home_rounded,
};

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});
  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _o;
  String? _error;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await ApiClient.instance.order(widget.orderId);
      setState(() => _o = Order.fromJson(r.data));
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _cancel() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Cancel this order?',
            style: AppTheme.font(size: 18, weight: FontWeight.w700)),
        content: Text('This action can\'t be undone.',
            style: AppTheme.font(color: AppColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Back', style: AppTheme.font())),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('Yes, cancel',
                  style: AppTheme.font(
                      color: AppColors.danger, weight: FontWeight.w700))),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _cancelling = true);
    try {
      await ApiClient.instance.cancelOrder(widget.orderId);
      if (mounted) showMsg(context, 'Order cancelled');
      await _load();
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  List<TimelineStep> _steps(Order o) {
    if (o.timeline.isNotEmpty) {
      return o.timeline.where((s) => !s.status.startsWith('cancel')).toList();
    }
    final idx = _flow.indexOf(o.status);
    return [
      for (int i = 0; i < _flow.length; i++)
        TimelineStep(_flow[i], orderStatusLabels[_flow[i]]!, '', i <= idx)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (_error != null) {
      return Scaffold(
          appBar: AppBar(), body: ErrorView(_error!, onRetry: _load));
    }
    if (_o == null) return const Scaffold(body: Loader());
    final o = _o!;
    final cancelled = o.status.startsWith('cancel');
    final cur = app.currency;
    final steps = _steps(o);
    final doneCount = steps.where((s) => s.done).length;

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
        title: AnimatedTitle('Order #${o.number}'),
      ),
      body: RefreshIndicator(
        color: AppColors.ember,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cancelled ? AppColors.danger : AppColors.ink,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cancelled
                            ? Colors.white24
                            : AppColors.ember,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          cancelled
                              ? Icons.close_rounded
                              : (_icons[o.status] ?? Icons.receipt_long),
                          color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current status',
                              style: AppTheme.font(
                                  size: 12, color: Colors.white60)),
                          Text(o.statusLabel,
                              style: AppTheme.font(
                                  size: 21,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ]),
                  if (!cancelled) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0,
                            end: steps.isEmpty ? 0 : doneCount / steps.length),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          color: AppColors.ember,
                          backgroundColor: AppColors.ink3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Step $doneCount of ${steps.length}',
                        style:
                            AppTheme.font(size: 12, color: Colors.white60)),
                  ],
                ],
              ),
            ),
            if (!cancelled) ...[
              const SizedBox(height: 22),
              Text('Order journey',
                  style: AppTheme.font(size: 17, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(children: _timeline(steps)),
              ),
            ],
            const SizedBox(height: 22),
            Text('Sneakers', style: AppTheme.font(size: 17, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (int i = 0; i < o.items.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.tint(i),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: NetImage(o.items[i].image),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.items[i].name,
                            style: AppTheme.font(weight: FontWeight.w600)),
                        Text(
                            '× ${o.items[i].quantity}${o.items[i].options['size'] != null ? '  ·  Size ${o.items[i].options['size']}' : ''}',
                            style: AppTheme.font(
                                size: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text(money(o.items[i].lineTotal, currency: cur),
                      style: AppTheme.font(weight: FontWeight.w700)),
                ]),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(children: [
                if (o.address.isNotEmpty)
                  _info(Icons.location_on_outlined, o.address),
                if (o.paymentMethod.isNotEmpty)
                  _info(
                      Icons.payments_outlined,
                      o.paymentMethod == 'cash'
                          ? 'Cash on delivery'
                          : o.paymentMethod == 'card_demo'
                              ? 'Card (demo)'
                              : o.paymentMethod),
                const Divider(color: AppColors.line, height: 20),
                _sum('Subtotal', money(o.subtotal, currency: cur)),
                if (o.discount > 0)
                  _sum('Discount', '- ${money(o.discount, currency: cur)}'),
                _sum('Delivery',
                    o.deliveryFee == 0 ? 'Free' : money(o.deliveryFee, currency: cur)),
                _sum('Total', money(o.total, currency: cur), bold: true),
              ]),
            ),
            if (o.canCancel && !cancelled) ...[
              const SizedBox(height: 20),
              Pressable(
                onTap: _cancelling ? null : _cancel,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Text(_cancelling ? 'Cancelling...' : 'Cancel order',
                      style: AppTheme.font(
                          weight: FontWeight.w600, color: AppColors.danger)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _timeline(List<TimelineStep> steps) {
    final current = steps.lastIndexWhere((s) => s.done);
    return [
      for (int i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: i == current
                      ? AppColors.ember
                      : (steps[i].done ? AppColors.ink : AppColors.bone),
                  shape: BoxShape.circle,
                  boxShadow: i == current
                      ? [
                          BoxShadow(
                            color: AppColors.ember.withValues(alpha: .35),
                            blurRadius: 12,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  steps[i].done
                      ? (_icons[steps[i].status] ?? Icons.check_rounded)
                      : (_icons[steps[i].status] ?? Icons.circle_outlined),
                  size: 18,
                  color: steps[i].done ? Colors.white : AppColors.muted,
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: steps[i + 1].done ? AppColors.ink : AppColors.sand2,
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(steps[i].label,
                        style: AppTheme.font(
                            weight: FontWeight.w600,
                            color: steps[i].done
                                ? AppColors.text
                                : AppColors.muted)),
                    if (steps[i].at.isNotEmpty)
                      Text(steps[i].at,
                          style: AppTheme.font(
                              size: 12, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ]),
        ),
    ];
  }

  Widget _info(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: AppColors.bone, shape: BoxShape.circle),
            child: Icon(i, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: AppTheme.font())),
        ]),
      );

  Widget _sum(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
              child: Text(l,
                  style: AppTheme.font(
                      color: bold ? AppColors.text : AppColors.muted,
                      weight: bold ? FontWeight.w700 : FontWeight.w400))),
          Text(v,
              style: AppTheme.font(
                  size: bold ? 19 : 14,
                  weight: FontWeight.w700,
                  color: bold ? AppColors.ember : AppColors.text)),
        ]),
      );
}
