import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/firebase_auth_service.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// "Check your inbox" screen shown after sign up, or when signing in
/// with an email that is not verified yet. It checks Firebase every few
/// seconds and signs the user in automatically once the link is clicked.
class VerifyEmailScreen extends StatefulWidget {
  final String email, password;
  const VerifyEmailScreen(
      {super.key, required this.email, required this.password});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);
  Timer? _poll, _cooldownTimer;
  int _cooldown = 30;
  bool _checking = false, _done = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _cooldownTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _check({bool manual = false}) async {
    if (_checking || _done) return;
    _checking = true;
    if (manual) setState(() {});
    try {
      final ok = await FirebaseGate.instance.isVerified();
      if (!ok) {
        if (manual && mounted) {
          showMsg(context, 'Not verified yet — tap the link in the email',
              error: true);
        }
        return;
      }
      _done = true;
      _poll?.cancel();
      if (!mounted) return;
      await context.read<AppState>().login(widget.email, widget.password);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showMsg(context, 'Email verified — welcome! 🎉');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      _done = false;
      if (manual && mounted) showMsg(context, '$e', error: true);
    } finally {
      _checking = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _resend() async {
    try {
      await FirebaseGate.instance.resendVerification();
      if (!mounted) return;
      showMsg(context, 'Verification email sent again 📩');
      _startCooldown();
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleBtn(Icons.arrow_back_rounded,
                  bg: Colors.white24,
                  color: Colors.white,
                  onTap: () => Navigator.pop(context)),
              const Spacer(),
              Center(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) {
                    final t = Curves.easeInOut.transform(_pulse.value);
                    return Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.emberGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ember
                                .withValues(alpha: .25 + .25 * t),
                            blurRadius: 30 + 20 * t,
                            spreadRadius: 4 + 8 * t,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: const Icon(Icons.mark_email_unread_rounded,
                      size: 58, color: Colors.white),
                ),
              ),
              const SizedBox(height: 36),
              EntryMotion(
                from: const Offset(0, .3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ONE LAST STEP',
                        style: AppTheme.font(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.ember,
                            spacing: 3)),
                    const SizedBox(height: 6),
                    Text('Verify your email',
                        style: AppTheme.font(
                            size: 30,
                            weight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'We sent a verification link to\n'),
                        TextSpan(
                            text: widget.email,
                            style: AppTheme.font(
                                weight: FontWeight.w700,
                                color: AppColors.ember)),
                        const TextSpan(
                            text:
                                '\nOpen it, tap the link, and you\'ll be signed in automatically.'),
                      ]),
                      style: AppTheme.font(
                          size: 14, color: Colors.white70, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.ember),
                ),
                const SizedBox(width: 10),
                Text('Waiting for verification…',
                    style: AppTheme.font(size: 12.5, color: Colors.white54)),
              ]),
              const Spacer(),
              AppButton(
                label: 'I\'ve verified my email',
                icon: Icons.verified_rounded,
                loading: _checking,
                style: AppButtonStyle.light,
                onTap: () => _check(manual: true),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _cooldown > 0 ? null : _resend,
                  child: Text(
                    _cooldown > 0
                        ? 'Resend email in ${_cooldown}s'
                        : 'Resend verification email',
                    style: AppTheme.font(
                        weight: FontWeight.w600,
                        color:
                            _cooldown > 0 ? Colors.white38 : Colors.white),
                  ),
                ),
              ),
              Center(
                child: Text('Can\'t find it? Check your Spam folder.',
                    style: AppTheme.font(size: 12, color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
