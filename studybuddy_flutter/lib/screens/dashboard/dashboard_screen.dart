import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(ApiConstants.dashboard);
      setState(() {
        _stats = res['data'] as Map<String, dynamic>?;
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
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, ${user?.username ?? ''}',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
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
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatGrid(stats: _stats),
                    const SizedBox(height: 28),
                    _RecentActivity(stats: _stats),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _StatGrid({this.stats});

  @override
  Widget build(BuildContext context) {
    final documents = stats?['totalDocuments'] as int? ?? 0;
    final flashcards = stats?['totalFlashcards'] as int? ?? 0;
    final quizzes = stats?['totalQuizzes'] as int? ?? 0;
    final avgScore = (stats?['averageQuizScore'] as num?)?.toDouble() ?? 0.0;

    final items = [
      _StatItem(
        icon: Icons.description_outlined,
        label: 'Documents',
        value: '$documents',
        color: AppColors.primary,
      ),
      _StatItem(
        icon: Icons.style_outlined,
        label: 'Flashcards',
        value: '$flashcards',
        color: const Color(0xFF7C3AED),
      ),
      _StatItem(
        icon: Icons.quiz_outlined,
        label: 'Quizzes',
        value: '$quizzes',
        color: AppColors.accent,
      ),
      _StatItem(
        icon: Icons.bar_chart_rounded,
        label: 'Avg Score',
        value: '${avgScore.toStringAsFixed(0)}%',
        color: AppColors.success,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _RecentActivity({this.stats});

  @override
  Widget build(BuildContext context) {
    final recent = stats?['recentActivity'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
            ),
            child: const Center(
              child: Text(
                'No recent activity yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = recent[i] as Map<String, dynamic>;
                final type = item['type'] as String? ?? '';
                final title = item['title'] as String? ?? '';
                final time = item['createdAt'] as String?;
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForType(type),
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(title, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: time != null
                      ? Text(
                          _formatTime(time),
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return Icons.description_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'flashcard':
        return Icons.style_outlined;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
