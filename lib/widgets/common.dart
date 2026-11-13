import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../screens/auth_screen.dart';
import 'motion.dart';

/// Network image with a soft sand placeholder while loading
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width, height;
  final BorderRadius? radius;
  final Alignment alignment;
  const NetImage(this.url,
      {super.key,
      this.fit = BoxFit.cover,
      this.width,
      this.height,
      this.radius,
      this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.sand,
      alignment: Alignment.center,
      child: const Icon(Icons.directions_walk_rounded,
          color: AppColors.sand2, size: 34),
    );
    final img = url.isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            width: width,
            height: height,
            alignment: alignment,
            // On web, draw with an <img> tag: the store's /uploads images
            // don't send CORS headers, so the default web renderer can't
            // load them. (No effect on Android / iOS.)
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
            fadeInDuration: const Duration(milliseconds: 350),
            placeholder: (_, __) =>
                Container(width: width, height: height, color: AppColors.sand),
            errorWidget: (_, __, ___) => placeholder,
          );
    return radius == null ? img : ClipRRect(borderRadius: radius!, child: img);
  }
}
/// Slightly shrinks on press — a tactile "real button" feel
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  const Pressable(
      {super.key,
      required this.child,
      this.onTap,
      this.onLongPress,
      this.scale = .96});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? kicker;
  final VoidCallback? onMore;
  const SectionHeader(this.title, {super.key, this.kicker, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kicker != null)
                Text(kicker!.toUpperCase(),
                    style: AppTheme.font(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.ember,
                        spacing: 1.6)),
              Text(title,
                  style: AppTheme.font(size: 21, weight: FontWeight.w700)),
            ],
          ),
        ),
        if (onMore != null)
          Pressable(
            onTap: onMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('All',
                    style: AppTheme.font(size: 12.5, weight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 15),
              ]),
            ),
          ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle = '',
      this.action,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                  color: AppColors.sand, shape: BoxShape.circle),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                  color: AppColors.ink, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            Positioned(
              top: 10,
              right: 14,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    color: AppColors.ember, shape: BoxShape.circle),
              ),
            ),
          ]),
          const SizedBox(height: 22),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTheme.font(size: 19, weight: FontWeight.w700)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.font(color: AppColors.muted, height: 1.6)),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            SizedBox(
                width: 230,
                child: AppButton(label: action!, onTap: onAction)),
          ],
        ]),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView(this.message, {super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Oops, something slipped',
        subtitle: message,
        action: 'Try again',
        onAction: onRetry,
      );
}

class Loader extends StatelessWidget {
  const Loader({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
              color: AppColors.ember, strokeWidth: 2.6),
        ),
      );
}

/// "Sign in" gate for protected pages
class LoginRequired extends StatelessWidget {
  final String title;
  const LoginRequired({super.key, this.title = 'Sign in first'});
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.lock_outline_rounded,
        title: title,
        subtitle: 'Create an account in seconds to save your bag and wishlist',
        action: 'Sign in',
        onAction: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AuthScreen())),
      );
}

/// Ensures the user is signed in before an action
Future<bool> ensureLoggedIn(BuildContext context) async {
  if (context.read<AppState>().loggedIn) return true;
  await Navigator.push(
      context, MaterialPageRoute(builder: (_) => const AuthScreen()));
  return context.mounted && context.read<AppState>().loggedIn;
}

/// Pill-shaped quantity stepper
class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool compact, dark;
  const QtyStepper(
      {super.key,
      required this.value,
      required this.onChanged,
      this.compact = false,
      this.dark = false});

  @override
  Widget build(BuildContext context) {
    final s = compact ? 30.0 : 40.0;
    final fg = dark ? Colors.white : AppColors.text;
    Widget btn(IconData i, int v) => Pressable(
          onTap: () => onChanged(v),
          child: SizedBox(
              width: s, height: s, child: Icon(i, size: compact ? 16 : 19, color: fg)),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink3 : AppColors.surface,
        borderRadius: BorderRadius.circular(40),
        border: dark ? null : Border.all(color: AppColors.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove_rounded, value - 1),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: SizedBox(
            key: ValueKey(value),
            width: compact ? 22 : 28,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppTheme.font(
                    size: compact ? 14 : 16,
                    weight: FontWeight.w700,
                    color: fg)),
          ),
        ),
        btn(Icons.add_rounded, value + 1),
      ]),
    );
  }
}

enum AppButtonStyle { ink, ember, light }

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final AppButtonStyle style;
  final double height;
  const AppButton(
      {super.key,
      required this.label,
      this.icon,
      this.onTap,
      this.loading = false,
      this.style = AppButtonStyle.ink,
      this.height = 58});

  @override
  Widget build(BuildContext context) {
    final bg = switch (style) {
      AppButtonStyle.ink => AppColors.ink,
      AppButtonStyle.ember => AppColors.ember,
      AppButtonStyle.light => Colors.white,
    };
    final fg = style == AppButtonStyle.light ? AppColors.ink : Colors.white;
    return Opacity(
      opacity: onTap == null ? .45 : 1,
      child: Pressable(
        onTap: loading ? null : onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              if (style != AppButtonStyle.light)
                BoxShadow(
                  color: bg.withValues(alpha: .28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: fg, strokeWidth: 2.4))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(label,
                        style: AppTheme.font(
                            size: 15.5, weight: FontWeight.w600, color: fg)),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: style == AppButtonStyle.ink
                              ? AppColors.ember
                              : fg.withValues(alpha: .15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            size: 16,
                            color: style == AppButtonStyle.light
                                ? AppColors.ink
                                : Colors.white),
                      ),
                    ],
                  ]),
          ),
        ),
      ),
    );
  }
}

class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color, bg;
  final double size;
  final int? badge;
  const CircleBtn(this.icon,
      {super.key,
      required this.onTap,
      this.color = AppColors.text,
      this.bg = AppColors.surface,
      this.size = 46,
      this.badge});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: size * .45, color: color),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: -2,
              right: -2,
              child: PopOnChange(
                value: badge!,
                child: Container(
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.ember,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.bone, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('$badge',
                    style: AppTheme.font(
                        size: 10, weight: FontWeight.w700, color: Colors.white)),
              ),
              ),
            ),
        ]),
      );
}

/// Price pill
class PriceTag extends StatelessWidget {
  final num price;
  final num? old;
  final String currency;
  final bool big, light;
  const PriceTag(
      {super.key,
      required this.price,
      this.old,
      required this.currency,
      this.big = false,
      this.light = false});

  @override
  Widget build(BuildContext context) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: [
          Text(money(price, currency: currency),
              style: AppTheme.font(
                  size: big ? 28 : 16,
                  weight: FontWeight.w700,
                  color: light ? Colors.white : AppColors.text)),
          if (old != null && old! > price)
            Padding(
              padding: EdgeInsets.only(bottom: big ? 5 : 1),
              child: Text(money(old!, currency: currency),
                  style: AppTheme.font(
                      size: big ? 14 : 11.5,
                      color: light ? Colors.white54 : AppColors.muted)
                      .copyWith(decoration: TextDecoration.lineThrough)),
            ),
        ],
      );
}

/// Bottom-sheet header with title
class SheetTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SheetTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: AppTheme.font(size: 20, weight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}
