class Todo {
  final int? id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final bool isCompleted;
  final int priority; // 0=low, 1=medium, 2=high
  final DateTime createdAt;
  final bool syncedToCloud;

  Todo({
    this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.reminderTime,
    this.isCompleted = false,
    this.priority = 1,
    DateTime? createdAt,
    this.syncedToCloud = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? reminderTime,
    bool clearReminderTime = false,
    bool? isCompleted,
    int? priority,
    DateTime? createdAt,
    bool? syncedToCloud,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderTime:
          clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'reminder_time': reminderTime?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced_to_cloud': syncedToCloud ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      reminderTime: map['reminder_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reminder_time'] as int)
          : null,
      isCompleted: (map['is_completed'] ?? 0) == 1,
      priority: map['priority'] ?? 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      syncedToCloud: (map['synced_to_cloud'] ?? 0) == 1,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Low';
      case 2:
        return 'High';
      default:
        return 'Medium';
    }
  }
}
