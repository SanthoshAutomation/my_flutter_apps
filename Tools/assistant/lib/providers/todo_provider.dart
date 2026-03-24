import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  bool _isLoading = false;

  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;

  List<Todo> get pendingTodos =>
      _todos.where((t) => !t.isCompleted).toList();
  List<Todo> get completedTodos =>
      _todos.where((t) => t.isCompleted).toList();

  List<Todo> get todayTodos {
    final today = DateTime.now();
    return _todos.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final d = t.dueDate!;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();
  }

  List<Todo> get overdueTodos {
    final now = DateTime.now();
    return _todos.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      return t.dueDate!.isBefore(
          DateTime(now.year, now.month, now.day));
    }).toList();
  }

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    _todos = await DatabaseService.instance.getTodos();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTodo(Todo todo) async {
    final id = await DatabaseService.instance.insertTodo(todo);
    final newTodo = todo.copyWith(id: id);
    _todos.insert(0, newTodo);
    if (newTodo.reminderTime != null) {
      await NotificationService.instance.scheduleTodoReminder(
        id: id,
        title: '\u2705 Time to: ${newTodo.title}',
        body: _motivate(newTodo.title),
        scheduledTime: newTodo.reminderTime!,
      );
    }
    notifyListeners();
  }

  Future<void> updateTodo(Todo todo) async {
    await DatabaseService.instance.updateTodo(todo);
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) _todos[index] = todo;
    if (todo.id != null) {
      await NotificationService.instance.cancelTodoReminder(todo.id!);
      if (todo.reminderTime != null) {
        await NotificationService.instance.scheduleTodoReminder(
          id: todo.id!,
          title: '\u2705 Time to: ${todo.title}',
          body: _motivate(todo.title),
          scheduledTime: todo.reminderTime!,
        );
      }
    }
    notifyListeners();
  }

  Future<void> toggleTodo(Todo todo) async {
    await updateTodo(todo.copyWith(isCompleted: !todo.isCompleted));
  }

  Future<void> deleteTodo(int id) async {
    await DatabaseService.instance.deleteTodo(id);
    await NotificationService.instance.cancelTodoReminder(id);
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  String _motivate(String task) {
    final msgs = [
      "You've got this! Every step counts. \u{1F4AA}",
      'Small progress is still progress. Keep going! \u2728',
      "You're capable of amazing things! \u{1F680}",
      'One task at a time - you\'re doing great! \u{1F3AF}',
      'Believe in yourself and take action! \u{1F31F}',
    ];
    return msgs[DateTime.now().millisecond % msgs.length];
  }
}
