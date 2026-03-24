import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AlarmProvider extends ChangeNotifier {
  List<AlarmModel> _alarms = [];
  bool _isLoading = false;

  List<AlarmModel> get alarms => _alarms;
  bool get isLoading => _isLoading;

  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();
    _alarms = await DatabaseService.instance.getAlarms();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    final id = await DatabaseService.instance.insertAlarm(alarm);
    final newAlarm = alarm.copyWith(id: id);
    _alarms.add(newAlarm);
    _sort();
    if (newAlarm.isEnabled) await _scheduleAlarm(newAlarm);
    notifyListeners();
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    await DatabaseService.instance.updateAlarm(alarm);
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) _alarms[index] = alarm;
    if (alarm.id != null) {
      await NotificationService.instance.cancelAlarm(alarm.id!);
      if (alarm.isEnabled) await _scheduleAlarm(alarm);
    }
    notifyListeners();
  }

  Future<void> toggleAlarm(AlarmModel alarm) async {
    await updateAlarm(alarm.copyWith(isEnabled: !alarm.isEnabled));
  }

  Future<void> deleteAlarm(int id) async {
    await DatabaseService.instance.deleteAlarm(id);
    await NotificationService.instance.cancelAlarm(id);
    _alarms.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void _sort() {
    _alarms.sort((a, b) {
      final am = a.time.hour * 60 + a.time.minute;
      final bm = b.time.hour * 60 + b.time.minute;
      return am.compareTo(bm);
    });
  }

  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    if (alarm.id == null) return;
    final now = DateTime.now();
    var scheduled = DateTime(
        now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await NotificationService.instance.scheduleAlarm(
      id: alarm.id!,
      title: alarm.title,
      scheduledTime: scheduled,
      repeating: alarm.days.any((d) => d),
    );
  }
}
