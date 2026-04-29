class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String? topic;
  final bool isStarred;
  final int reviewCount;
  final double? confidenceScore;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.topic,
    this.isStarred = false,
    this.reviewCount = 0,
    this.confidenceScore,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['_id'] as String? ?? json['id'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
        topic: json['topic'] as String?,
        isStarred: json['isStarred'] as bool? ?? false,
        reviewCount: json['reviewCount'] as int? ?? 0,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      );
}

class FlashcardSet {
  final String id;
  final String documentId;
  final String documentTitle;
  final int totalCards;
  final List<Flashcard> flashcards;
  final DateTime? createdAt;

  const FlashcardSet({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.totalCards,
    required this.flashcards,
    this.createdAt,
  });

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    // Backend sends 'cards'; fall back to 'flashcards' for forward-compat
    final cardsJson =
        json['cards'] as List<dynamic>? ?? json['flashcards'] as List<dynamic>? ?? [];

    // Backend stores document ref as 'document' (ObjectId or populated obj)
    // Also handle 'documentId' as a fallback
    final docField = json['document'] ?? json['documentId'];
    final String docId;
    final String docTitle;
    if (docField is Map<String, dynamic>) {
      docId = docField['_id'] as String? ?? docField['id'] as String? ?? '';
      docTitle = docField['title'] as String? ?? '';
    } else {
      docId = docField as String? ?? '';
      docTitle = json['documentTitle'] as String? ?? '';
    }

    return FlashcardSet(
      id: json['_id'] as String? ?? json['id'] as String,
      documentId: docId,
      documentTitle: docTitle,
      totalCards: json['totalCards'] as int? ?? cardsJson.length,
      flashcards: cardsJson
          .map((c) => Flashcard.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
