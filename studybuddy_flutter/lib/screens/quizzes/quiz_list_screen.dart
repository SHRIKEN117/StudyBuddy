import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_widgets.dart';
import 'quiz_take_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadAllQuizzes();
    });
  }

  Future<void> _takeQuiz(Quiz quiz) async {
    if (quiz.questions.length <= 3) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => QuizTakeScreen(quiz: quiz),
      ));
      return;
    }

    final count = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuizCountSheet(totalQuestions: quiz.questions.length),
    );

    if (count == null || !mounted) return;

    final questions = count >= quiz.questions.length
        ? quiz.questions
        : (List.of(quiz.questions)..shuffle()).take(count).toList();

    final subset = Quiz(
      id: quiz.id,
      documentId: quiz.documentId,
      documentTitle: quiz.documentTitle,
      title: quiz.title,
      questions: questions,
      totalQuestions: questions.length,
      createdAt: quiz.createdAt,
    );

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizTakeScreen(quiz: subset),
    ));
  }

  Future<void> _retakeQuiz(Quiz quiz) async {
    final provider = context.read<QuizProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    final answers = await provider.loadQuizAnswers(quiz.id);

    if (!mounted) return;
    Navigator.pop(context);

    if (answers == null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => QuizTakeScreen(quiz: quiz),
      ));
      return;
    }

    final wrongQuestions = quiz.questions.where((q) {
      final selected = answers[q.id];
      return selected == null || selected != q.correctOptionId;
    }).toList();

    if (wrongQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfect score! Retaking full quiz.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => QuizTakeScreen(quiz: quiz),
      ));
      return;
    }

    final wrongQuiz = Quiz(
      id: quiz.id,
      documentId: quiz.documentId,
      documentTitle: quiz.documentTitle,
      title: quiz.title,
      questions: wrongQuestions,
      totalQuestions: wrongQuestions.length,
      createdAt: quiz.createdAt,
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizTakeScreen(quiz: wrongQuiz),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: context.read<QuizProvider>().loadAllQuizzes,
      color: AppColors.accent,
      child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _QuizzesHeader(isDark: isDark),
            ),
            if (provider.loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (provider.quizzes.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No quizzes yet',
                  subtitle: 'Open a document and generate a quiz to get started',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _QuizCard(
                        quiz: provider.quizzes[i],
                        onTake: provider.quizzes[i].isCompleted
                            ? () => _retakeQuiz(provider.quizzes[i])
                            : () => _takeQuiz(provider.quizzes[i]),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Quiz?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<QuizProvider>()
                                .deleteQuiz(provider.quizzes[i].id);
                          }
                        },
                      ),
                    ),
                    childCount: provider.quizzes.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      );
  }
}

// ── Gradient mesh header ───────────────────────────────────────────────────────

class _QuizzesHeader extends StatelessWidget {
  final bool isDark;
  const _QuizzesHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.h,
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
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
            top: -30, right: -10,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: isDark ? 0.32 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B9D)
                        .withValues(alpha: isDark ? 0.22 : 0.12),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Quiz Time',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Quizzes',
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

// ── Quiz card ──────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTake;
  final VoidCallback onDelete;

  const _QuizCard({
    required this.quiz,
    required this.onTake,
    required this.onDelete,
  });

  LinearGradient get _scoreGradient {
    if (quiz.score == null) return AppGradients.rose;
    if (quiz.score! >= 80) return AppGradients.emerald;
    if (quiz.score! >= 60) return AppGradients.amber;
    return AppGradients.rose;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.accent,
      padding: EdgeInsets.all(16.r),
      borderRadius: BorderRadius.circular(18.r),
      child: Row(
        children: [
          GradientIcon(
            icon: Icons.quiz_rounded,
            gradient: AppGradients.rose,
            size: 48,
            iconSize: 22,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.documentTitle.isNotEmpty
                      ? quiz.documentTitle
                      : quiz.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${quiz.totalQuestions} questions',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    if (quiz.createdAt != null)
                      Text(
                        DateFormat('MMM d').format(quiz.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (quiz.isCompleted && quiz.score != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          gradient: _scoreGradient,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '${quiz.score}%',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onTake,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: AppGradients.rose,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                quiz.isCompleted ? 'Retake' : 'Take',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert_rounded,
                color: context.cTextSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Quiz count picker sheet ────────────────────────────────────────────────────

class _QuizCountSheet extends StatefulWidget {
  final int totalQuestions;
  const _QuizCountSheet({required this.totalQuestions});

  @override
  State<_QuizCountSheet> createState() => _QuizCountSheetState();
}

class _QuizCountSheetState extends State<_QuizCountSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.totalQuestions >= 10 ? 10 : widget.totalQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final options = [5, 10, 15].where((n) => n < widget.totalQuestions).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.cBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Take Quiz',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'How many questions do you want to answer?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.cTextSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ...options.map((n) {
                final selected = n == _selected;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent
                              : context.cSurfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.accent : context.cBorder,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$n',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : context.cTextPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              'Qs',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: selected
                                        ? Colors.white70
                                        : context.cTextSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = widget.totalQuestions),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selected == widget.totalQuestions
                          ? AppColors.accent
                          : context.cSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selected == widget.totalQuestions
                            ? AppColors.accent
                            : context.cBorder,
                        width: _selected == widget.totalQuestions ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'All',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: _selected == widget.totalQuestions
                                    ? Colors.white
                                    : context.cTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          '${widget.totalQuestions}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: _selected == widget.totalQuestions
                                    ? Colors.white70
                                    : context.cTextSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: Text('Start $_selected Questions'),
            ),
          ),
        ],
      ),
    );
  }
}
