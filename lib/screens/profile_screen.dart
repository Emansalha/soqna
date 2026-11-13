import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'orders_screen.dart';
import 'store_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = app.customer;
    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Membership card
          Container(
            margin: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 16, 16, 0),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(32),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                right: -40,
                bottom: -70,
                child: Icon(Icons.directions_run_rounded,
                    size: 190, color: Colors.white.withValues(alpha: .05)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                          color: AppColors.ember, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        c != null && c.name.isNotEmpty
                            ? c.name.characters.first
                            : '?',
                        style: AppTheme.font(
                            size: 26,
                            weight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c?.name ?? 'Guest',
                              style: AppTheme.font(
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(c?.email ?? 'Sign in for the full experience',
                              style: AppTheme.font(
                                  size: 13, color: Colors.white60)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Text('MEMBER · ${app.store?.name ?? ''}'.toUpperCase(),
                      style: AppTheme.font(
                          size: 10.5, color: AppColors.ember, spacing: 2.5)),
                ],
              ),
            ]),
          ),
          if (app.loggedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                _stat(context, Icons.shopping_bag_outlined, '${app.cart.count}',
                    'In bag', () => app.setTab(3)),
                const SizedBox(width: 10),
                _stat(context, Icons.favorite_border_rounded,
                    '${app.favoriteIds.length}', 'Saved', () => app.setTab(2)),
                const SizedBox(width: 10),
                _stat(context, Icons.receipt_long_outlined, '↗', 'My orders',
                    () => _push(context, const OrdersScreen())),
              ]),
            ),
          const SizedBox(height: 18),
          if (!app.loggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton(
                label: 'Sign in / Sign up',
                icon: Icons.arrow_forward_rounded,
                style: AppButtonStyle.ember,
                onTap: () => _push(context, const AuthScreen()),
              ),
            ),
          const SizedBox(height: 8),
          _group([
            if (app.loggedIn) ...[
              _tile(Icons.receipt_long_outlined, 'My orders & tracking',
                  () => _push(context, const OrdersScreen())),
              _tile(Icons.edit_outlined, 'Edit profile',
                  () => _editProfile(context)),
            ],
            _tile(Icons.storefront_outlined, 'About the store',
                () => _push(context, const StoreInfoScreen())),
            _tile(Icons.support_agent_outlined, 'Contact us',
                () => _push(context, const StoreInfoScreen())),
          ]),
          if (app.loggedIn)
            _group([
              _tile(Icons.logout_rounded, 'Sign out', () async {
                await app.logout();
                if (context.mounted) showMsg(context, 'Signed out');
              }, danger: true),
            ]),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData i, String v, String l,
          VoidCallback onTap) =>
      Expanded(
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              Icon(i, size: 20, color: AppColors.muted),
              const SizedBox(height: 4),
              Text(v, style: AppTheme.font(size: 20, weight: FontWeight.w700)),
              Text(l, style: AppTheme.font(size: 11.5, color: AppColors.muted)),
            ]),
          ),
        ),
      );

  Widget _group(List<Widget> tiles) => Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 66, color: AppColors.line),
            tiles[i],
          ],
        ]),
      );

  Widget _tile(IconData i, String t, VoidCallback onTap,
          {bool danger = false}) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger
                    ? AppColors.danger.withValues(alpha: .1)
                    : AppColors.bone,
                shape: BoxShape.circle,
              ),
              child: Icon(i,
                  size: 20, color: danger ? AppColors.danger : AppColors.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(t,
                  style: AppTheme.font(
                      weight: FontWeight.w500,
                      color: danger ? AppColors.danger : AppColors.text)),
            ),
            if (!danger)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.muted),
          ]),
        ),
      );

  Future<void> _editProfile(BuildContext context) async {
    final app = context.read<AppState>();
    final name = TextEditingController(text: app.customer?.name);
    final phone = TextEditingController(text: app.customer?.phone);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            22, 0, 22, MediaQuery.of(ctx).viewInsets.bottom + 26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetTitle('Edit profile'),
          TextField(
              controller: name,
              style: AppTheme.font(),
              decoration: const InputDecoration(
                  hintText: 'Name',
                  prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 12),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              style: AppTheme.font(),
              decoration: const InputDecoration(
                  hintText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 20),
          AppButton(label: 'Save', onTap: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (ok != true) return;
    try {
      await app.updateProfile(name.text.trim(), phone.text.trim());
      if (context.mounted) showMsg(context, 'Changes saved');
    } catch (e) {
      if (context.mounted) showMsg(context, '$e', error: true);
    }
  }
}
