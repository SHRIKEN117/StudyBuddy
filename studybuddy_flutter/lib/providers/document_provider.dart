import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/document.dart';

class DocumentProvider extends ChangeNotifier {
  List<Document> _documents = [];
  Document? _current;
  bool _loading = false;
  String? _error;
  String? _summary;
  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> _concepts = [];
  bool _conceptsLoading = false;

  List<Document> get documents => _documents;
  Document? get current => _current;
  bool get loading => _loading;
  String? get error => _error;
  String? get summary => _summary;
  List<Map<String, dynamic>> get chatHistory => _chatHistory;
  List<Map<String, dynamic>> get concepts => _concepts;
  bool get conceptsLoading => _conceptsLoading;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // Tracks doc IDs currently being polled so we don't launch duplicate loops.
  final Set<String> _polling = {};

  Future<void> loadDocuments() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.get(ApiConstants.documents);
      final list = res['data'] as List<dynamic>;
      _documents = list
          .map((d) => Document.fromJson(d as Map<String, dynamic>))
          .toList();
      // Resume polling for any document that is still processing.
      for (final doc in _documents.where((d) => d.isProcessing)) {
        _startPolling(doc.id);
      }
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDocument(String id) async {
    _setLoading(true);
    _error = null;
    _summary = null;
    _chatHistory = [];
    try {
      final res = await ApiService.get('${ApiConstants.documents}/$id');
      _current = Document.fromJson(res['data'] as Map<String, dynamic>);
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadDocument(File file, String title) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.uploadFile(
        ApiConstants.uploadDocument,
        file,
        'file',
        fields: {'title': title.trim()},
      );
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) throw ApiException('Upload failed: no data returned', 0);
      final doc = Document.fromJson(
        data['document'] as Map<String, dynamic>? ?? data,
      );
      _documents = [doc, ..._documents];
      _setLoading(false);
      if (doc.isProcessing) _startPolling(doc.id);
      return true;
    } on Object catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _startPolling(String docId) {
    if (_polling.contains(docId)) return;
    _polling.add(docId);
    _pollUntilReady(docId);
  }

  Future<void> _pollUntilReady(String docId) async {
    const interval = Duration(seconds: 3);
    const maxAttempts = 40; // 2 minutes max
    var consecutiveErrors = 0;
    try {
      for (var i = 0; i < maxAttempts; i++) {
        await Future.delayed(interval);
        try {
          // Fetch the full list so we get the same response shape as
          // loadDocuments(), avoiding per-document side effects.
          final res = await ApiService.get(ApiConstants.documents);
          final list = res['data'] as List<dynamic>;
          final updated = list
              .map((d) => Document.fromJson(d as Map<String, dynamic>))
              .toList();

          // Find the specific document in the refreshed list.
          final match = updated.cast<Document?>().firstWhere(
                (d) => d?.id == docId,
                orElse: () => null,
              );

          if (match == null) return; // document deleted — stop polling

          // Replace only the polled document; keep everything else as-is.
          _documents = [
            for (final d in _documents) d.id == docId ? match : d,
          ];
          notifyListeners();
          consecutiveErrors = 0;

          if (!match.isProcessing) return; // done
        } on Object {
          consecutiveErrors++;
          if (consecutiveErrors >= 3) return; // give up after 3 straight failures
        }
      }
    } finally {
      _polling.remove(docId);
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await ApiService.delete('${ApiConstants.documents}/$id');
      _documents = _documents.where((d) => d.id != id).toList();
      notifyListeners();
      return true;
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSummary(String documentId) async {
    _summary = null;
    notifyListeners();
    try {
      final res = await ApiService.get('/ai/summary/$documentId');
      final data = res['data'] as Map<String, dynamic>?;
      _summary = data?['summary'] as String?;
      notifyListeners();
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<String?> generateSummary(String documentId, {String length = 'standard'}) async {
    try {
      final res = await ApiService.post(
        ApiConstants.generateSummary,
        {'documentId': documentId, 'length': length},
      );
      final data = res['data'] as Map<String, dynamic>?;
      _summary = data?['summary'] as String?;
      notifyListeners();
      return _summary;
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadChatHistory(String documentId) async {
    try {
      final res = await ApiService.get('/ai/chat-history/$documentId');
      final list = res['data'] as List<dynamic>? ?? [];
      _chatHistory = list.map((m) => Map<String, dynamic>.from(m as Map)).toList();
      notifyListeners();
    } on Object {
      _chatHistory = [];
      notifyListeners();
    }
  }

  Future<void> generateConcepts(String documentId) async {
    _conceptsLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.post(
        ApiConstants.extractConcepts,
        {'documentId': documentId},
      );
      final data = res['data'] as Map<String, dynamic>?;
      final list = data?['concepts'] as List<dynamic>? ?? [];
      _concepts = list.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _conceptsLoading = false;
      notifyListeners();
    }
  }

  Future<String?> sendChatMessage(String documentId, String message) async {
    _chatHistory = [
      ..._chatHistory,
      {'role': 'user', 'content': message},
    ];
    notifyListeners();
    try {
      final res = await ApiService.post(
        ApiConstants.chat,
        {'documentId': documentId, 'question': message},
      );
      final data = res['data'] as Map<String, dynamic>?;
      final reply = data?['answer'] as String? ?? data?['response'] as String? ?? '';
      _chatHistory = [
        ..._chatHistory,
        {'role': 'assistant', 'content': reply},
      ];
      notifyListeners();
      return reply;
    } on Object catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
