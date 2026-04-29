import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  double? _downloadProgress; // null = not started, 0-1 = in progress

  // Session-level cache: URL → local file path
  static final Map<String, String> _pathCache = {};

  static const _bg = Color(0xFF0F0F1A);
  static const _cardBg = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  String _resolvedUrl() {
    var url = widget.url;
    if (url.contains('localhost')) {
      final baseUri = Uri.tryParse(ApiConstants.baseUrl);
      if (baseUri != null) {
        url = url.replaceFirst('localhost', baseUri.host);
      }
    }
    return url;
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _error = null;
      _localPath = null;
      _downloadProgress = null;
    });
    try {
      final resolved = _resolvedUrl();

      // Local file — use directly
      if (resolved.startsWith('file://')) {
        final path = Uri.parse(resolved).toFilePath();
        if (mounted) setState(() => _localPath = path);
        return;
      }

      // Check session cache first
      final cached = _pathCache[resolved];
      if (cached != null && File(cached).existsSync()) {
        if (mounted) setState(() => _localPath = cached);
        return;
      }

      final uri = Uri.parse(resolved);

      // Try streaming download with Content-Length progress
      final request = http.Request('GET', uri);
      final response = await request
          .send()
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];

      if (mounted) setState(() => _downloadProgress = 0.0);

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0 && mounted) {
          setState(() =>
              _downloadProgress = (bytes.length / contentLength).clamp(0.0, 1.0));
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = uri.pathSegments.lastWhere(
        (s) => s.isNotEmpty,
        orElse: () => 'document.pdf',
      );
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      _pathCache[resolved] = file.path;
      if (mounted) setState(() => _localPath = file.path);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'PDF',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: _totalPages > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: _totalPages > 0 && _localPath != null
          ? _buildPageBar()
          : null,
    );
  }

  Widget _buildPageBar() {
    final progress = (_currentPage + 1) / _totalPages;
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Page ${_currentPage + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_totalPages',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 36, color: AppColors.error),
              ),
              const SizedBox(height: 20),
              const Text(
                'Failed to load document',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading document…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_downloadProgress != null) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(_downloadProgress! * 100).toStringAsFixed(0)}%',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ] else
              const Text(
                'Please wait',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: PDFView(
          filePath: _localPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: true,
          pageSnap: true,
          fitEachPage: true,
          backgroundColor: const Color(0xFF1A1A2E),
          onRender: (pages) {
            if (mounted) setState(() => _totalPages = pages ?? 0);
          },
          onPageChanged: (page, _) {
            if (mounted) setState(() => _currentPage = page ?? 0);
          },
          onError: (error) {
            if (mounted) setState(() => _error = error.toString());
          },
        ),
      ),
    );
  }
}
