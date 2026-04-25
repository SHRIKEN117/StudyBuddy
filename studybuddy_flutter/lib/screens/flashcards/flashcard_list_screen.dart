import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: context.read<FlashcardProvider>().loadSets,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                color: AppColors.surface,
                child: Text(
                  'Flashcards',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
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
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FlashcardSetCard(
                        set: provider.sets[i],
                        onStudy: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FlashcardReviewScreen(
                              flashcardSet: provider.sets[i],
                            ),
                          ),
                        ),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Flashcard Set'),
                              content:
                                  const Text('This cannot be undone.'),
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
                          if (confirmed == true && mounted) {
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
          ],
        ),
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.style_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  '${set.totalCards} cards${set.createdAt != null ? ' · ${DateFormat('MMM d').format(set.createdAt!)}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onStudy, child: const Text('Study')),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'delete') onDelete(); },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}
