import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/flashcard.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/app_widgets.dart';

class FlashcardReviewScreen extends StatefulWidget {
  final FlashcardSet flashcardSet;
  const FlashcardReviewScreen({super.key, required this.flashcardSet});

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  int _index = 0;
  bool _flipped = false;
  int _known = 0;
  int _learning = 0;
  bool _done = false;

  Flashcard get _card => widget.flashcardSet.flashcards[_index];
  int get _total => widget.flashcardSet.flashcards.length;

  void _flip() => setState(() => _flipped = !_flipped);

  void _rate(bool wasKnown) {
    final provider = context.read<FlashcardProvider>();
    provider.reviewCard(_card.id, wasKnown ? 'easy' : 'hard');

    setState(() {
      if (wasKnown) _known++; else _learning++;
      if (_index < _total - 1) {
        _index++;
        _flipped = false;
      } else {
        _done = true;
      }
    });
  }

  void _restart() => setState(() {
        _index = 0;
        _flipped = false;
        _known = 0;
        _learning = 0;
        _done = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Flashcard Review',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          if (!_done)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_index + 1} / $_total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: _done ? _buildSummary() : _buildCard(),
    );
  }

  Widget _buildCard() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_index + 1) / _total,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          minHeight: 3,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _flip,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _flipped
                        ? _CardFace(
                            key: const ValueKey('answer'),
                            label: 'ANSWER',
                            content: _card.answer,
                            color: AppColors.primary,
                          )
                        : _CardFace(
                            key: const ValueKey('question'),
                            label: 'QUESTION',
                            content: _card.question,
                            color: AppColors.surfaceVariant,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _flipped ? 'How did you do?' : 'Tap to reveal answer',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                if (_flipped)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => _rate(false),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Still Learning'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(color: AppColors.warning),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _rate(true),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Got It'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _flip,
                      child: const Text('Reveal Answer'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final pct = (_known / _total * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Session Complete!',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'You reviewed all $_total cards',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _ScoreCard(
                    label: 'Got It',
                    value: '$_known',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScoreCard(
                    label: 'Learning',
                    value: '$_learning',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScoreCard(
                    label: 'Score',
                    value: '$pct%',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AppButton(
                label: 'Study Again',
                icon: Icons.refresh_rounded,
                onPressed: _restart,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AppButton(
                label: 'Done',
                outline: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _CardFace({
    super.key,
    required this.label,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: color == AppColors.primary
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color == AppColors.primary
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
