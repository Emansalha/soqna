import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'order_details_screen.dart';

Color statusColor(String s) => switch (s) {
      'pending' => AppColors.gold,
      'confirmed' => AppColors.slate,
      'preparing' => AppColors.amber,
      'shipped' => AppColors.ember,
      'delivered' => AppColors.success,
      'cancelled' || 'canceled' => AppColors.danger,
      _ => AppColors.muted,
    };

const _flow = ['pending', 'confirmed', 'preparing', 'shipped', 'delivered'];

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _f = _load();

  Future<List<Order>> _load() async =>
      asList((await ApiClient.instance.orders()).data)
          .map(Order.fromJson)
          .toList();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
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
        title: const AnimatedTitle('My orders'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _f,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) return const Loader();
          if (s.hasError) {
            return ErrorView('${s.error}',
                onRetry: () => setState(() => _f = _load()));
          }
          final list = s.data!;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your orders and tracking will show up here',
            );
          }
          return RefreshIndicator(
            color: AppColors.ember,
            onRefresh: () async {
              setState(() => _f = _load());
              await _f;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _card(app, list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _card(AppState app, Order o) {
    final c = statusColor(o.status);
    final step = _flow.indexOf(o.status);
    final cancelled = o.status.startsWith('cancel');
    return Pressable(
      scale: .98,
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: o.id)));
        setState(() => _f = _load());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(children: [
          Row(children: [
            // Stacked product thumbnails
            SizedBox(
              width: 74,
              height: 52,
              child: Stack(children: [
                for (int k = 0; k < o.items.length && k < 3; k++)
                  Positioned(
                    left: k * 14.0,
                    child: Container(
                      width: 46,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.tint(k),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NetImage(o.items[k].image),
                    ),
                  ),
                if (o.items.isEmpty)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.bone,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${o.number}',
                      style: AppTheme.font(weight: FontWeight.w700)),
                  if (o.date.isNotEmpty)
                    Text(o.date,
                        style:
                            AppTheme.font(size: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Text(money(o.total, currency: app.currency),
                style: AppTheme.font(size: 16, weight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(o.statusLabel,
                  style: AppTheme.font(
                      size: 12, weight: FontWeight.w700, color: c)),
            ),
            const SizedBox(width: 12),
            // Mini progress bar
            if (!cancelled)
              Expanded(
                child: Row(
                  children: List.generate(_flow.length, (k) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: k <= step ? AppColors.ink : AppColors.sand,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ]),
        ]),
      ),
    );
  }
}
