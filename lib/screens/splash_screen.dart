import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/sneaker_images.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

/// Splash, then three onboarding pages (shown once)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _intro = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final app = context.read<AppState>();
    // Precache images for a smooth first paint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final u in SneakerImages.lifestyle) {
        precacheImage(CachedNetworkImageProvider(u), context).ignore();
      }
    });
    await Future.wait([
      app.init(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool('intro_seen') ?? false) {
      _goHome();
    } else {
      setState(() => _intro = true);
    }
  }

  Future<void> _goHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => const MainShell(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _intro
          ? _Onboarding(key: const ValueKey('intro'), onDone: _goHome)
          : const _Brand(key: ValueKey('brand')),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppState>().store;
    final name = store?.name ?? 'Souqna';
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(children: [
        // Huge outlined word in the background
        Positioned.fill(
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text('SNEAKERS',
                  style: AppTheme.outline(
                      size: 120,
                      stroke: 1.2,
                      color: Colors.white.withValues(alpha: .07))),
            ),
          ),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutBack,
            builder: (_, v, c) => Opacity(
              opacity: v.clamp(0.0, 1.0).toDouble(),
              child: Transform.scale(scale: .8 + .2 * v, child: c),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.bone,
                  borderRadius: BorderRadius.circular(30),
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(12),
                child: store != null && store.logo.isNotEmpty
                    ? NetImage(store.logo, fit: BoxFit.contain)
                    : Center(
                        child: Text(name.characters.first,
                            style: AppTheme.font(
                                size: 44, weight: FontWeight.w800)),
                      ),
              ),
              const SizedBox(height: 22),
              Text(name,
                  style: AppTheme.font(
                      size: 28, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('STEP INTO STYLE',
                  style: AppTheme.font(
                      size: 11,
                      weight: FontWeight.w500,
                      color: AppColors.ember,
                      spacing: 4)),
            ]),
          ),
        ),
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.ember,
                  backgroundColor: AppColors.ink3,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Onboarding extends StatefulWidget {
  final VoidCallback onDone;
  const _Onboarding({super.key, required this.onDone});
  @override
  State<_Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<_Onboarding> {
  final _pc = PageController();
  double _page = 0;

  static final _pages = [
    (SneakerImages.life(0), 'STYLE', 'More than sneakers,\na lifestyle.',
        'Authentic brands and hand-picked designs for every step.'),
    (SneakerImages.life(1), 'COMFORT', 'All-day\ncomfort.',
        'Find your exact fit with our smart size guide.'),
    (SneakerImages.life(3), 'FAST', 'From our store\nto your door.',
        'Track your order live and pay on delivery.'),
  ];

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? 0));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = _page.round();
    final last = i == _pages.length - 1;
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.bone,
      body: Stack(children: [
        PageView.builder(
          controller: _pc,
          itemCount: _pages.length,
          itemBuilder: (_, idx) {
            final pg = _pages[idx];
            final delta = (idx - _page);
            return Column(children: [
              // Large image with parallax offset
              SizedBox(
                height: h * .6,
                child: Stack(fit: StackFit.expand, children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(44)),
                    child: Transform.translate(
                      offset: Offset(delta * 80, 0),
                      child: Transform.scale(
                          scale: 1.15, child: NetImage(pg.$1)),
                    ),
                  ),
                  const ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(44)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x66111014), Colors.transparent,
                            Color(0x99111014)],
                          stops: [0, .4, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(pg.$2,
                          maxLines: 1,
                          style: AppTheme.outline(
                              size: 86,
                              height: 1,
                              color: Colors.white.withValues(alpha: .85))),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 0),
                child: Opacity(
                  opacity: (1 - delta.abs()).clamp(0.0, 1.0).toDouble(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pg.$3,
                          style: AppTheme.font(
                              size: 32, weight: FontWeight.w700, height: 1.25)),
                      const SizedBox(height: 10),
                      Text(pg.$4,
                          style: AppTheme.font(
                              size: 15, color: AppColors.muted, height: 1.6)),
                    ],
                  ),
                ),
              ),
            ]);
          },
        ),
        SafeArea(
          child: Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Pressable(
                onTap: widget.onDone,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Text('Skip',
                      style: AppTheme.font(size: 12.5, color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          bottom: MediaQuery.of(context).padding.bottom + 26,
          child: Row(children: [
            Row(
              children: List.generate(_pages.length, (k) {
                final on = k == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  width: on ? 26 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: on ? AppColors.ember : AppColors.sand2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const Spacer(),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: AppButton(
                label: last ? 'Start shopping' : 'Next',
                icon: Icons.arrow_forward_rounded,
                onTap: last
                    ? widget.onDone
                    : () => _pc.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
