import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/quiz.dart';
import '../../widgets/app_widgets.dart';

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

  Color get _scoreColor {
    if (result.percentage >= 80) return AppColors.success;
    if (result.percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get _scoreLabel {
    if (result.percentage >= 80) return 'Excellent!';
    if (result.percentage >= 60) return 'Good Job!';
    if (result.percentage >= 40) return 'Keep Practicing';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quiz Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _ScoreBanner(
              percentage: result.percentage,
              score: result.score,
              total: result.totalQuestions,
              label: _scoreLabel,
              color: _scoreColor,
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Question Breakdown',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: wasCorrect
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: wasCorrect
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            wasCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            size: 14,
                            color: wasCorrect ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Q${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: wasCorrect ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.question,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (!wasCorrect && selectedText != null)
                      _AnswerRow(
                        label: 'Your answer',
                        text: selectedText,
                        color: AppColors.error,
                        icon: Icons.close_rounded,
                      ),
                    if (correctText != null)
                      _AnswerRow(
                        label: 'Correct answer',
                        text: correctText,
                        color: AppColors.success,
                        icon: Icons.check_rounded,
                      ),
                    if (q.explanation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        q.explanation!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AppButton(
                label: 'Back to Document',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBanner extends StatelessWidget {
  final double percentage;
  final int score;
  final int total;
  final String label;
  final Color color;

  const _ScoreBanner({
    required this.percentage,
    required this.score,
    required this.total,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 64,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '$score out of $total correct',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
