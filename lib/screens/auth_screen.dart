import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/firebase_auth_service.dart';
import '../core/sneaker_images.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'verify_email_screen.dart';

/// Sign in + sign up
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true, _loading = false, _obscure = true;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _loading = true);
    final app = context.read<AppState>();
    final email = _email.text.trim();
    try {
      if (_isLogin) {
        await app.login(email, _pass.text);
        if (!mounted) return;
        showMsg(context, 'Welcome back 👟');
        Navigator.pop(context);
      } else {
        await app.register({
          'name': _name.text.trim(),
          'email': email,
          'phone': _phone.text.trim(),
          'password': _pass.text,
          'password_confirmation': _pass2.text,
        });
        if (!mounted) return;
        showMsg(context, 'Account created — check your inbox 📩');
        _openVerify(email, replace: true);
      }
    } on EmailNotVerified {
      if (!mounted) return;
      showMsg(context, 'Please verify your email to continue', error: true);
      _openVerify(email);
    } catch (e) {
      if (mounted) showMsg(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openVerify(String email, {bool replace = false}) {
    final password = _pass.text; // capture now: this screen may be disposed
    final route = MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(email: email, password: password));
    replace
        ? Navigator.pushReplacement(context, route)
        : Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppState>().store;
    String? req(String? v) =>
        (v == null || v.trim().isEmpty) ? 'This field is required' : null;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(children: [
        // Top background image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: h * .42,
          child: Stack(fit: StackFit.expand, children: [
            NetImage(SneakerImages.hero(2)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55111014), AppColors.ink],
                ),
              ),
            ),
          ]),
        ),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircleBtn(Icons.arrow_back_rounded,
                      bg: Colors.white24,
                      color: Colors.white,
                      onTap: () => Navigator.pop(context)),
                ),
                SizedBox(height: h * .1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_isLogin),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isLogin ? 'WELCOME BACK' : 'JOIN THE CLUB',
                            style: AppTheme.font(
                                size: 11,
                                weight: FontWeight.w600,
                                color: AppColors.ember,
                                spacing: 3)),
                        Text(_isLogin ? 'Welcome back' : 'Create account',
                            style: AppTheme.font(
                                size: 32,
                                weight: FontWeight.w800,
                                color: Colors.white)),
                        Text('at ${store?.name ?? 'our store'}',
                            style: AppTheme.font(color: Colors.white60)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                  decoration: const BoxDecoration(
                    color: AppColors.bone,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  constraints: BoxConstraints(minHeight: h * .6),
                  child: Form(
                    key: _form,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      alignment: Alignment.topCenter,
                      child: Column(children: [
                        _segmented(),
                        const SizedBox(height: 20),
                        if (!_isLogin)
                          _f(_name, 'Name', Icons.person_outline_rounded, req),
                        _f(_email, 'Email', Icons.alternate_email,
                            (v) => req(v) ??
                                (v!.contains('@') ? null : 'Invalid email address'),
                            type: TextInputType.emailAddress, ltr: true),
                        if (!_isLogin)
                          _f(_phone, 'Phone number', Icons.phone_outlined, req,
                              type: TextInputType.phone, ltr: true),
                        _f(
                          _pass,
                          'Password',
                          Icons.lock_outline_rounded,
                          (v) => req(v) ??
                              (!_isLogin && v!.length < 8
                                  ? 'Password must be at least 8 characters'
                                  : null),
                          obscure: true,
                        ),
                        if (!_isLogin)
                          _f(_pass2, 'Confirm password',
                              Icons.lock_reset_outlined,
                              (v) => v != _pass.text
                                  ? 'Passwords don\'t match'
                                  : null,
                              obscure: true),
                        const SizedBox(height: 14),
                        AppButton(
                          label: _isLogin ? 'Sign in' : 'Create account',
                          icon: Icons.arrow_forward_rounded,
                          loading: _loading,
                          onTap: _submit,
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _segmented() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(children: [
          for (final login in [true, false])
            Expanded(
              child: Pressable(
                scale: .98,
                onTap: () => setState(() => _isLogin = login),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isLogin == login ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(login ? 'Sign in' : 'Sign up',
                      style: AppTheme.font(
                          weight: FontWeight.w600,
                          color: _isLogin == login
                              ? Colors.white
                              : AppColors.text)),
                ),
              ),
            ),
        ]),
      );

  Widget _f(TextEditingController c, String hint, IconData icon,
          String? Function(String?) validator,
          {TextInputType? type, bool ltr = false, bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          validator: validator,
          keyboardType: type,
          obscureText: obscure && _obscure,
          textDirection: ltr ? TextDirection.ltr : null,
          style: AppTheme.font(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: obscure
                ? IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  )
                : null,
          ),
        ),
      );
}
