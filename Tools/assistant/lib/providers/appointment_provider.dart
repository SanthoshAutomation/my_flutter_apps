import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  bool _isLoading = false;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;

  List<Appointment> getForDay(DateTime day) {
    return _appointments.where((a) {
      final start = DateTime(a.startDate.year, a.startDate.month, a.startDate.day);
      final end = DateTime(a.endDate.year, a.endDate.month, a.endDate.day);
      final d = DateTime(day.year, day.month, day.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    notifyListeners();
    _appointments = await DatabaseService.instance.getAppointments();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAppointment(Appointment appointment) async {
    final id =
        await DatabaseService.instance.insertAppointment(appointment);
    final newAppt = appointment.copyWith(id: id);
    _appointments.add(newAppt);
    _appointments.sort((a, b) => a.startDate.compareTo(b.startDate));
    if (newAppt.reminderTime != null) {
      await NotificationService.instance.scheduleAppointmentReminder(
        id: id,
        title: '\u{1F4C5} Upcoming: ${newAppt.title}',
        body: newAppt.location.isNotEmpty
            ? 'At ${newAppt.location}'
            : "Don't forget your appointment!",
        scheduledTime: newAppt.reminderTime!,
      );
    }
    notifyListeners();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await DatabaseService.instance.updateAppointment(appointment);
    final index =
        _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) _appointments[index] = appointment;
    if (appointment.id != null) {
      await NotificationService.instance
          .cancelAppointmentReminder(appointment.id!);
      if (appointment.reminderTime != null) {
        await NotificationService.instance.scheduleAppointmentReminder(
          id: appointment.id!,
          title: '\u{1F4C5} Upcoming: ${appointment.title}',
          body: appointment.location.isNotEmpty
              ? 'At ${appointment.location}'
              : "Don't forget your appointment!",
          scheduledTime: appointment.reminderTime!,
        );
      }
    }
    notifyListeners();
  }

  Future<void> deleteAppointment(int id) async {
    await DatabaseService.instance.deleteAppointment(id);
    await NotificationService.instance.cancelAppointmentReminder(id);
    _appointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
