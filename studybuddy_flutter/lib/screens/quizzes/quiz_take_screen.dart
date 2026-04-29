import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_widgets.dart';
import 'quiz_result_screen.dart';

class QuizTakeScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizTakeScreen({super.key, required this.quiz});

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  final Map<String, String> _answers = {};
  int _page = 0;

  QuizQuestion get _question => widget.quiz.questions[_page];
  int get _total => widget.quiz.questions.length;
  bool get _answered => _answers.containsKey(_question.id);
  bool get _isLast => _page == _total - 1;

  void _selectOption(String optionId) {
    if (_answers.containsKey(_question.id)) return;
    setState(() => _answers[_question.id] = optionId);
  }

  Future<void> _submit() async {
    final provider = context.read<QuizProvider>();
    final result = await provider.submit(widget.quiz.id, _answers);
    if (!mounted) return;
    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quiz: widget.quiz,
            result: result,
            answers: _answers,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Submission failed'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _confirmQuit() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<QuizProvider>().submitting;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_page + 1) / _total;

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50, right: -30,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: isDark ? 0.25 : 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 120, left: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          _GlassIconButton(
                            icon: Icons.close_rounded,
                            isDark: isDark,
                            onTap: _confirmQuit,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.quiz.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: AppGradients.rose,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_page + 1}/$_total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.border,
                              valueColor:
                                  const AlwaysStoppedAnimation(AppColors.accent),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${(_answers.length / _total * 100).round()}% answered',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: context.cTextSecondary),
                              ),
                              const Spacer(),
                              Text(
                                '${_total - _answers.length} remaining',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question card
                      GlassCard(
                        glowColor: AppColors.accent,
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppGradients.rose,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Question ${_page + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _question.question,
                              style:
                                  Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Options
                      ..._question.options.map(
                        (opt) => _OptionTile(
                          option: opt,
                          selected: _answers[_question.id] == opt.id,
                          revealed: _answered,
                          isCorrect: opt.id == _question.correctOptionId,
                          onTap: () => _selectOption(opt.id),
                        ),
                      ),
                      // Explanation
                      if (_answered && _question.explanation != null) ...[
                        const SizedBox(height: 8),
                        GlassCard(
                          glowColor: AppColors.primary,
                          padding: const EdgeInsets.all(14),
                          borderRadius: BorderRadius.circular(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GradientIcon(
                                icon: Icons.lightbulb_rounded,
                                gradient: AppGradients.amber,
                                size: 32,
                                iconSize: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Explanation',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _question.explanation!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating bottom action bar
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomBar(
              isDark: isDark,
              page: _page,
              isLast: _isLast,
              answered: _answered,
              allAnswered: _answers.length == _total,
              submitting: submitting,
              onBack: () => setState(() => _page--),
              onNext: () => setState(() => _page++),
              onSubmit: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom action bar ──────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isDark;
  final int page;
  final bool isLast;
  final bool answered;
  final bool allAnswered;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.isDark,
    required this.page,
    required this.isLast,
    required this.answered,
    required this.allAnswered,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F0A1E).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppColors.border.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: Row(
            children: [
              if (page > 0) ...[
                Expanded(
                  child: AppButton(
                    label: 'Back',
                    outline: true,
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: isLast
                    ? GradientButton(
                        label: 'Submit Quiz',
                        gradient: AppGradients.rose,
                        loading: submitting,
                        onPressed: allAnswered ? onSubmit : null,
                        icon: Icons.send_rounded,
                      )
                    : GradientButton(
                        label: 'Next Question',
                        onPressed: answered ? onNext : null,
                        icon: Icons.arrow_forward_rounded,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Option tile ────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final QuizOption option;
  final bool selected;
  final bool revealed;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.selected,
    required this.revealed,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.border.withValues(alpha: 0.7);
    Color bgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.90);
    Color textColor = context.cTextPrimary;
    Widget? trailingIcon;

    if (revealed) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.10);
        textColor = AppColors.success;
        trailingIcon = Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: Colors.white, size: 14),
        );
      } else if (selected && !isCorrect) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.10);
        textColor = AppColors.error;
        trailingIcon = Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded,
              color: Colors.white, size: 14),
        );
      }
    } else if (selected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.08);
      trailingIcon = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.circle, color: Colors.white, size: 8),
      );
    }

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: revealed && (isCorrect || selected) ? 1.5 : 1.0,
          ),
          boxShadow: selected && !revealed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight:
                          selected || (revealed && isCorrect)
                              ? FontWeight.w600
                              : FontWeight.w400,
                    ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Glass icon button ──────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.border.withValues(alpha: 0.7),
              ),
            ),
            child: Icon(icon, size: 18, color: context.cTextPrimary),
          ),
        ),
      ),
    );
  }
}
