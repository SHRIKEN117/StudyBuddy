import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/quiz.dart';

class QuizProvider extends ChangeNotifier {
  List<Quiz> _quizzes = [];
  Quiz? _current;
  QuizResult? _lastResult;
  bool _loading = false;
  bool _generating = false;
  bool _submitting = false;
  String? _error;

  List<Quiz> get quizzes => _quizzes;
  Quiz? get current => _current;
  QuizResult? get lastResult => _lastResult;
  bool get loading => _loading;
  bool get generating => _generating;
  bool get submitting => _submitting;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> loadAllQuizzes() async {
    _setLoading(true);
    _error = null;
    _quizzes = [];
    try {
      final res = await ApiService.get(ApiConstants.quizzes);
      final data = res['data'];
      if (data is List) {
        _quizzes = data
            .map((q) => Quiz.fromJson(q as Map<String, dynamic>))
            .toList();
      }
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadQuizzesForDocument(String documentId) async {
    _setLoading(true);
    _error = null;
    _quizzes = [];
    try {
      final res = await ApiService.get('/quizzes/$documentId');
      final data = res['data'];
      if (data is List) {
        _quizzes = data
            .map((q) => Quiz.fromJson(q as Map<String, dynamic>))
            .toList();
      }
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadQuiz(String quizId) async {
    _setLoading(true);
    _error = null;
    _lastResult = null;
    try {
      final res = await ApiService.get('/quizzes/quiz/$quizId');
      _current = Quiz.fromJson(res['data'] as Map<String, dynamic>);
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Quiz?> generate(String documentId, {int numQuestions = 10}) async {
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post(
        ApiConstants.generateQuiz,
        {'documentId': documentId, 'numQuestions': numQuestions},
      );
      final data = res['data'];
      Quiz? quiz;
      if (data is Map) {
        quiz = Quiz.fromJson(data as Map<String, dynamic>);
      }
      if (quiz != null) {
        _quizzes = [quiz, ..._quizzes];
        _current = quiz;
      }
      return quiz;
    } on Object catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<QuizResult?> submit(
    String quizId,
    Map<String, String> answers,
  ) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      // Backend expects {questionIndex: int, selectedAnswer: String}
      // Question ids are stored as their 0-based index strings
      final formattedAnswers = answers.entries
          .map((e) => {
                'questionIndex': int.tryParse(e.key) ?? 0,
                'selectedAnswer': e.value,
              })
          .toList();
      final res = await ApiService.post(
        '/quizzes/$quizId/submit',
        {'answers': formattedAnswers},
      );
      _lastResult = QuizResult.fromJson(res);
      return _lastResult;
    } on Object catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> loadQuizAnswers(String quizId) async {
    _error = null;
    try {
      final res = await ApiService.get('/quizzes/$quizId/results');
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      final results = data['results'] as List<dynamic>? ?? [];
      final answers = <String, String>{};
      for (final r in results) {
        final map = r as Map<String, dynamic>;
        final idx = map['questionIndex'] as int? ?? 0;
        final selected = map['selectedAnswer'] as String? ?? '';
        answers[idx.toString()] = selected;
      }

      final quizData = data['quiz'] as Map<String, dynamic>?;
      final percentage = (quizData?['score'] as num?)?.toDouble() ?? 0.0;
      final total = quizData?['totalQuestions'] as int? ?? results.length;
      final correctCount =
          results.where((r) => (r as Map)['isCorrect'] == true).length;
      _lastResult = QuizResult(
        score: correctCount,
        totalQuestions: total,
        percentage: percentage,
        answers: results
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList(),
      );
      return answers;
    } on Object catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<bool> deleteQuiz(String id) async {
    try {
      await ApiService.delete('/quizzes/$id');
      _quizzes = _quizzes.where((q) => q.id != id).toList();
      notifyListeners();
      return true;
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
