class Document {
  final String id;
  final String title;
  final String? description;
  final String status;
  final int? pageCount;
  final int? wordCount;
  final String? fileUrl;
  final DateTime? createdAt;
  final DateTime? lastAccessedAt;
  final bool hasFlashcards;
  final bool hasQuizzes;
  final bool hasSummary;

  const Document({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.pageCount,
    this.wordCount,
    this.fileUrl,
    this.createdAt,
    this.lastAccessedAt,
    this.hasFlashcards = false,
    this.hasQuizzes = false,
    this.hasSummary = false,
  });

  bool get isReady => status == 'Ready';
  bool get isProcessing => status == 'Processing';
  bool get isFailed => status == 'Failed';

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['_id'] as String? ?? json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: json['status'] as String? ?? 'Processing',
        pageCount: json['pageCount'] as int?,
        wordCount: json['wordCount'] as int?,
        fileUrl: json['fileUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        lastAccessedAt: json['lastAccessedAt'] != null
            ? DateTime.tryParse(json['lastAccessedAt'] as String)
            : null,
        hasFlashcards: json['hasFlashcards'] as bool? ?? false,
        hasQuizzes: json['hasQuizzes'] as bool? ?? false,
        hasSummary: json['hasSummary'] as bool? ?? false,
      );
}
