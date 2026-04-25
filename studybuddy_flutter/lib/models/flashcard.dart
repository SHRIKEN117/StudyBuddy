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
    final cardsJson = json['flashcards'] as List<dynamic>? ?? [];
    return FlashcardSet(
      id: json['_id'] as String? ?? json['id'] as String,
      documentId: (json['document'] is Map)
          ? (json['document'] as Map<String, dynamic>)['_id'] as String
          : json['document'] as String,
      documentTitle: (json['document'] is Map)
          ? (json['document'] as Map<String, dynamic>)['title'] as String? ?? ''
          : json['documentTitle'] as String? ?? '',
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
