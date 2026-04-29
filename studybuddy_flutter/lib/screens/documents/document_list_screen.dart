import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/document_provider.dart';
import '../../models/document.dart';
import '../../widgets/app_widgets.dart';
import 'document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
    });
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    if (!mounted) return;

    final defaultTitle = path
        .split('/')
        .last
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => _TitleInputDialog(defaultTitle: defaultTitle),
    );
    if (title == null || !mounted) return;

    final provider = context.read<DocumentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.uploadDocument(File(path), title);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Document uploaded successfully'
          : (provider.error ?? 'Upload failed')),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _deleteDocument(BuildContext ctx, String id) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
            'This will also delete all associated flashcards and quizzes.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<DocumentProvider>().deleteDocument(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: context.read<DocumentProvider>().loadDocuments,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DocumentsHeader(isDark: isDark),
            ),
            if (provider.loading && provider.documents.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (provider.documents.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No documents yet',
                  subtitle: 'Tap the + button to upload a PDF',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _DocumentCard(
                        doc: provider.documents[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentDetailScreen(
                              documentId: provider.documents[i].id,
                            ),
                          ),
                        ),
                        onDelete: () =>
                            _deleteDocument(context, provider.documents[i].id),
                      ),
                    ),
                    childCount: provider.documents.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
      floatingActionButton: _GradientFab(onPressed: _uploadPdf),
    );
  }
}

// ── Gradient mesh header ───────────────────────────────────────────────────────

class _DocumentsHeader extends StatelessWidget {
  final bool isDark;
  const _DocumentsHeader({required this.isDark});

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
          Positioned(
            top: -40, right: -20,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: isDark ? 0.30 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60, left: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.14),
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
                      color: AppColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'My Library',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Documents',
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

// ── Gradient FAB ───────────────────────────────────────────────────────────────

class _GradientFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _GradientFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 80.h),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 58.r,
          height: 58.r,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28.r),
        ),
      ),
    );
  }
}

// ── Document card ──────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final Document doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.doc,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.primary,
      padding: EdgeInsets.all(16.r),
      borderRadius: BorderRadius.circular(18.r),
      onTap: doc.isReady ? onTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIcon(
                icon: Icons.picture_as_pdf_rounded,
                gradient: AppGradients.violet,
                size: 44,
                iconSize: 22,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  doc.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(status: doc.status),
              const SizedBox(width: 4),
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
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: context.cTextSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
          if (doc.description != null) ...[
            SizedBox(height: 8.h),
            Text(
              doc.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              if (doc.pageCount != null)
                _MetaChip(
                  icon: Icons.article_outlined,
                  label: '${doc.pageCount} pages',
                ),
              if (doc.createdAt != null) ...[
                SizedBox(width: 10.w),
                _MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('MMM d, y').format(doc.createdAt!),
                ),
              ],
              const Spacer(),
              if (doc.hasFlashcards)
                Tooltip(
                  message: 'Has flashcards',
                  child: Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.style_rounded,
                      size: 14.r,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (doc.hasFlashcards && doc.hasQuizzes)
                SizedBox(width: 6.w),
              if (doc.hasQuizzes)
                Tooltip(
                  message: 'Has quizzes',
                  child: Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.quiz_rounded,
                      size: 14.r,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.r, color: context.cTextSecondary),
        SizedBox(width: 4.w),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── Title input dialog ─────────────────────────────────────────────────────────

class _TitleInputDialog extends StatefulWidget {
  final String defaultTitle;
  const _TitleInputDialog({required this.defaultTitle});

  @override
  State<_TitleInputDialog> createState() => _TitleInputDialogState();
}

class _TitleInputDialogState extends State<_TitleInputDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Document Title'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter a title for this document',
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => Navigator.pop(
          context,
          _ctrl.text.trim().isEmpty ? widget.defaultTitle : _ctrl.text.trim(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _ctrl.text.trim().isEmpty
                ? widget.defaultTitle
                : _ctrl.text.trim(),
          ),
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
