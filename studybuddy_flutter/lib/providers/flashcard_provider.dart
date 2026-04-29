import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/flashcard.dart';

class FlashcardProvider extends ChangeNotifier {
  List<FlashcardSet> _sets = [];
  List<FlashcardSet> _documentSets = [];
  FlashcardSet? _current;
  bool _loading = false;
  bool _generating = false;
  String? _error;

  List<FlashcardSet> get sets => _sets;
  List<FlashcardSet> get documentSets => _documentSets;
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
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSetForDocument(String documentId) async {
    _setLoading(true);
    _error = null;
    _documentSets = [];
    _current = null;
    try {
      final res = await ApiService.get('${ApiConstants.flashcards}/$documentId');
      final data = res['data'];
      if (data is List) {
        _documentSets = data
            .map((s) => FlashcardSet.fromJson(s as Map<String, dynamic>))
            .toList();
      } else if (data is Map) {
        _documentSets = [FlashcardSet.fromJson(data as Map<String, dynamic>)];
      }
      _current = _documentSets.isNotEmpty ? _documentSets.first : null;
    } on Object catch (e) {
      _error = e.toString();
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
        _documentSets = [set, ..._documentSets];
      }
      return set;
    } on Object catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<void> reviewCard(String cardId, String rating) async {
    try {
      await ApiService.post('/flashcards/$cardId/review', {'rating': rating});
    } on Object {
      // non-critical
    }
  }

  Future<void> toggleStar(String cardId) async {
    try {
      await ApiService.put('/flashcards/$cardId/star', {});
      _updateStarInDocumentSets(cardId);
      notifyListeners();
    } on Object {
      // non-critical
    }
  }

  void _updateStarInDocumentSets(String cardId) {
    _documentSets = _documentSets.map((set) {
      final idx = set.flashcards.indexWhere((c) => c.id == cardId);
      if (idx == -1) return set;
      final updated = List<Flashcard>.from(set.flashcards);
      final old = updated[idx];
      updated[idx] = Flashcard(
        id: old.id,
        question: old.question,
        answer: old.answer,
        topic: old.topic,
        isStarred: !old.isStarred,
        reviewCount: old.reviewCount,
        confidenceScore: old.confidenceScore,
      );
      return FlashcardSet(
        id: set.id,
        documentId: set.documentId,
        documentTitle: set.documentTitle,
        totalCards: set.totalCards,
        flashcards: updated,
        createdAt: set.createdAt,
      );
    }).toList();
    if (_current != null) {
      _current = _documentSets.firstWhere(
        (s) => s.id == _current!.id,
        orElse: () => _documentSets.first,
      );
    }
  }

  Future<bool> deleteSet(String id) async {
    try {
      await ApiService.delete('${ApiConstants.flashcards}/$id');
      _sets = _sets.where((s) => s.id != id).toList();
      _documentSets = _documentSets.where((s) => s.id != id).toList();
      if (_current?.id == id) {
        _current = _documentSets.isNotEmpty ? _documentSets.first : null;
      }
      notifyListeners();
      return true;
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
