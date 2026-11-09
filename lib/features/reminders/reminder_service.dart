import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'noteon_reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDesc =
      'Notifications for scheduled tasks and note reminders';

  static const String _agendaChannelId = 'noteon_agenda';
  static const String _agendaChannelName = 'Daily Agenda';
  static const String _agendaChannelDesc =
      'Daily morning overview of your scheduled tasks';

  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationResponse,
  }) async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open NoteOn',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _backgroundNotificationHandler,
    );

    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _backgroundNotificationHandler(NotificationResponse response) {
    // Handle background actions like snooze or complete
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final notifGranted = await androidImplementation
            .requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
        return notifGranted ?? false;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime remindAt,
    String? body,
  }) async {
    if (remindAt.isBefore(DateTime.now())) return;

    final id = taskId.hashCode.abs() % 100000;
    final scheduledDate = tz.TZDateTime.from(remindAt, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      actions: const [
        AndroidNotificationAction(
          'action_complete',
          'Complete',
          showsUserInterface: true,
        ),
        AndroidNotificationAction('action_snooze_10m', 'Snooze 10m'),
        AndroidNotificationAction('action_snooze_1h', 'Snooze 1h'),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'TASK_REMINDER',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body ?? 'Task is due now',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task:$taskId',
      );
    } catch (_) {
      // Fallback if exact alarms permission is not granted on older/restricted device
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body ?? 'Task is due now',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'task:$taskId',
      );
    }
  }

  Future<void> scheduleNoteReminder({
    required String noteId,
    required String title,
    required DateTime remindAt,
  }) async {
    if (remindAt.isBefore(DateTime.now())) return;

    final id = (noteId.hashCode.abs() % 100000) + 100000;
    final scheduledDate = tz.TZDateTime.from(remindAt, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Note Reminder: $title',
        body: 'Tap to view note',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'note:$noteId',
      );
    } catch (_) {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: 'Note Reminder: $title',
        body: 'Tap to view note',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'note:$noteId',
      );
    }
  }

  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> scheduleDailyAgenda({
    required int hour,
    required int minute,
    required int taskCount,
  }) async {
    const id = 999999;
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _agendaChannelId,
      _agendaChannelName,
      channelDescription: _agendaChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: 'Good morning! ☀️',
      body: 'You have $taskCount tasks scheduled for today.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'agenda:daily',
    );
  }

  Future<void> cancelDailyAgenda() async {
    await _notificationsPlugin.cancel(id: 999999);
  }
}
