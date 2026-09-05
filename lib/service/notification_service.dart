import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:srbguide/data/deadline.dart';

/// Schedules the local reminders behind the deadlines screen.
///
/// Reminders are scheduled **inexactly** on purpose: exact alarms need
/// `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, which Google Play only grants to
/// alarm and calendar apps. A tax reminder that lands within an hour of 10:00
/// is just as useful and keeps the app policy-clean.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'srbguide_deadlines';
  static const String _channelName = 'Дедлайны';
  static const String _channelDescription =
      'Напоминания о визаране, ВНЖ, налогах и документах';

  /// Reminders fire at 10:00 local time on the day they are due.
  static const int _hour = 10;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Belgrade is the right guess for this audience if the lookup fails.
      tz.setLocalLocation(tz.getLocation('Europe/Belgrade'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asks for notification permission. Returns false when the user declined,
  /// so the UI can explain why nothing will arrive.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
            alert: true, badge: true, sound: true) ??
        false;
  }

  Future<bool> hasPermission() async {
    await init();
    if (!Platform.isAndroid) return true;
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  /// Rebuilds every scheduled notification from [deadlines].
  ///
  /// Cheaper to reason about than diffing: cancel everything, then re-schedule
  /// what is still enabled and still in the future.
  Future<void> reschedule(
    List<Deadline> deadlines, {
    required String Function(Deadline) title,
    required String Function(Deadline, int daysBefore) body,
  }) async {
    await init();
    await _plugin.cancelAll();

    for (final Deadline deadline in deadlines) {
      if (!deadline.enabled) continue;
      final DateTime target = deadline.nextOccurrence;

      for (final int lead in deadline.kind.defaultLeadDays) {
        final DateTime when = DateTime(
          target.year,
          target.month,
          target.day - lead,
          _hour,
        );
        if (when.isBefore(DateTime.now())) continue;

        await _schedule(
          id: _notificationId(deadline.id, lead),
          title: title(deadline),
          body: body(deadline, lead),
          when: when,
        );
      }

      // A reminder on the day itself, for the deadlines that allow same-day
      // action (paušal tax, visa run).
      final DateTime dayOf =
          DateTime(target.year, target.month, target.day, _hour);
      if (dayOf.isAfter(DateTime.now())) {
        await _schedule(
          id: _notificationId(deadline.id, 0),
          title: title(deadline),
          body: body(deadline, 0),
          when: dayOf,
        );
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // Never let a scheduling failure take the screen down with it.
      debugPrint('Failed to schedule notification $id: $e');
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Stable per-(deadline, lead) id. `hashCode` is masked into the positive
  /// 31-bit range Android accepts.
  int _notificationId(String deadlineId, int lead) =>
      ('$deadlineId#$lead').hashCode & 0x3FFFFFFF;
}
