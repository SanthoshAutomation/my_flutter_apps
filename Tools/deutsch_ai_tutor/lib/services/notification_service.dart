import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> scheduleDailyReminder({
    int hour = 9,
    int minute = 0,
  }) async {
    await _plugin.cancelAll();

    final messages = [
      ('Zeit für Deutsch! 🇩🇪', 'Your German lesson is waiting. Keep that streak alive!'),
      ('Guten Morgen! ☀️', 'Start your day with German. Just 10 minutes makes a difference!'),
      ('Du schaffst das! 💪', 'Your German journey continues today. Don\'t break the streak!'),
      ('Learning time! 📚', 'New German lesson ready. Your future self will thank you!'),
    ];

    for (var i = 0; i < messages.length; i++) {
      final (title, body) = messages[i % messages.length];
      await _plugin.zonedSchedule(
        i,
        title,
        body,
        _nextInstanceOfTime(hour, minute, daysOffset: i),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'deutsch_meister_daily',
            'Daily German Reminder',
            channelDescription: 'Daily reminder to practice German',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute,
      {int daysOffset = 0}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysOffset,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> showStreakNotification(int streak) async {
    await _plugin.show(
      100,
      '🔥 $streak Day Streak!',
      'Unglaublich! You\'re on fire! Keep going, champion!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'deutsch_meister_achievements',
          'Achievements',
          channelDescription: 'Achievement notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
