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
    } on ApiException catch (e) {
      _error = e.message;
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
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<Quiz?> generate(String documentId) async {
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post(
        ApiConstants.generateQuiz,
        {'documentId': documentId},
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
    } on ApiException catch (e) {
      _error = e.message;
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
      final formattedAnswers = answers.entries
          .map((e) => {'questionId': e.key, 'selectedOptionId': e.value})
          .toList();
      final res = await ApiService.post(
        '/quizzes/$quizId/submit',
        {'answers': formattedAnswers},
      );
      _lastResult = QuizResult.fromJson(res);
      return _lastResult;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteQuiz(String id) async {
    try {
      await ApiService.delete('/quizzes/$id');
      _quizzes = _quizzes.where((q) => q.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
