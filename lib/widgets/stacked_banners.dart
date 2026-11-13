import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'common.dart';

/// Banner stack: 3 cards layered so the back two peek out.
/// Tap or swipe: the front card slides away and the next moves up.
/// "Shop now" or long-press opens the banner target.
class StackedBanners extends StatefulWidget {
  final List<BannerItem> banners;
  final void Function(BannerItem)? onOpen;
  final double height;
  final Duration autoPlay;

  const StackedBanners({
    super.key,
    required this.banners,
    this.onOpen,
    this.height = 200,
    this.autoPlay = const Duration(seconds: 5),
  });

  @override
  State<StackedBanners> createState() => _StackedBannersState();
}

class _StackedBannersState extends State<StackedBanners>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _index = (_index + 1) % widget.banners.length);
        _c.value = 0;
      }
    });

  int _index = 0;
  Timer? _timer;
  static const _peek = 13.0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(widget.autoPlay, (_) => _next(auto: true));
    }
  }

  void _next({bool auto = false}) {
    if (widget.banners.length < 2 || _c.isAnimating) return;
    if (!auto) {
      HapticFeedback.lightImpact();
      _restartTimer();
    }
    _c.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.banners.length;
    if (n == 0) return const SizedBox.shrink();
    final visible = math.min(3, n);
    final maxDepth = (visible - 1).toDouble();

    return Column(children: [
      SizedBox(
        height: widget.height + _peek * maxDepth,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_c.value);
            final count = n > 3 && _c.value > 0 ? 4 : visible;
            final cards = <Widget>[];
            for (int depth = count - 1; depth >= 0; depth--) {
              final bi = (_index + depth) % n;
              final double d =
                  depth == 0 ? 0.0 : (depth - t).clamp(0.0, maxDepth).toDouble();
              cards.add(_positioned(
                banner: widget.banners[bi],
                number: bi + 1,
                total: n,
                depth: d,
                maxDepth: maxDepth,
                isFront: depth == 0,
                exit: depth == 0 ? t : 0.0,
                fadeIn: depth == 3 ? t : 1.0,
              ));
            }
            return Stack(clipBehavior: Clip.none, children: cards);
          },
        ),
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(n, (i) {
          final active = i == _index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.ink : AppColors.sand2,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    ]);
  }

  Widget _positioned({
    required BannerItem banner,
    required int number,
    required int total,
    required double depth,
    required double maxDepth,
    required bool isFront,
    required double exit,
    required double fadeIn,
  }) {
    final scale = 1 - depth * 0.055;
    final top = (maxDepth - depth) * _peek;
    final dy = exit * widget.height * .6;
    final rot = exit * 0.07;
    final double opacity =
        (isFront ? 1 - exit : fadeIn).clamp(0.0, 1.0).toDouble();

    return Positioned(
      top: top + dy,
      left: 20,
      right: 20,
      height: widget.height,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: -rot,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: isFront ? _next : null,
              onLongPress: isFront ? () => widget.onOpen?.call(banner) : null,
              onHorizontalDragEnd: isFront
                  ? (d) {
                      if ((d.primaryVelocity ?? 0).abs() > 150) _next();
                    }
                  : null,
              child: _BannerCard(
                banner: banner,
                number: number,
                total: total,
                depth: depth,
                onOpen: isFront ? () => widget.onOpen?.call(banner) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _tags = ['NEW DROP', 'CLASSICS', 'LIMITED', 'HOT SALE', 'TRENDING'];

/// Slow zoom & drift on the banner photo — subtle, looping motion
class _KenBurns extends StatefulWidget {
  final Widget child;
  const _KenBurns({required this.child});
  @override
  State<_KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<_KenBurns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 9))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 1.0 + .08 * t,
            alignment: Alignment(.6 - .3 * t, 0),
            child: child,
          );
        },
        child: widget.child,
      );
}

class _BannerCard extends StatelessWidget {
  final BannerItem banner;
  final int number, total;
  final double depth;
  final VoidCallback? onOpen;
  const _BannerCard({
    required this.banner,
    required this.number,
    required this.total,
    required this.depth,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    // Back cards darken progressively for depth
    final shade = (depth * .28).clamp(0.0, .6).toDouble();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: depth == 0 ? .28 : .08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        // Full-bleed photo, anchored to the trailing side, with a slow
        // "Ken Burns" zoom on the front card
        Positioned.fill(
          child: depth == 0
              ? _KenBurns(
                  child: NetImage(banner.image,
                      alignment: Alignment.centerRight))
              : NetImage(banner.image, alignment: Alignment.centerRight),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.ink, Color(0xB3111014), Color(0x00111014)],
              stops: [0, .42, .8],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.ember,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_tags[(number - 1) % _tags.length],
                      style: AppTheme.font(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          spacing: 1.2)),
                ),
                const Spacer(),
                Text(
                  '${number.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                  style: AppTheme.font(
                      size: 11, color: Colors.white60, spacing: 1),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: Text(
                  banner.title.isEmpty ? 'Your next step\nstarts here' : banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                      size: 22,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25),
                ),
              ),
              if (banner.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: 190,
                  child: Text(banner.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(size: 12, color: Colors.white70)),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: onOpen,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Shop now',
                        style: AppTheme.font(
                            size: 12.5, weight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: AppColors.ink, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (shade > 0)
          IgnorePointer(
            child: ColoredBox(color: AppColors.ink.withValues(alpha: shade)),
          ),
      ]),
    );
  }
}
