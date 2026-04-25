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

  List<Document> get documents => _documents;
  Document? get current => _current;
  bool get loading => _loading;
  String? get error => _error;
  String? get summary => _summary;
  List<Map<String, dynamic>> get chatHistory => _chatHistory;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> loadDocuments() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.get(ApiConstants.documents);
      final list = res['data'] as List<dynamic>;
      _documents = list
          .map((d) => Document.fromJson(d as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
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
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadDocument(File file) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.uploadFile(
        ApiConstants.uploadDocument,
        file,
        'file',
      );
      final doc = Document.fromJson(
        (res['data'] as Map<String, dynamic>)['document'] as Map<String, dynamic>? ??
            res['data'] as Map<String, dynamic>,
      );
      _documents = [doc, ..._documents];
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await ApiService.delete('${ApiConstants.documents}/$id');
      _documents = _documents.where((d) => d.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
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
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<String?> generateSummary(String documentId) async {
    try {
      final res = await ApiService.post(
        ApiConstants.generateSummary,
        {'documentId': documentId},
      );
      final data = res['data'] as Map<String, dynamic>?;
      _summary = data?['summary'] as String?;
      notifyListeners();
      return _summary;
    } on ApiException catch (e) {
      _error = e.message;
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
    } on ApiException {
      _chatHistory = [];
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
        {'documentId': documentId, 'message': message},
      );
      final data = res['data'] as Map<String, dynamic>?;
      final reply = data?['response'] as String? ?? data?['message'] as String? ?? '';
      _chatHistory = [
        ..._chatHistory,
        {'role': 'assistant', 'content': reply},
      ];
      notifyListeners();
      return reply;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
