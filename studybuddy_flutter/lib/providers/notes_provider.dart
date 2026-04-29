import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  final Map<String, List<Note>> _notesByDoc = {};

  List<Note> notesFor(String documentId) =>
      List.unmodifiable(_notesByDoc[documentId] ?? []);

  Future<void> load(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notes_$documentId');
    if (raw == null) return;
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();
    _notesByDoc[documentId] = list;
    notifyListeners();
  }

  Future<void> add(String documentId, String content) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: documentId,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notesByDoc[documentId] = [note, ...(_notesByDoc[documentId] ?? [])];
    notifyListeners();
    await _save(documentId);
  }

  Future<void> update(String documentId, String noteId, String content) async {
    final notes = _notesByDoc[documentId] ?? [];
    _notesByDoc[documentId] = notes.map((n) {
      return n.id == noteId ? n.copyWith(content: content) : n;
    }).toList();
    notifyListeners();
    await _save(documentId);
  }

  Future<void> delete(String documentId, String noteId) async {
    _notesByDoc[documentId] =
        (_notesByDoc[documentId] ?? []).where((n) => n.id != noteId).toList();
    notifyListeners();
    await _save(documentId);
  }

  Future<void> _save(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = (_notesByDoc[documentId] ?? [])
        .map((n) => n.toJson())
        .toList();
    await prefs.setString('notes_$documentId', jsonEncode(list));
  }
}
