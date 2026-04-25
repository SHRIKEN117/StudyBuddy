import 'dart:io';
import 'package:flutter/material.dart';
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

    final provider = context.read<DocumentProvider>();
    final ok = await provider.uploadDocument(File(path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Document uploaded successfully' : (provider.error ?? 'Upload failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: context.read<DocumentProvider>().loadDocuments,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Documents',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _uploadPdf,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Upload PDF'),
                    ),
                  ],
                ),
              ),
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
                  subtitle: 'Upload a PDF to get started',
                  action: AppButton(
                    label: 'Upload PDF',
                    icon: Icons.upload_rounded,
                    onPressed: _uploadPdf,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
          ],
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: doc.isReady ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: doc.status),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
            if (doc.description != null) ...[
              const SizedBox(height: 8),
              Text(
                doc.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (doc.pageCount != null)
                  _MetaChip(
                    icon: Icons.article_outlined,
                    label: '${doc.pageCount} pages',
                  ),
                if (doc.createdAt != null) ...[
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('MMM d, y').format(doc.createdAt!),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    if (doc.hasFlashcards)
                      const Tooltip(
                        message: 'Has flashcards',
                        child: Icon(
                          Icons.style_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    if (doc.hasQuizzes)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Tooltip(
                          message: 'Has quizzes',
                          child: Icon(
                            Icons.quiz_outlined,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
