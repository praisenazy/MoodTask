import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  static Future<void> scheduleTaskReminder({
    required int id,
    required String taskTitle,
    required DateTime scheduledTime,
    required String mood,
  }) async {
    String moodEmoji = _getMoodEmoji(mood);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '$moodEmoji Task Reminder',
      taskTitle,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'tired':
        return '😴';
      case 'focused':
        return '😤';
      case 'productive':
        return '🎯';
      case 'calm':
        return '😌';
      case 'motivated':
        return '🔥';
      default:
        return '📝';
    }
  }
}
