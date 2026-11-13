import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/sneaker_images.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// "More than a store" + contact us
class StoreInfoScreen extends StatelessWidget {
  const StoreInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.store;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView('Couldn\'t load store details', onRetry: () => app.init()),
      );
    }
    final contacts = <(IconData, String, String)>[
      if (s.phone.isNotEmpty) (Icons.phone_rounded, s.phone, 'Phone'),
      if (s.whatsapp.isNotEmpty) (Icons.chat_rounded, s.whatsapp, 'WhatsApp'),
      if (s.email.isNotEmpty) (Icons.mail_outline_rounded, s.email, 'Email'),
      if (s.instagram.isNotEmpty)
        (Icons.camera_alt_outlined, s.instagram, 'Instagram'),
      if (s.facebook.isNotEmpty) (Icons.facebook_rounded, s.facebook, 'Facebook'),
    ];
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: h * .5,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(44)),
                  child: NetImage(s.cover.isNotEmpty && !SneakerImages.forceDemoPhotos
                      ? s.cover
                      : SneakerImages.hero(0)),
                ),
                const ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(44)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66111014), Color(0x22111014),
                          Color(0xEE111014)],
                        stops: [0, .4, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: CircleBtn(Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context)),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  left: 24,
                  bottom: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name.toUpperCase(),
                          style: AppTheme.font(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.ember,
                              spacing: 3)),
                      Text('More than\njust a store.',
                          style: AppTheme.font(
                              size: 36,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
            sliver: SliverList.list(children: [
              if (s.description.isNotEmpty)
                Text(s.description,
                    style: AppTheme.font(
                        color: AppColors.body, height: 1.8)),
              const SizedBox(height: 18),
              Row(children: [
                _feature(Icons.verified_outlined, '100%\nAuthentic'),
                _feature(
                    Icons.local_shipping_outlined,
                    s.deliveryFee == 0
                        ? 'Free\ndelivery'
                        : 'Delivery\n${money(s.deliveryFee, currency: s.currency)}'),
                _feature(Icons.payments_outlined, 'Cash on\ndelivery'),
                _feature(Icons.support_agent_outlined, 'Always-on\nsupport'),
              ]),
              if (contacts.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Contact us',
                    style: AppTheme.font(size: 20, weight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final c in contacts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Pressable(
                      scale: .98,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: c.$2));
                        showMsg(context, '${c.$3} copied');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                                color: AppColors.ink, shape: BoxShape.circle),
                            child: Icon(c.$1, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.$2,
                                    textDirection: TextDirection.ltr,
                                    style: AppTheme.font(
                                        weight: FontWeight.w600)),
                                Text(c.$3,
                                    style: AppTheme.font(
                                        size: 12, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.copy_rounded,
                              size: 18, color: AppColors.ember),
                        ]),
                      ),
                    ),
                  ),
              ],
              if (s.address.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Our location',
                    style: AppTheme.font(size: 20, weight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                          color: AppColors.ember, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.address,
                          style: AppTheme.font(
                              color: Colors.white, height: 1.5)),
                    ),
                  ]),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData i, String t) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Icon(i, color: AppColors.ember),
            const SizedBox(height: 6),
            Text(t,
                textAlign: TextAlign.center,
                style: AppTheme.font(
                    size: 11, weight: FontWeight.w600, height: 1.35)),
          ]),
        ),
      );
}
