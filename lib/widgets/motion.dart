import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Fades + slides a widget in once, after an optional [delay].
/// Used for app bar titles and header rows.
class EntryMotion extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset from;
  const EntryMotion({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
    this.from = const Offset(0, -.35),
  });

  @override
  State<EntryMotion> createState() => _EntryMotionState();
}

class _EntryMotionState extends State<EntryMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
  CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t,
    child: SlideTransition(
      position: Tween(begin: widget.from, end: Offset.zero).animate(_t),
      child: widget.child,
    ),
  );
}

/// App bar title that drops in softly and shows a small ember underline
/// that grows from the start edge.
class AnimatedTitle extends StatelessWidget {
  final String text;
  const AnimatedTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => EntryMotion(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(text),
      const SizedBox(height: 3),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutBack,
        builder: (_, v, __) => Container(
          width: 22 * v.clamp(0.0, 1.2).toDouble(),
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.ember,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    ]),
  );
}

/// Logo avatar with a slowly rotating ember gradient ring.
class SpinningRing extends StatefulWidget {
  final Widget child;
  final double size;
  const SpinningRing({super.key, required this.child, this.size = 46});

  @override
  State<SpinningRing> createState() => _SpinningRingState();
}

class _SpinningRingState extends State<SpinningRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size + 6,
    height: widget.size + 6,
    child: Stack(alignment: Alignment.center, children: [
      RotationTransition(
        turns: _c,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [
              AppColors.ember,
              Color(0x00FF5A1F),
              AppColors.ink,
              AppColors.ember,
            ]),
          ),
        ),
      ),
      Container(
        width: widget.size + 1,
        height: widget.size + 1,
        decoration: const BoxDecoration(
            color: AppColors.bone, shape: BoxShape.circle),
      ),
      SizedBox(
          width: widget.size - 3,
          height: widget.size - 3,
          child: widget.child),
    ]),
  );
}

/// Scale "pop" every time [value] changes (e.g. cart badge count).
class PopOnChange extends StatelessWidget {
  final Object value;
  final Widget child;
  const PopOnChange({super.key, required this.value, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(value),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 520),
    builder: (_, t, c) {
      // 1 → 1.35 → 1 with a little overshoot
      final s = 1 + .35 * math.sin(t * math.pi) * (1 - t * .4);
      return Transform.scale(scale: s, child: c);
    },
    child: child,
  );
}

/// Compact frosted bar that slides down once the page is scrolled past
/// [showAfter] pixels. Wrap it in a [ValueListenableBuilder] on the offset.
class CollapsingTopBar extends StatelessWidget {
  final double offset;
  final double showAfter;
  final Widget child;
  const CollapsingTopBar({
    super.key,
    required this.offset,
    required this.child,
    this.showAfter = 150,
  });

  @override
  Widget build(BuildContext context) {
    final double t = ((offset - showAfter) / 60).clamp(0.0, 1.0).toDouble();
    final top = MediaQuery.of(context).padding.top;
    return IgnorePointer(
      ignoring: t < .5,
      child: Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -18 * (1 - t)),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, top + 8, 20, 10),
                decoration: BoxDecoration(
                  color: AppColors.bone.withValues(alpha: .82),
                  border: Border(
                    bottom: BorderSide(
                        color: AppColors.line.withValues(alpha: t)),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}