class QuizOption {
  final String id;
  final String text;

  const QuizOption({required this.id, required this.text});

  // Backend sends options as plain strings; handle both String and Map forms
  factory QuizOption.fromValue(dynamic value) {
    if (value is String) {
      return QuizOption(id: value, text: value);
    }
    final json = value as Map<String, dynamic>;
    final text = json['text'] as String? ?? json['_id'] as String? ?? '';
    final id = json['_id'] as String? ?? json['id'] as String? ?? text;
    return QuizOption(id: id, text: text);
  }
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

  // index is the 0-based position; used as question id for submit payloads
  factory QuizQuestion.fromJson(Map<String, dynamic> json, int index) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .map(QuizOption.fromValue)
        .toList();

    // correctAnswer is a plain string (option text)
    final correctAnswer = json['correctAnswer'] as String? ?? '';

    return QuizQuestion(
      id: index.toString(),
      question: json['question'] as String,
      options: opts,
      correctOptionId: correctAnswer,
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
  final DateTime? completedAt;
  final int? score; // percentage 0-100

  const Quiz({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.title,
    required this.questions,
    required this.totalQuestions,
    this.createdAt,
    this.completedAt,
    this.score,
  });

  bool get isCompleted => completedAt != null;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    final qs = questionsJson
        .asMap()
        .entries
        .map((e) => QuizQuestion.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();

    final docField = json['document'] ?? json['documentId'];
    final String docId;
    final String docTitle;
    if (docField is Map<String, dynamic>) {
      docId = docField['_id'] as String? ?? docField['id'] as String? ?? '';
      docTitle = docField['title'] as String? ?? '';
    } else {
      docId = docField as String? ?? '';
      docTitle = '';
    }

    return Quiz(
      id: json['_id'] as String? ?? json['id'] as String,
      documentId: docId,
      documentTitle: docTitle,
      title: json['title'] as String? ?? 'Quiz',
      questions: qs,
      totalQuestions: json['totalQuestions'] as int? ?? qs.length,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      score: json['score'] as int?,
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
    // Full API response shape: {success, data: {score, totalQuestions, percentage, userAnswers}}
    final data = json['data'] as Map<String, dynamic>? ??
        json['result'] as Map<String, dynamic>? ??
        json;
    return QuizResult(
      // Backend 'score' = percentage (0-100); 'correctCount' = number correct
      score: data['correctCount'] as int? ?? data['score'] as int? ?? 0,
      totalQuestions: data['totalQuestions'] as int? ?? 0,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0.0,
      answers: (data['userAnswers'] as List<dynamic>? ??
              data['answers'] as List<dynamic>? ??
              [])
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(),
    );
  }
}
