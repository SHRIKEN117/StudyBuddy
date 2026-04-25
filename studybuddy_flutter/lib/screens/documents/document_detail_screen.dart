import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/document_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_widgets.dart';
import '../flashcards/flashcard_review_screen.dart';
import '../quizzes/quiz_take_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<DocumentProvider>().loadDocument(widget.documentId);
      await context.read<DocumentProvider>().loadChatHistory(widget.documentId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        actions: [StatusBadge(status: doc.status), const SizedBox(width: 16)],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Chat'),
            Tab(text: 'Flashcards'),
            Tab(text: 'Quizzes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(documentId: widget.documentId),
          _ChatTab(documentId: widget.documentId),
          _FlashcardsTab(documentId: widget.documentId, docReady: doc.isReady),
          _QuizzesTab(documentId: widget.documentId, docReady: doc.isReady),
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
    setState(() => _generating = true);
    await context.read<DocumentProvider>().generateSummary(widget.documentId);
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
                          color: AppColors.textSecondary,
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
          const Padding(
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
                Text('AI is thinking...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
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
                color: isUser ? AppColors.primary : AppColors.surfaceVariant,
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
                          color: AppColors.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<FlashcardProvider>();

    if (provider.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final set = provider.current;

    if (set == null) {
      return EmptyState(
        icon: Icons.style_outlined,
        title: 'No flashcards yet',
        subtitle: widget.docReady
            ? 'Generate AI flashcards from this document'
            : 'Document is still processing...',
        action: widget.docReady
            ? AppButton(
                label: 'Generate Flashcards',
                icon: Icons.auto_awesome_rounded,
                loading: provider.generating,
                onPressed: () async {
                  final result = await context
                      .read<FlashcardProvider>()
                      .generate(widget.documentId);
                  if (result == null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Failed to generate'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              )
            : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  const Border.fromBorderSide(BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.style_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${set.totalCards} Flashcards',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Ready to review',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardReviewScreen(flashcardSet: set),
                    ),
                  ),
                  child: const Text('Study'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: set.flashcards.length,
              itemBuilder: (_, i) {
                final card = set.flashcards[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q: ${card.question}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A: ${card.answer}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<QuizProvider>();

    if (provider.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quizzes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (widget.docReady)
                AppButton(
                  label: 'Generate',
                  icon: Icons.auto_awesome_rounded,
                  loading: provider.generating,
                  onPressed: () async {
                    final q = await context
                        .read<QuizProvider>()
                        .generate(widget.documentId);
                    if (q != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizTakeScreen(quiz: q),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.quizzes.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.quiz_outlined,
                title: 'No quizzes yet',
                subtitle: widget.docReady
                    ? 'Generate a quiz to test your knowledge'
                    : 'Document is still processing...',
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: provider.quizzes.length,
                itemBuilder: (_, i) {
                  final quiz = provider.quizzes[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border.fromBorderSide(
                          BorderSide(color: AppColors.border)),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.quiz_outlined,
                            color: AppColors.accent, size: 20),
                      ),
                      title: Text(quiz.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                        '${quiz.totalQuestions} questions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizTakeScreen(quiz: quiz),
                          ),
                        ),
                        child: const Text('Take'),
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
