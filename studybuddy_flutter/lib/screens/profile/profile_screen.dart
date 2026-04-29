import 'package:flutter/material.dart';
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
  late final _serverUrlCtrl =
      TextEditingController(text: ApiService.baseUrl);

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveServerUrl() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) return;
    await ApiService.setBaseUrl(url);
    _serverUrlCtrl.text = ApiService.baseUrl;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Server URL saved'),
        backgroundColor: AppColors.success,
      ));
    }
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user, isDark: isDark),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'New Password',
                      controller: _newPwCtrl,
                      obscure: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: AppButton(
                        label: 'Update Password',
                        loading: _changingPw,
                        onPressed: _changePassword,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                    const SizedBox(height: 10),
                    const _ThemePicker(),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Server',
                  icon: Icons.dns_outlined,
                  gradient: AppGradients.amber,
                  children: [
                    Text(
                      'Backend URL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.cTextSecondary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Server URL',
                      hint: 'http://192.168.x.x:8000/api',
                      controller: _serverUrlCtrl,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: AppButton(
                        label: 'Save URL',
                        onPressed: _saveServerUrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: AppColors.error, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          if (_loggingOut)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          else
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: context.cTextTertiary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 140),
              ]),
            ),
          ),
        ],
      ),
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
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.darkBackground : AppColors.background,
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 76,
                    height: 76,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.username ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.cTextSecondary,
                        ),
                  ),
                  if (user?.createdAt != null) ...[
                    const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(18),
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
              const SizedBox(width: 10),
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
          const SizedBox(height: 16),
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
        const SizedBox(width: 8),
        _ThemeOption(
          mode: ThemeMode.system,
          icon: Icons.brightness_auto_rounded,
          label: 'Auto',
          current: current,
        ),
        const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primary : null,
            color: selected ? null : context.cSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
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
                size: 20,
                color: selected ? Colors.white : context.cTextSecondary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
