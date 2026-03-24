import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    _notes = await DatabaseService.instance.getNotes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    final id = await DatabaseService.instance.insertNote(note);
    _notes.insert(0, note.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    await DatabaseService.instance.updateNote(note);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) _notes[index] = note;
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    await DatabaseService.instance.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> togglePin(Note note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    notifyListeners();
  }
}
