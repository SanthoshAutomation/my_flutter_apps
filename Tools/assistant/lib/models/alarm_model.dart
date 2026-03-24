import 'package:flutter/material.dart';

class AlarmModel {
  final int? id;
  final String title;
  final TimeOfDay time;
  final List<bool> days; // Mon-Sun (7 elements)
  final bool isEnabled;
  final String sound;
  final bool vibrate;

  AlarmModel({
    this.id,
    required this.title,
    required this.time,
    List<bool>? days,
    this.isEnabled = true,
    this.sound = 'default',
    this.vibrate = true,
  }) : days = days ?? List.filled(7, false);

  AlarmModel copyWith({
    int? id,
    String? title,
    TimeOfDay? time,
    List<bool>? days,
    bool? isEnabled,
    String? sound,
    bool? vibrate,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      days: days ?? List.from(this.days),
      isEnabled: isEnabled ?? this.isEnabled,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'hour': time.hour,
      'minute': time.minute,
      'days': days.map((d) => d ? 1 : 0).toList().join(','),
      'is_enabled': isEnabled ? 1 : 0,
      'sound': sound,
      'vibrate': vibrate ? 1 : 0,
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    final daysList =
        (map['days'] as String).split(',').map((e) => e == '1').toList();
    return AlarmModel(
      id: map['id'],
      title: map['title'] ?? 'Alarm',
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
      days: daysList.length == 7 ? daysList : List.filled(7, false),
      isEnabled: (map['is_enabled'] ?? 1) == 1,
      sound: map['sound'] ?? 'default',
      vibrate: (map['vibrate'] ?? 1) == 1,
    );
  }

  String get daysLabel {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final active = <String>[];
    for (int i = 0; i < 7; i++) {
      if (days[i]) active.add(dayNames[i]);
    }
    if (active.isEmpty) return 'Once';
    if (active.length == 7) return 'Every day';
    if (active.length == 5 && !days[5] && !days[6]) return 'Weekdays';
    if (active.length == 2 && days[5] && days[6]) return 'Weekends';
    return active.join(', ');
  }
}
