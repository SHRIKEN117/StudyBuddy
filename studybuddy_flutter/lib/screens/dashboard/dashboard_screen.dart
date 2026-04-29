import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onTabTap;
  const DashboardScreen({super.key, this.onTabTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  Map<String, dynamic> get _overview =>
      _data?['overview'] as Map<String, dynamic>? ?? {};

  Map<String, dynamic> get _recentActivity =>
      _data?['recentActivity'] as Map<String, dynamic>? ?? {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(ApiConstants.dashboard);
      setState(() {
        _data = res['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } on ApiException {
      setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(
                greeting: _greeting(),
                username: user?.username ?? '',
                isDark: isDark,
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatGrid(
                      overview: _overview,
                      onTabTap: widget.onTabTap,
                    ),
                    SizedBox(height: 28.h),
                    _RecentActivity(recentActivity: _recentActivity),
                    SizedBox(height: 20.h),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient mesh header ───────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String username;
  final bool isDark;

  const _DashboardHeader({
    required this.greeting,
    required this.username,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return SizedBox(
      height: 210.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background base
          Positioned.fill(
            child: Container(
              color: isDark ? AppColors.darkBackground : AppColors.background,
            ),
          ),
          // Radial purple blob — top right
          Positioned(
            top: -50, right: -30,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.38 : 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Radial pink blob — mid left
          Positioned(
            top: 70, left: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: isDark ? 0.25 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Radial lavender blob — bottom center
          Positioned(
            bottom: -30, right: 80,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: isDark ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date pill badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '$greeting, ${username.isNotEmpty ? username : 'there'} 👋',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final Map<String, dynamic> overview;
  final ValueChanged<int>? onTabTap;
  const _StatGrid({required this.overview, this.onTabTap});

  @override
  Widget build(BuildContext context) {
    final docs = overview['totalDocuments'] as int? ?? 0;
    final cards = overview['totalFlashcards'] as int? ?? 0;
    final quizzes = overview['totalQuizzes'] as int? ?? 0;
    final avg = (overview['averageScore'] as num?)?.toDouble() ?? 0.0;

    // tabIndex: 1=Docs, 2=Cards, 3=Quizzes
    final stats = [
      _StatData('Documents', '$docs', Icons.description_rounded, AppGradients.violet, 1),
      _StatData('Flashcards', '$cards', Icons.style_rounded, AppGradients.primary, 2),
      _StatData('Quizzes', '$quizzes', Icons.quiz_rounded, AppGradients.rose, 3),
      _StatData('Avg Score', '${avg.toStringAsFixed(0)}%', Icons.bar_chart_rounded, AppGradients.emerald, 3),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 14.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => _StatCard(
            data: stats[i],
            onTap: onTabTap != null ? () => onTabTap!(stats[i].tabIndex) : null,
          ),
        ),
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final int tabIndex;
  const _StatData(this.label, this.value, this.icon, this.gradient, this.tabIndex);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  final VoidCallback? onTap;
  const _StatCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: data.gradient.colors.first,
      padding: EdgeInsets.all(14.r),
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: Row(
        children: [
          GradientIcon(
            icon: data.icon,
            gradient: data.gradient,
            size: 42,
            iconSize: 20,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  data.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity ────────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  final Map<String, dynamic> recentActivity;
  const _RecentActivity({required this.recentActivity});

  List<_ActivityItem> _buildItems() {
    final docs = recentActivity['documents'] as List<dynamic>? ?? [];
    final quizzes = recentActivity['quizzes'] as List<dynamic>? ?? [];
    final items = <_ActivityItem>[];

    for (final d in docs) {
      final m = d as Map<String, dynamic>;
      items.add(_ActivityItem(
        type: 'document',
        title: m['title'] as String? ?? m['fileName'] as String? ?? 'Document',
        time: m['lastAccessedAt'] as String? ?? m['createdAt'] as String?,
      ));
    }

    for (final q in quizzes) {
      final m = q as Map<String, dynamic>;
      final docTitle = (m['documentId'] is Map)
          ? (m['documentId'] as Map<String, dynamic>)['title'] as String? ?? ''
          : '';
      items.add(_ActivityItem(
        type: 'quiz',
        title: m['title'] as String? ??
            (docTitle.isNotEmpty ? 'Quiz: $docTitle' : 'Quiz'),
        time: m['completedAt'] as String? ?? m['createdAt'] as String?,
      ));
    }

    items.sort((a, b) {
      final ta = a.time != null ? DateTime.tryParse(a.time!) : null;
      final tb = b.time != null ? DateTime.tryParse(b.time!) : null;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    return items;
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final visible = items.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (items.isNotEmpty) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 14.h),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18.r),
          child: visible.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(28.r),
                  child: Column(
                    children: [
                      GradientIcon(
                        icon: Icons.history_rounded,
                        gradient: AppGradients.violet,
                        size: 52,
                        iconSize: 26,
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'No recent activity yet',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload a document to get started',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: List.generate(visible.length, (i) {
                    final item = visible[i];
                    final isDoc = item.type == 'document';
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 13.h),
                          child: Row(
                            children: [
                              GradientIcon(
                                icon: isDoc
                                    ? Icons.description_rounded
                                    : Icons.quiz_rounded,
                                gradient: isDoc
                                    ? AppGradients.violet
                                    : AppGradients.rose,
                                size: 36,
                                iconSize: 18,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.time != null)
                                      Text(
                                        _formatTime(item.time!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12.r,
                                color: context.cTextTertiary,
                              ),
                            ],
                          ),
                        ),
                        if (i < visible.length - 1)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: context.cBorder.withValues(alpha: 0.5),
                          ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }
}

class _ActivityItem {
  final String type;
  final String title;
  final String? time;
  const _ActivityItem({required this.type, required this.title, this.time});
}
