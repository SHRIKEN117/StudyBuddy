import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz.dart';
import '../../widgets/app_widgets.dart';
import 'quiz_take_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizResult result;
  final Map<String, String> answers;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.result,
    required this.answers,
  });

  LinearGradient get _scoreGradient {
    if (result.percentage >= 80) return AppGradients.emerald;
    if (result.percentage >= 60) return AppGradients.amber;
    return AppGradients.rose;
  }

  String get _scoreLabel {
    if (result.percentage >= 80) return 'Excellent!';
    if (result.percentage >= 60) return 'Good Job!';
    if (result.percentage >= 40) return 'Keep Practicing';
    return 'Needs Improvement';
  }

  String get _scoreEmoji {
    if (result.percentage >= 80) return '🏆';
    if (result.percentage >= 60) return '👍';
    if (result.percentage >= 40) return '📚';
    return '💪';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -60, right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _scoreGradient.colors.first
                      .withValues(alpha: isDark ? 0.28 : 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 80, left: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Quiz Results',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Hero score banner
                  GlassCard(
                    glowColor: _scoreGradient.colors.first,
                    padding: const EdgeInsets.all(28),
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        Text(
                          _scoreEmoji,
                          style: const TextStyle(fontSize: 44),
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              _scoreGradient.createShader(bounds),
                          child: Text(
                            '${result.percentage.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 72,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: _scoreGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _scoreLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Stat row
                        Row(
                          children: [
                            _HeroStat(
                              label: 'Correct',
                              value: '${result.score}',
                              gradient: AppGradients.emerald,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'out of',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  Text(
                                    '${result.totalQuestions}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'questions',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            _HeroStat(
                              label: 'Wrong',
                              value:
                                  '${result.totalQuestions - result.score}',
                              gradient: AppGradients.rose,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Breakdown header
                  Row(
                    children: [
                      GradientIcon(
                        icon: Icons.list_alt_rounded,
                        gradient: AppGradients.violet,
                        size: 32,
                        iconSize: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Question Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Question breakdown list
                  ...quiz.questions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final q = entry.value;
                    final selected = answers[q.id];
                    final correct = q.correctOptionId;
                    final wasCorrect = selected == correct;

                    final selectedText = q.options
                        .where((o) => o.id == selected)
                        .map((o) => o.text)
                        .firstOrNull;
                    final correctText = q.options
                        .where((o) => o.id == correct)
                        .map((o) => o.text)
                        .firstOrNull;

                    return _BreakdownCard(
                      index: i,
                      question: q.question,
                      wasCorrect: wasCorrect,
                      selectedText: wasCorrect ? null : selectedText,
                      correctText: correctText,
                      explanation: q.explanation,
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: GradientButton(
                      label: 'Retake Quiz',
                      icon: Icons.refresh_rounded,
                      gradient: AppGradients.rose,
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizTakeScreen(quiz: quiz),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: GradientButton(
                      label: 'Back to Document',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
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

// ── Hero stat ──────────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;

  const _HeroStat(
      {required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => gradient.createShader(b),
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Breakdown card ─────────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final int index;
  final String question;
  final bool wasCorrect;
  final String? selectedText;
  final String? correctText;
  final String? explanation;

  const _BreakdownCard({
    required this.index,
    required this.question,
    required this.wasCorrect,
    required this.selectedText,
    required this.correctText,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = wasCorrect ? AppColors.success : AppColors.error;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                color: accentColor,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            wasCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Q${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (!wasCorrect && selectedText != null) ...[
                      const SizedBox(height: 8),
                      _AnswerRow(
                        label: 'Your answer',
                        text: selectedText!,
                        color: AppColors.error,
                        icon: Icons.close_rounded,
                      ),
                    ],
                    if (correctText != null) ...[
                      const SizedBox(height: 4),
                      _AnswerRow(
                        label: 'Correct answer',
                        text: correctText!,
                        color: AppColors.success,
                        icon: Icons.check_rounded,
                      ),
                    ],
                    if (explanation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        explanation!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final IconData icon;

  const _AnswerRow({
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
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
    );
  }
}
