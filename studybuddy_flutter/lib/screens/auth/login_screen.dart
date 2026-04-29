import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _submitting = false;
  String? _inlineError;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

Future<void> _submit() async {
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final ok = await auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _inlineError =
              auth.error ?? 'Incorrect email or password. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60, left: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: isDark ? 0.28 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 48.h),
                    // Logo
                    Image.asset(
                      isDark
                          ? 'assets/images/logo_dark.png'
                          : 'assets/images/logo.png',
                      width: 120.r,
                      height: 120.r,
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Sign in to continue learning',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.cTextSecondary,
                          ),
                    ),
                    SizedBox(height: 32.h),
                    AppTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!_emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      obscure: !_showPassword,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: context.cTextSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    if (_inlineError != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 18.r, color: AppColors.error),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                _inlineError!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: GradientButton(
                        label: 'Sign In',
                        onPressed: _submitting ? null : _submit,
                        loading: _submitting,
                        icon: Icons.login_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.cTextSecondary,
                                  ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          style:
                              TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
