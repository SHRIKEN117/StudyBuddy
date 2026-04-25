import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/flashcard.dart';

class FlashcardProvider extends ChangeNotifier {
  List<FlashcardSet> _sets = [];
  FlashcardSet? _current;
  bool _loading = false;
  bool _generating = false;
  String? _error;

  List<FlashcardSet> get sets => _sets;
  FlashcardSet? get current => _current;
  bool get loading => _loading;
  bool get generating => _generating;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> loadSets() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.get(ApiConstants.flashcards);
      final list = res['data'] as List<dynamic>;
      _sets = list
          .map((s) => FlashcardSet.fromJson(s as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSetForDocument(String documentId) async {
    _setLoading(true);
    _error = null;
    _current = null;
    try {
      final res = await ApiService.get('${ApiConstants.flashcards}/$documentId');
      final data = res['data'];
      if (data is List && data.isNotEmpty) {
        _current = FlashcardSet.fromJson(data.first as Map<String, dynamic>);
      } else if (data is Map) {
        _current = FlashcardSet.fromJson(data as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<FlashcardSet?> generate(String documentId) async {
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post(
        ApiConstants.generateFlashcards,
        {'documentId': documentId},
      );
      final data = res['data'];
      FlashcardSet? set;
      if (data is Map) {
        set = FlashcardSet.fromJson(data as Map<String, dynamic>);
      }
      if (set != null) {
        _current = set;
        // Refresh all sets
        await loadSets();
      }
      return set;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<void> reviewCard(String cardId, String rating) async {
    try {
      await ApiService.post('/flashcards/$cardId/review', {'rating': rating});
    } on ApiException {
      // non-critical
    }
  }

  Future<void> toggleStar(String cardId) async {
    try {
      await ApiService.put('/flashcards/$cardId/star', {});
      if (_current != null) {
        final updated = _current!.flashcards.map((c) {
          if (c.id == cardId) {
            return Flashcard(
              id: c.id,
              question: c.question,
              answer: c.answer,
              topic: c.topic,
              isStarred: !c.isStarred,
              reviewCount: c.reviewCount,
              confidenceScore: c.confidenceScore,
            );
          }
          return c;
        }).toList();
        _current = FlashcardSet(
          id: _current!.id,
          documentId: _current!.documentId,
          documentTitle: _current!.documentTitle,
          totalCards: _current!.totalCards,
          flashcards: updated,
          createdAt: _current!.createdAt,
        );
        notifyListeners();
      }
    } on ApiException {
      // non-critical
    }
  }

  Future<bool> deleteSet(String id) async {
    try {
      await ApiService.delete('${ApiConstants.flashcards}/$id');
      _sets = _sets.where((s) => s.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
