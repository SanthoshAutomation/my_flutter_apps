class Appointment {
  final int? id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // 'appointment', 'vacation', 'event'
  final String location;
  final DateTime? reminderTime;
  final int colorIndex;
  final bool syncedToCloud;

  Appointment({
    this.id,
    required this.title,
    this.description = '',
    required this.startDate,
    required this.endDate,
    this.type = 'appointment',
    this.location = '',
    this.reminderTime,
    this.colorIndex = 0,
    this.syncedToCloud = false,
  });

  Appointment copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? location,
    DateTime? reminderTime,
    bool clearReminderTime = false,
    int? colorIndex,
    bool? syncedToCloud,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      location: location ?? this.location,
      reminderTime:
          clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      colorIndex: colorIndex ?? this.colorIndex,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
      'type': type,
      'location': location,
      'reminder_time': reminderTime?.millisecondsSinceEpoch,
      'color_index': colorIndex,
      'synced_to_cloud': syncedToCloud ? 1 : 0,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate:
          DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
      type: map['type'] ?? 'appointment',
      location: map['location'] ?? '',
      reminderTime: map['reminder_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reminder_time'] as int)
          : null,
      colorIndex: map['color_index'] ?? 0,
      syncedToCloud: (map['synced_to_cloud'] ?? 0) == 1,
    );
  }

  String get typeIcon {
    switch (type) {
      case 'vacation':
        return '🏖️';
      case 'event':
        return '🎉';
      default:
        return '📅';
    }
  }
}
