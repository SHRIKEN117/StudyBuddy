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

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<QuizProvider>().submitting;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
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
          },
        ),
        title: Text(
          widget.quiz.title,
          style: Theme.of(context).textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_page + 1} / $_total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_page + 1) / _total,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 3,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_page + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _question.question,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  ..._question.options.map(
                    (opt) => _OptionTile(
                      option: opt,
                      selected: _answers[_question.id] == opt.id,
                      revealed: _answered,
                      isCorrect: opt.id == _question.correctOptionId,
                      onTap: () => _selectOption(opt.id),
                    ),
                  ),
                  if (_answered && _question.explanation != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _question.explanation!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_page > 0)
                  Expanded(
                    child: AppButton(
                      label: 'Back',
                      outline: true,
                      onPressed: () => setState(() => _page--),
                    ),
                  ),
                if (_page > 0) const SizedBox(width: 12),
                Expanded(
                  child: _isLast
                      ? AppButton(
                          label: 'Submit Quiz',
                          loading: submitting,
                          onPressed: _answers.length == _total ? _submit : null,
                        )
                      : AppButton(
                          label: 'Next',
                          onPressed: _answered
                              ? () => setState(() => _page++)
                              : null,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.textPrimary;

    if (revealed) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.08);
        textColor = AppColors.success;
      } else if (selected && !isCorrect) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.08);
        textColor = AppColors.error;
      }
    } else if (selected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.06);
    }

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: revealed && (isCorrect || selected) ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                    ),
              ),
            ),
            if (revealed && isCorrect)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.success),
            if (revealed && selected && !isCorrect)
              const Icon(Icons.cancel_rounded, size: 20, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}
