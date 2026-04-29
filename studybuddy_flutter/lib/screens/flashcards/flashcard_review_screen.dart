import 'dart:ui' show ImageFilter;
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

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _flipped = false;
  int _known = 0;
  int _learning = 0;
  bool _done = false;

  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  Flashcard get _card => widget.flashcardSet.flashcards[_index];
  int get _total => widget.flashcardSet.flashcards.length;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _flipped = !_flipped);
  }

  void _rate(bool wasKnown) {
    final provider = context.read<FlashcardProvider>();
    provider.reviewCard(_card.id, wasKnown ? 'easy' : 'hard');

    // Reset flip animation before next card
    _flipCtrl.reset();
    setState(() {
      if (wasKnown) { _known++; } else { _learning++; }
      if (_index < _total - 1) {
        _index++;
        _flipped = false;
      } else {
        _done = true;
      }
    });
  }

  void _restart() {
    _flipCtrl.reset();
    setState(() {
      _index = 0;
      _flipped = false;
      _known = 0;
      _learning = 0;
      _done = false;
    });
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
                  AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 80, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: isDark ? 0.22 : 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: _done ? _buildSummary(isDark) : _buildCard(isDark),
          ),
        ],
      ),
    );
  }

  // ── Card view ──────────────────────────────────────────────────────────────

  Widget _buildCard(bool isDark) {
    return Column(
      children: [
        _TopBar(
          isDark: isDark,
          index: _index,
          total: _total,
          title: widget.flashcardSet.documentTitle,
          onBack: () => Navigator.pop(context),
        ),
        // Gradient progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _total,
              backgroundColor:
                  isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatPill(
                  icon: Icons.check_circle_rounded,
                  label: '$_known',
                  color: AppColors.success),
              Text(
                '${_index + 1} of $_total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              _StatPill(
                  icon: Icons.refresh_rounded,
                  label: '$_learning',
                  color: AppColors.warning),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _flip,
                    child: AnimatedBuilder(
                      animation: _flipAnim,
                      builder: (_, _) {
                        final angle = _flipAnim.value * 3.14159;
                        final showBack = _flipAnim.value > 0.5;
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: showBack
                              ? Transform(
                                  transform: Matrix4.identity()..rotateY(3.14159),
                                  alignment: Alignment.center,
                                  child: _AnswerCardFace(content: _card.answer),
                                )
                              : _QuestionCardFace(
                                  content: _card.question,
                                  isDark: isDark,
                                ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: _flipped ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 14, color: context.cTextTertiary),
                      const SizedBox(width: 4),
                      Text(
                        'Tap card to reveal answer',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: _flipped ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: !_flipped,
                    child: Row(
                      children: [
                        Expanded(
                          child: _RateButton(
                            label: 'Still Learning',
                            icon: Icons.refresh_rounded,
                            gradient: AppGradients.amber,
                            onTap: () => _rate(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RateButton(
                            label: 'Got It!',
                            icon: Icons.check_rounded,
                            gradient: AppGradients.emerald,
                            onTap: () => _rate(true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary view ───────────────────────────────────────────────────────────

  Widget _buildSummary(bool isDark) {
    final pct = (_known / _total * 100).round();
    final LinearGradient scoreGrad = pct >= 80
        ? AppGradients.emerald
        : pct >= 60
            ? AppGradients.amber
            : AppGradients.rose;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // Back button row
          Align(
            alignment: Alignment.centerLeft,
            child: _GlassIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              isDark: isDark,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 32),
          // Score circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: scoreGrad,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scoreGrad.colors.first.withValues(alpha: 0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'You reviewed all $_total cards',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.cTextSecondary,
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _SummaryStatCard(
                  label: 'Got It',
                  value: '$_known',
                  gradient: AppGradients.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStatCard(
                  label: 'Learning',
                  value: '$_learning',
                  gradient: AppGradients.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStatCard(
                  label: 'Total',
                  value: '$_total',
                  gradient: AppGradients.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GradientButton(
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
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isDark;
  final int index;
  final int total;
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.isDark,
    required this.index,
    required this.total,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          _GlassIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              isDark: isDark,
              onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${index + 1}/$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

// ── Stat pill ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question card face ─────────────────────────────────────────────────────────

class _QuestionCardFace extends StatelessWidget {
  final String content;
  final bool isDark;

  const _QuestionCardFace(
      {required this.content, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle top-right accent circle
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.30)),
                  ),
                  child: const Text(
                    'QUESTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  content,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Answer card face ───────────────────────────────────────────────────────────

class _AnswerCardFace extends StatelessWidget {
  final String content;

  const _AnswerCardFace({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -30, right: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: -20, left: -20,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ANSWER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  content,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rate button ────────────────────────────────────────────────────────────────

class _RateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _RateButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary stat card ──────────────────────────────────────────────────────────

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;

  const _SummaryStatCard(
      {required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: gradient.colors.first.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: gradient.colors.first.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                gradient.createShader(bounds),
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
