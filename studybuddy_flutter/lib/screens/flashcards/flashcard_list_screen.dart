import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/flashcard_provider.dart';
import '../../models/flashcard.dart';
import '../../widgets/app_widgets.dart';
import 'flashcard_review_screen.dart';

class FlashcardListScreen extends StatefulWidget {
  const FlashcardListScreen({super.key});

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadSets();
    });
  }

  Future<void> _showStudySheet(FlashcardSet set) async {
    if (set.flashcards.length <= 3) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => FlashcardReviewScreen(flashcardSet: set),
      ));
      return;
    }

    final count = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FlashcardStudySheet(totalCards: set.flashcards.length),
    );

    if (count == null || !mounted) return;

    final shuffled = List.of(set.flashcards)..shuffle();
    final cards = count >= set.flashcards.length ? set.flashcards : shuffled.take(count).toList();

    final subset = FlashcardSet(
      id: set.id,
      documentId: set.documentId,
      documentTitle: set.documentTitle,
      totalCards: cards.length,
      flashcards: cards,
      createdAt: set.createdAt,
    );

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FlashcardReviewScreen(flashcardSet: subset),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: context.read<FlashcardProvider>().loadSets,
      color: AppColors.primary,
      child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _FlashcardsHeader(isDark: isDark),
            ),
            if (provider.loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (provider.sets.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.style_outlined,
                  title: 'No flashcard sets yet',
                  subtitle: 'Open a document and generate flashcards',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _FlashcardSetCard(
                        set: provider.sets[i],
                        onStudy: () => _showStudySheet(provider.sets[i]),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Flashcard Set'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
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
                                .read<FlashcardProvider>()
                                .deleteSet(provider.sets[i].id);
                          }
                        },
                      ),
                    ),
                    childCount: provider.sets.length,
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

class _FlashcardsHeader extends StatelessWidget {
  final bool isDark;
  const _FlashcardsHeader({required this.isDark});

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
                    AppColors.primary.withValues(alpha: isDark ? 0.32 : 0.18),
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
                    AppColors.primaryLight
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
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Study Mode',
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
                    'Flashcards',
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

// ── Flashcard set card ─────────────────────────────────────────────────────────

class _FlashcardSetCard extends StatelessWidget {
  final FlashcardSet set;
  final VoidCallback onStudy;
  final VoidCallback onDelete;

  const _FlashcardSetCard({
    required this.set,
    required this.onStudy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.primary,
      padding: EdgeInsets.all(16.r),
      borderRadius: BorderRadius.circular(18.r),
      child: Row(
        children: [
          GradientIcon(
            icon: Icons.style_rounded,
            gradient: AppGradients.primary,
            size: 48,
            iconSize: 22,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  set.documentTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${set.totalCards} cards',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (set.createdAt != null) ...[
                      SizedBox(width: 6.w),
                      Text(
                        DateFormat('MMM d').format(set.createdAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onStudy,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Study',
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

// ── Study count picker sheet ───────────────────────────────────────────────────

class _FlashcardStudySheet extends StatefulWidget {
  final int totalCards;
  const _FlashcardStudySheet({required this.totalCards});

  @override
  State<_FlashcardStudySheet> createState() => _FlashcardStudySheetState();
}

class _FlashcardStudySheetState extends State<_FlashcardStudySheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.totalCards >= 10 ? 10 : widget.totalCards;
  }

  @override
  Widget build(BuildContext context) {
    final options = [5, 10, 20].where((n) => n < widget.totalCards).toList();

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
            'Study Flashcards',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'How many cards do you want to study?',
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
                              ? AppColors.primary
                              : context.cSurfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                selected ? AppColors.primary : context.cBorder,
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
                              'Cards',
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
                  onTap: () => setState(() => _selected = widget.totalCards),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selected == widget.totalCards
                          ? AppColors.primary
                          : context.cSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selected == widget.totalCards
                            ? AppColors.primary
                            : context.cBorder,
                        width: _selected == widget.totalCards ? 2 : 1,
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
                                color: _selected == widget.totalCards
                                    ? Colors.white
                                    : context.cTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          '${widget.totalCards}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: _selected == widget.totalCards
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
              child: Text('Study $_selected Cards'),
            ),
          ),
        ],
      ),
    );
  }
}
