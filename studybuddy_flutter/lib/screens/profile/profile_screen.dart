import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _changingPw = false;
  bool _loggingOut = false;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

Future<void> _changePassword() async {
    if (_currentPwCtrl.text.isEmpty || _newPwCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('New password must be at least 6 characters'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _changingPw = true);
    try {
      await ApiService.post(ApiConstants.changePassword, {
        'currentPassword': _currentPwCtrl.text,
        'newPassword': _newPwCtrl.text,
      });
      if (mounted) {
        _currentPwCtrl.clear();
        _newPwCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.success,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user, isDark: isDark),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionCard(
                  title: 'Change Password',
                  icon: Icons.lock_outline_rounded,
                  gradient: AppGradients.violet,
                  children: [
                    AppTextField(
                      label: 'Current Password',
                      controller: _currentPwCtrl,
                      obscure: true,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      label: 'New Password',
                      controller: _newPwCtrl,
                      obscure: true,
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: AppButton(
                        label: 'Update Password',
                        loading: _changingPw,
                        onPressed: _changePassword,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _SectionCard(
                  title: 'Appearance',
                  icon: Icons.palette_outlined,
                  gradient: AppGradients.cyan,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.cTextSecondary,
                          ),
                    ),
                    SizedBox(height: 10.h),
                    const _ThemePicker(),
                  ],
                ),
                SizedBox(height: 14.h),
                _SectionCard(
                  title: 'Account',
                  icon: Icons.manage_accounts_outlined,
                  gradient: AppGradients.rose,
                  children: [
                    GestureDetector(
                      onTap: _loggingOut ? null : _logout,
                      child: Row(
                        children: [
                          Container(
                            width: 38.r,
                            height: 38.r,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(Icons.logout_rounded,
                                color: AppColors.error, size: 18.r),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          if (_loggingOut)
                            SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          else
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14.r, color: context.cTextTertiary),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 140.h),
              ]),
            ),
          ),
        ],
      );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _ProfileHeader({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final initial = (user?.username?.isNotEmpty == true)
        ? (user!.username as String)[0].toUpperCase()
        : '?';

    return SizedBox(
      height: 240.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.darkBackground : AppColors.background,
            ),
          ),
          // Hamburger
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu_rounded,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            size: 24.r),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60, left: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.30 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20, right: -30,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: isDark ? 0.22 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 76.r,
                    height: 76.r,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    user?.username ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.cTextSecondary,
                        ),
                  ),
                  if (user?.createdAt != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Joined ${DateFormat('MMMM y').format(user!.createdAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: gradient.colors.first,
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIcon(
                icon: icon,
                gradient: gradient,
                size: 36,
                iconSize: 18,
              ),
              SizedBox(width: 10.w),
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }
}

// ── Theme picker ───────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<SettingsProvider>().themeMode;
    return Row(
      children: [
        _ThemeOption(
          mode: ThemeMode.light,
          icon: Icons.light_mode_rounded,
          label: 'Light',
          current: current,
        ),
        SizedBox(width: 8.w),
        _ThemeOption(
          mode: ThemeMode.system,
          icon: Icons.brightness_auto_rounded,
          label: 'Auto',
          current: current,
        ),
        SizedBox(width: 8.w),
        _ThemeOption(
          mode: ThemeMode.dark,
          icon: Icons.dark_mode_rounded,
          label: 'Dark',
          current: current,
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final ThemeMode current;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final selected = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<SettingsProvider>().setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primary : null,
            color: selected ? null : context.cSurfaceVariant,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : context.cBorder,
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20.r,
                color: selected ? Colors.white : context.cTextSecondary,
              ),
              SizedBox(height: 5.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : context.cTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
