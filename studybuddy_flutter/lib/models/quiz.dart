class QuizOption {
  final String id;
  final String text;

  const QuizOption({required this.id, required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> json) => QuizOption(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        text: json['text'] as String,
      );
}

class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOption> options;
  final String correctOptionId;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionId,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
        .toList();

    // correctAnswer may be an object with _id or a plain id string
    String correctId = '';
    final ca = json['correctAnswer'];
    if (ca is Map) {
      correctId = ca['_id'] as String? ?? ca['id'] as String? ?? '';
    } else if (ca is String) {
      correctId = ca;
    }

    return QuizQuestion(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      question: json['question'] as String,
      options: opts,
      correctOptionId: correctId,
      explanation: json['explanation'] as String?,
    );
  }
}

class Quiz {
  final String id;
  final String documentId;
  final String documentTitle;
  final String title;
  final List<QuizQuestion> questions;
  final int totalQuestions;
  final DateTime? createdAt;

  const Quiz({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.title,
    required this.questions,
    required this.totalQuestions,
    this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final qs = (json['questions'] as List<dynamic>? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return Quiz(
      id: json['_id'] as String? ?? json['id'] as String,
      documentId: (json['document'] is Map)
          ? (json['document'] as Map<String, dynamic>)['_id'] as String
          : json['document'] as String? ?? '',
      documentTitle: (json['document'] is Map)
          ? (json['document'] as Map<String, dynamic>)['title'] as String? ?? ''
          : '',
      title: json['title'] as String? ?? 'Quiz',
      questions: qs,
      totalQuestions: json['totalQuestions'] as int? ?? qs.length,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class QuizResult {
  final int score;
  final int totalQuestions;
  final double percentage;
  final List<Map<String, dynamic>> answers;

  const QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.answers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? json;
    return QuizResult(
      score: result['score'] as int? ?? 0,
      totalQuestions: result['totalQuestions'] as int? ?? 0,
      percentage: (result['percentage'] as num?)?.toDouble() ?? 0.0,
      answers: (result['answers'] as List<dynamic>? ?? [])
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(),
    );
  }
}
