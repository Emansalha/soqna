import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'motion.dart';

/// One tab of the bottom bar. [index] is the page index in MainShell.
class NavTab {
  final int index;
  final IconData icon, activeIcon;
  final String label;
  const NavTab(this.index, this.icon, this.activeIcon, this.label);
}

/// Floating "notched" bottom app bar:
/// - dark ink capsule with a curved notch cut out for a raised ember cart button
/// - a bone circle (ember ring + dot) that springs from tab to tab
/// - circular ripple on press; icons morph outline → filled and pop
/// - the cart button breathes softly and its badge pops when the count changes
/// - the whole bar slides away while scrolling down and returns on scroll up
class SneakerBottomBar extends StatelessWidget {
  final int index;
  final int cartCount;
  final bool visible;
  final ValueChanged<int> onTap;

  const SneakerBottomBar({
    super.key,
    required this.index,
    required this.cartCount,
    required this.onTap,
    this.visible = true,
  });

  static const cartIndex = 3;
  static const _left = [
    NavTab(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
    NavTab(1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Shop'),
  ];
  static const _right = [
    NavTab(2, Icons.favorite_border_rounded, Icons.favorite_rounded, 'Wishlist'),
    NavTab(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  static const _barHeight = 70.0;
  static const _fab = 62.0;
  static const _notchR = 39.0;
  static const _centerGap = 86.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(bottom, 12)),
        child: SizedBox(
          height: _barHeight + _fab / 2,
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final slotW = (w - _centerGap) / 4;
            final tabs = [..._left, ..._right];
            double slotX(int slot) =>
                slot < 2 ? slot * slotW : _centerGap + slot * slotW;
            final activeSlot = tabs.indexWhere((t) => t.index == index);
            const dot = 48.0; // active circle diameter

            return Stack(clipBehavior: Clip.none, children: [
              // ── Notched ink capsule ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: CustomPaint(
                  painter: _NotchedBarPainter(notchRadius: _notchR),
                ),
              ),
              // ── Sliding bone circle (springs between tabs) ──
              AnimatedPositioned(
                duration: const Duration(milliseconds: 520),
                curve: Curves.elasticOut,
                left: activeSlot < 0
                    ? w / 2 - dot / 2
                    : slotX(activeSlot) + (slotW - dot) / 2,
                bottom: (_barHeight - dot) / 2 + 3,
                width: dot,
                height: dot,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: activeSlot < 0 ? 0 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bone,
                      border: Border.all(
                          color: AppColors.ember.withValues(alpha: .55),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ember.withValues(alpha: .35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Small ember dot that follows the circle ──
              AnimatedPositioned(
                duration: const Duration(milliseconds: 620),
                curve: Curves.elasticOut,
                left: activeSlot < 0
                    ? w / 2 - 2.5
                    : slotX(activeSlot) + slotW / 2 - 2.5,
                bottom: 5,
                width: 5,
                height: 5,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: activeSlot < 0 ? 0 : 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                        color: AppColors.ember, shape: BoxShape.circle),
                  ),
                ),
              ),
              // ── Side tabs ──
              for (int s = 0; s < tabs.length; s++)
                Positioned(
                  left: slotX(s),
                  width: slotW,
                  bottom: 0,
                  height: _barHeight,
                  child: _TabButton(
                    tab: tabs[s],
                    active: tabs[s].index == index,
                    onTap: () => onTap(tabs[s].index),
                  ),
                ),
              // ── Raised ember cart button in the notch ──
              Positioned(
                left: w / 2 - _fab / 2,
                top: 0,
                width: _fab,
                height: _fab,
                child: _CartFab(
                  active: index == cartIndex,
                  count: cartCount,
                  onTap: () => onTap(cartIndex),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final NavTab tab;
  final bool active;
  final VoidCallback onTap;
  const _TabButton(
      {required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: active,
        label: tab.label,
        child: Tooltip(
          message: tab.label,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              // Circular touch feedback (no square highlight)
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkResponse(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  highlightShape: BoxShape.circle,
                  radius: 26,
                  splashColor: AppColors.ember.withValues(alpha: .28),
                  highlightColor: Colors.white.withValues(alpha: .06),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: PopOnChange(
                        value: active ? 'on${tab.index}' : 'off${tab.index}',
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(
                            active ? tab.activeIcon : tab.icon,
                            key: ValueKey(active),
                            size: 23,
                            color: active ? AppColors.ink : Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Ember cart button: soft breathing glow, rotating ring when active,
/// badge that pops on every change.
class _CartFab extends StatefulWidget {
  final bool active;
  final int count;
  final VoidCallback onTap;
  const _CartFab(
      {required this.active, required this.count, required this.onTap});

  @override
  State<_CartFab> createState() => _CartFabState();
}

class _CartFabState extends State<_CartFab> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  bool _down = false;

  @override
  void dispose() {
    _breath.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.active,
      label: 'Bag',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .9 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedBuilder(
            animation: _breath,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_breath.value);
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ember.withValues(alpha: .28 + .22 * t),
                      blurRadius: 14 + 10 * t,
                      spreadRadius: 1 + 2 * t,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Stack(clipBehavior: Clip.none, children: [
              // rotating ring when the bag tab is active
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: widget.active ? 1 : 0,
                  child: RotationTransition(
                    turns: _spin,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(colors: [
                          Colors.white,
                          Color(0x00FFFFFF),
                          AppColors.ember,
                          Colors.white,
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.emberGradient,
                    ),
                    child: Icon(
                      widget.active
                          ? Icons.shopping_bag_rounded
                          : Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              if (widget.count > 0)
                Positioned(
                  top: -2,
                  right: -4,
                  child: PopOnChange(
                    value: widget.count,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 21, minHeight: 21),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bone, width: 2),
                      ),
                      child: Text('${widget.count}',
                          style: AppTheme.font(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Ink capsule with a smooth circular notch at the top centre.
class _NotchedBarPainter extends CustomPainter {
  final double notchRadius;
  _NotchedBarPainter({required this.notchRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final bar = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(math.min(r, 32))));
    final notch = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, 0),
          radius: notchRadius));
    final shape = Path.combine(PathOperation.difference, bar, notch);

    canvas.drawShadow(shape, AppColors.ink.withValues(alpha: .55), 14, false);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.ink3, AppColors.ink],
        ).createShader(Offset.zero & size),
    );
    // hairline highlight along the top edge
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .07),
    );
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) => old.notchRadius != notchRadius;
}
