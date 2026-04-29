import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/note.dart';
import '../../providers/document_provider.dart';
import '../../models/flashcard.dart';
import '../../models/quiz.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_widgets.dart';
import '../flashcards/flashcard_review_screen.dart';
import '../quizzes/quiz_result_screen.dart';
import '../quizzes/quiz_take_screen.dart';
import 'pdf_viewer_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  int _tab = 0;

  static const _sections = <_DocSection>[
    _DocSection(Icons.summarize_outlined, 'Summary'),
    _DocSection(Icons.chat_outlined, 'Chat'),
    _DocSection(Icons.style_outlined, 'Flashcards'),
    _DocSection(Icons.quiz_outlined, 'Quizzes'),
    _DocSection(Icons.lightbulb_outline_rounded, 'Concepts'),
    _DocSection(Icons.edit_note_rounded, 'Notes'),
    _DocSection(Icons.download_rounded, 'Download'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future.wait([
        context.read<DocumentProvider>().loadDocument(widget.documentId),
        context.read<DocumentProvider>().loadChatHistory(widget.documentId),
      ]);
    });
  }

  void _openPdf(String fileUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(url: fileUrl, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = context.watch<DocumentProvider>().current;
    final loading = context.watch<DocumentProvider>().loading;

    if (loading && doc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Document not found')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          doc.title,
          style: Theme.of(context).textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (doc.fileUrl != null)
            IconButton(
              tooltip: 'View PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _openPdf(doc.fileUrl!, doc.title),
            ),
          StatusBadge(status: doc.status),
          const SizedBox(width: 4),
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Sections',
              icon: const Icon(Icons.menu_book_rounded),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      endDrawer: _DocSectionsDrawer(
        sections: _sections,
        currentIndex: _tab,
        docTitle: doc.title,
        isDark: isDark,
        onTap: (i) {
          setState(() => _tab = i);
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _SummaryTab(documentId: widget.documentId),
          _ChatTab(documentId: widget.documentId),
          _FlashcardsTab(documentId: widget.documentId, docReady: doc.isReady),
          _QuizzesTab(documentId: widget.documentId, docReady: doc.isReady),
          _ConceptsTab(documentId: widget.documentId, docReady: doc.isReady),
          _NotesTab(documentId: widget.documentId),
          _DownloadTab(fileUrl: doc.fileUrl, title: doc.title),
        ],
      ),
    );
  }
}

class _DocSection {
  final IconData icon;
  final String label;
  const _DocSection(this.icon, this.label);
}

// ── Document sections drawer ───────────────────────────────────────────────────

