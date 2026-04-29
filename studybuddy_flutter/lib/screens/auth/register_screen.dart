import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _submitting = false;
  String? _inlineError;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  static final _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d).{8,}$',
  );

  @override
  void dispose() {
    _username.dispose();
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
      final ok = await auth.register(
        _username.text.trim(),
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final msg = auth.error ?? 'Registration failed. Please try again.';
        final isConflict = msg.toLowerCase().contains('already');
        if (isConflict) {
          await showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Already Taken'),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          setState(() => _inlineError = msg);
        }
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
            top: -60, left: -40,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: isDark ? 0.30 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.14),
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
                    SizedBox(height: 16.h),
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: context.cGlass,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: context.cGlassBorder),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18.r,
                          color: context.cTextPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      'Create account',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Start your AI-powered learning journey',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.cTextSecondary,
                          ),
                    ),
                    SizedBox(height: 40.h),
                    AppTextField(
                      label: 'Username',
                      hint: 'your_username',
                      controller: _username,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (!_usernameRegex.hasMatch(v.trim())) {
                          return '3–20 characters: letters, numbers, underscores only';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
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
                    SizedBox(height: 16.h),
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
                        if (!_passwordRegex.hasMatch(v)) {
                          return 'Min 8 characters with at least one letter and one number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),
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
                      SizedBox(height: 16.h),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: GradientButton(
                        label: 'Create Account',
                        onPressed: _submitting ? null : _submit,
                        loading: _submitting,
                        icon: Icons.person_add_rounded,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.cTextSecondary,
                                  ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style:
                              TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
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
