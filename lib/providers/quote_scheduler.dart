import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../notification/notification_service.dart';
import 'package:flutter/foundation.dart';

class QuoteScheduler {
  static final QuoteScheduler _instance = QuoteScheduler._internal();
  factory QuoteScheduler() => _instance;
  QuoteScheduler._internal();

  static const int _quoteNotificationId = 1;

  // This function will be called at the scheduled time
  static void sendQuoteCallback() async {
    final notificationService = NotificationService();
    await notificationService.sendDailyMotivationalQuote();
  }

  // Schedule daily quote at a specific time (e.g., 8:00 AM)
  Future<void> scheduleDailyQuote({
    int hour = 8,
    int minute = 0,
  }) async {
    try {
      // Cancel any existing alarms
      await AndroidAlarmManager.cancel(_quoteNotificationId);

      // Schedule the alarm to repeat daily
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        _quoteNotificationId,
        sendQuoteCallback,
        startAt: _getNextScheduledTime(hour, minute),
        exact: true,
        wakeup: true,
      );

      debugPrint('Quote scheduled daily at $hour:$minute');
    } catch (e) {
      debugPrint('Error scheduling quote: $e');
    }
  }

  // Calculate next scheduled time
  static DateTime _getNextScheduledTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelDailyQuote() async {
    try {
      await AndroidAlarmManager.cancel(_quoteNotificationId);
      debugPrint('Daily quote scheduling cancelled');
    } catch (e) {
      debugPrint('Error cancelling quote schedule: $e');
    }
  }
}