class _DocSectionsDrawer extends StatelessWidget {
  final List<_DocSection> sections;
  final int currentIndex;
  final String docTitle;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _DocSectionsDrawer({
    required this.sections,
    required this.currentIndex,
    required this.docTitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 20.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: Border(
                bottom: BorderSide(color: context.cBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Sections',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  docTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Section items
          Expanded(
            child: ListView.builder(
              padding:
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              itemCount: sections.length,
              itemBuilder: (_, i) {
                final s = sections[i];
                final isActive = i == currentIndex;
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 13.h),
                      decoration: BoxDecoration(
                        gradient: isActive ? AppGradients.primary : null,
                        color: isActive
                            ? null
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.0)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            s.icon,
                            size: 20.r,
                            color: isActive
                                ? Colors.white
                                : context.cTextSecondary,
                          ),
                          SizedBox(width: 14.w),
                          Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : context.cTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Tab ──────────────────────────────────────────────────────────────

class _SummaryTab extends StatefulWidget {
  final String documentId;
  const _SummaryTab({required this.documentId});

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadSummary(widget.documentId);
    });
  }

  Future<void> _generate() async {
    final length = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SummaryLengthSheet(),
    );
    if (length == null || !mounted) return;
    setState(() => _generating = true);
    await context
        .read<DocumentProvider>()
        .generateSummary(widget.documentId, length: length);
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final summary = context.watch<DocumentProvider>().summary;

    if (_generating || (summary == null)) {
      return Center(
        child: _generating
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Generating summary...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.cTextSecondary,
                        ),
                  ),
                ],
              )
            : EmptyState(
                icon: Icons.summarize_outlined,
                title: 'No summary yet',
                subtitle: 'Generate an AI-powered summary of this document',
                action: AppButton(
                  label: 'Generate Summary',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _generate,
                ),
              ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'AI Summary',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Regenerate'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: summary,
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyLarge,
              h1: Theme.of(context).textTheme.headlineLarge,
              h2: Theme.of(context).textTheme.headlineMedium,
              h3: Theme.of(context).textTheme.headlineSmall,
              listBullet: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Tab ──────────────────────────────────────────────────────────────────

class _ChatTab extends StatefulWidget {
  final String documentId;
  const _ChatTab({required this.documentId});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _messageCtrl.clear();
    setState(() => _sending = true);
    await context
        .read<DocumentProvider>()
        .sendChatMessage(widget.documentId, text);
    if (mounted) {
      setState(() => _sending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final history = context.watch<DocumentProvider>().chatHistory;

    return Column(
      children: [
        Expanded(
          child: history.isEmpty
              ? EmptyState(
                  icon: Icons.chat_outlined,
                  title: 'Ask anything',
                  subtitle: 'Chat with AI about this document',
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final msg = history[i];
                    final isUser = msg['role'] == 'user';
                    return _ChatBubble(
                      content: msg['content'] as String? ?? '',
                      isUser: isUser,
                    );
                  },
                ),
        ),
        if (_sending)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text('AI is thinking...', style: TextStyle(color: context.cTextSecondary, fontSize: 13)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: context.cSurface,
            border: Border(top: BorderSide(color: context.cBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ask about this document...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send_rounded),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const _ChatBubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : context.cSurfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isUser
                  ? Text(
                      content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    )
                  : MarkdownBody(
                      data: content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: context.cTextPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Flashcards Tab ────────────────────────────────────────────────────────────

class _FlashcardsTab extends StatefulWidget {
  final String documentId;
  final bool docReady;
  const _FlashcardsTab({required this.documentId, required this.docReady});

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlashcardProvider>().loadSetForDocument(widget.documentId);
    });
  }

  Future<void> _generate() async {
    final count = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FlashcardGenerateSheet(),
    );
    if (count == null || !mounted) return;

    final result = await context
        .read<FlashcardProvider>()
        .generate(widget.documentId, numCards: count);
    if (!mounted) return;
    if (result == null) {
      final err = context.read<FlashcardProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed to generate flashcards'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(FlashcardSet set) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Flashcard Set'),
        content: Text(
            'Delete this set of ${set.totalCards} cards? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<FlashcardProvider>().deleteSet(set.id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<FlashcardProvider>();

    if (provider.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final sets = provider.documentSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Flashcard Sets',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (sets.isNotEmpty)
                      Text(
                        '${sets.length} ${sets.length == 1 ? 'Set' : 'Sets'} available',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (widget.docReady)
                ElevatedButton.icon(
                  onPressed: provider.generating ? null : _generate,
                  icon: provider.generating
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                      provider.generating ? 'Generating…' : 'Generate New Set'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        // ── Grid or empty state ──
        Expanded(
          child: sets.isEmpty
              ? EmptyState(
                  icon: Icons.style_outlined,
                  title: 'No flashcards yet',
                  subtitle: widget.docReady
                      ? 'Generate AI flashcards from this document'
                      : 'Document is still processing…',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: sets.length,
                  itemBuilder: (_, i) => _FlashcardSetCard(
                    set: sets[i],
                    onStudy: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FlashcardReviewScreen(flashcardSet: sets[i]),
                      ),
                    ),
                    onDelete: () => _confirmDelete(sets[i]),
                  ),
                ),
        ),
      ],
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Created ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStudy,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.fromBorderSide(BorderSide(color: context.cBorder)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + delete button row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: context.cTextTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Flashcard Set',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(set.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${set.totalCards} Cards',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quizzes Tab ───────────────────────────────────────────────────────────────

class _QuizzesTab extends StatefulWidget {
  final String documentId;
  final bool docReady;
  const _QuizzesTab({required this.documentId, required this.docReady});

  @override
  State<_QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<_QuizzesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizzesForDocument(widget.documentId);
    });
  }

  Future<void> _showGenerateSheet() async {
    final count = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QuizGenerateSheet(),
    );
    if (count == null || !mounted) return;

    final q = await context
        .read<QuizProvider>()
        .generate(widget.documentId, numQuestions: count);
    if (!mounted) return;
    if (q != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizTakeScreen(quiz: q)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            context.read<QuizProvider>().error ?? 'Failed to generate quiz'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _viewResults(String quizId) async {
    final provider = context.read<QuizProvider>();
    final quiz = provider.quizzes.firstWhere((q) => q.id == quizId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final answers = await provider.loadQuizAnswers(quizId);
    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    final result = provider.lastResult;
    if (answers == null || result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed to load results'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuizResultScreen(quiz: quiz, result: result, answers: answers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<QuizProvider>();

    if (provider.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Quizzes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (provider.quizzes.isNotEmpty)
                      Text(
                        '${provider.quizzes.length} ${provider.quizzes.length == 1 ? 'Quiz' : 'Quizzes'} available',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (widget.docReady)
                ElevatedButton.icon(
                  onPressed: provider.generating ? null : _showGenerateSheet,
                  icon: provider.generating
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                      provider.generating ? 'Generating…' : 'Generate Quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: provider.quizzes.isEmpty
              ? EmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No quizzes yet',
                  subtitle: widget.docReady
                      ? 'Generate a quiz to test your knowledge'
                      : 'Document is still processing...',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: provider.quizzes.length,
                  itemBuilder: (_, i) {
                    final quiz = provider.quizzes[i];
                    return _QuizCard(
                      quiz: quiz,
                      onStart: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => QuizTakeScreen(quiz: quiz)),
                      ),
                      onViewResults: () => _viewResults(quiz.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Quiz Card ─────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onStart;
  final VoidCallback onViewResults;

  const _QuizCard({
    required this.quiz,
    required this.onStart,
    required this.onViewResults,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final String badgeText;
    if (quiz.isCompleted && quiz.score != null) {
      badgeColor = quiz.score! >= 60 ? AppColors.success : AppColors.error;
      badgeText = 'SCORE: ${quiz.score}%';
    } else {
      badgeColor = AppColors.primary;
      badgeText = 'NOT ATTEMPTED';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.fromBorderSide(BorderSide(color: context.cBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.quiz_outlined,
                color: AppColors.accent, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(quiz.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.cTextTertiary,
                  fontSize: 11,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${quiz.totalQuestions} Questions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: quiz.isCompleted
                ? OutlinedButton(
                    onPressed: onViewResults,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: BorderSide(color: context.cBorder),
                      foregroundColor: context.cTextSecondary,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('View Results'),
                  )
                : ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Start Quiz'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Quiz Generate Sheet ───────────────────────────────────────────────────────

class _QuizGenerateSheet extends StatefulWidget {
  const _QuizGenerateSheet();

  @override
  State<_QuizGenerateSheet> createState() => _QuizGenerateSheetState();
}

class _QuizGenerateSheetState extends State<_QuizGenerateSheet> {
  int _selected = 10;

  static const _options = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          // Drag handle
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
            'Generate Quiz',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'How many questions do you want?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.cTextSecondary,
                ),
          ),
          const SizedBox(height: 24),
          // Option chips
          Row(
            children: _options.map((n) {
              final selected = n == _selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: n != _options.last ? 10 : 0),
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
                          color: selected
                              ? AppColors.primary
                              : context.cBorder,
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
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: Text('Generate $_selected Questions'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flashcard Generate Sheet ──────────────────────────────────────────────────

class _FlashcardGenerateSheet extends StatefulWidget {
  const _FlashcardGenerateSheet();

  @override
  State<_FlashcardGenerateSheet> createState() =>
      _FlashcardGenerateSheetState();
}

class _FlashcardGenerateSheetState extends State<_FlashcardGenerateSheet> {
  int _selected = 20;

  static const _options = [10, 20, 30, 40];

  @override
  Widget build(BuildContext context) {
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
            'Generate Flashcards',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'How many flashcards do you want?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.cTextSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: _options.map((n) {
              final selected = n == _selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: n != _options.last ? 10 : 0),
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
                          color: selected
                              ? AppColors.primary
                              : context.cBorder,
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
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: Text('Generate $_selected Cards'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Length Sheet ──────────────────────────────────────────────────────

class _SummaryLengthSheet extends StatefulWidget {
  const _SummaryLengthSheet();

  @override
  State<_SummaryLengthSheet> createState() => _SummaryLengthSheetState();
}

class _SummaryLengthSheetState extends State<_SummaryLengthSheet> {
  String _selected = 'standard';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          Text('Generate Summary',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Choose the summary length',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.cTextSecondary),
          ),
          const SizedBox(height: 24),
          _LengthOption(
            value: 'brief',
            selected: _selected,
            label: 'Brief',
            description: 'Overview + key points only',
            icon: Icons.short_text_rounded,
            onTap: () => setState(() => _selected = 'brief'),
          ),
          const SizedBox(height: 10),
          _LengthOption(
            value: 'standard',
            selected: _selected,
            label: 'Standard',
            description: 'Key concepts, takeaways, and terms',
            icon: Icons.subject_rounded,
            onTap: () => setState(() => _selected = 'standard'),
          ),
          const SizedBox(height: 10),
          _LengthOption(
            value: 'detailed',
            selected: _selected,
            label: 'Detailed',
            description: 'In-depth with examples and study questions',
            icon: Icons.article_outlined,
            onTap: () => setState(() => _selected = 'detailed'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: const Text('Generate'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LengthOption extends StatelessWidget {
  final String value;
  final String selected;
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _LengthOption({
    required this.value,
    required this.selected,
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.cSurfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.cBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : context.cTextSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : context.cTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.cTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Concepts Tab ──────────────────────────────────────────────────────────────

class _ConceptsTab extends StatefulWidget {
  final String documentId;
  final bool docReady;
  const _ConceptsTab({required this.documentId, required this.docReady});

  @override
  State<_ConceptsTab> createState() => _ConceptsTabState();
}

class _ConceptsTabState extends State<_ConceptsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _generate() async {
    await context.read<DocumentProvider>().generateConcepts(widget.documentId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<DocumentProvider>();
    final concepts = provider.concepts;

    if (provider.conceptsLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Extracting concepts...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.cTextSecondary),
            ),
          ],
        ),
      );
    }

    if (concepts.isEmpty) {
      return EmptyState(
        icon: Icons.lightbulb_outline_rounded,
        title: 'No concepts yet',
        subtitle: widget.docReady
            ? 'Extract key terms and definitions from this document'
            : 'Document is still processing...',
        action: widget.docReady
            ? AppButton(
                label: 'Extract Concepts',
                icon: Icons.auto_awesome_rounded,
                onPressed: _generate,
              )
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Key Concepts',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                      '${concepts.length} concepts extracted',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: concepts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final c = concepts[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.fromBorderSide(
                      BorderSide(color: context.cBorder)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lightbulb_outline_rounded,
                          color: AppColors.accent, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['term'] as String? ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['definition'] as String? ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: context.cTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatefulWidget {
  final String documentId;
  const _NotesTab({required this.documentId});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().load(widget.documentId);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    _noteCtrl.clear();
    await context.read<NotesProvider>().add(widget.documentId, text);
  }

  Future<void> _showEditSheet(Note note) async {
    final ctrl = TextEditingController(text: note.content);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditSheet(controller: ctrl),
    );
    ctrl.dispose();
    if (result != null && mounted) {
      await context
          .read<NotesProvider>()
          .update(widget.documentId, note.id, result);
    }
  }

  String _fmt(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final notes =
        context.watch<NotesProvider>().notesFor(widget.documentId);

    return Column(
      children: [
        Expanded(
          child: notes.isEmpty
              ? const EmptyState(
                  icon: Icons.notes_rounded,
                  title: 'No notes yet',
                  subtitle: 'Add your personal notes for this document',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final note = notes[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.fromBorderSide(
                            BorderSide(color: context.cBorder)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _fmt(note.updatedAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: context.cTextTertiary),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => _showEditSheet(note),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_outlined,
                                      size: 16,
                                      color: context.cTextSecondary),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => context
                                    .read<NotesProvider>()
                                    .delete(widget.documentId, note.id),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: context.cSurface,
            border: Border(top: BorderSide(color: context.cBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteEditSheet extends StatelessWidget {
  final TextEditingController controller;
  const _NoteEditSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
            Text('Edit Note',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Your note...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Download Tab ──────────────────────────────────────────────────────────────

class _DownloadTab extends StatefulWidget {
  final String? fileUrl;
  final String title;
  const _DownloadTab({required this.fileUrl, required this.title});

  @override
  State<_DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<_DownloadTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _downloading = false;
  double _progress = 0;
  String? _savedPath;
  String? _error;

  String _resolvedUrl() {
    var url = widget.fileUrl ?? '';
    if (url.contains('localhost')) {
      final baseUri = Uri.tryParse(ApiConstants.baseUrl);
      if (baseUri != null) {
        url = url.replaceFirst('localhost', baseUri.host);
      }
    }
    return url;
  }

  Future<void> _download() async {
    if (widget.fileUrl == null) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
      _savedPath = null;
    });
    try {
      final uri = Uri.parse(_resolvedUrl());
      final client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }
      final total = response.contentLength ?? 0;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (total > 0 && mounted) {
          setState(() => _progress = bytes.length / total);
        }
      }
      client.close();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = uri.pathSegments.last.isNotEmpty
          ? uri.pathSegments.last
          : '${widget.title.replaceAll(RegExp(r'[^\w\s]'), '').trim().replaceAll(' ', '_')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = 1;
          _savedPath = file.path;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _openPdfViewer() {
    if (_savedPath == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfViewerScreen(url: 'file://$_savedPath', title: widget.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.fileUrl == null) {
      return const EmptyState(
        icon: Icons.file_download_off_outlined,
        title: 'No file available',
        subtitle: 'This document has no attached PDF',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          // Document card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.fromBorderSide(
                  BorderSide(color: context.cBorder)),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      size: 36, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF Document',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.cTextTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // State: downloading
          if (_downloading) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.fromBorderSide(
                    BorderSide(color: context.cBorder)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Downloading...',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: context.cTextSecondary),
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: context.cBorder,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

          // State: downloaded
          ] else if (_savedPath != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved to device',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.success),
                        ),
                        Text(
                          _savedPath!.split('/').last,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: context.cTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openPdfViewer,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Again'),
              ),
            ),

          // State: error
          ] else if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Download failed. Please try again.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // State: idle
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save the PDF to your device for offline reading',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.cTextTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
