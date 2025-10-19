import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamController<int>? _unreadCountController;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isDisposed = false;

  // Hardcoded motivational quotes for each day of the week
  final Map<int, String> _dailyQuotes = {
    0: "Monday Motivation: You're stronger than you think. Start your week with determination!",
    1: "Tuesday Triumph: Every step forward counts. Keep pushing towards your goals!",
    2: "Wednesday Wisdom: You're halfway there! Stay consistent and believe in yourself.",
    3: "Thursday Thunder: Your dedication is paying off. Don't stop now!",
    4: "Friday Fire: You've made it through the week! Celebrate your progress and keep the momentum.",
    5: "Saturday Strength: Rest and recovery are part of your journey. Honor your body today.",
    6: "Sunday Soul: Prepare your mind and spirit for the week ahead. You've got this!",
  };

  Future<void> initialize() async {
    debugPrint('NotificationService: Initializing...');
    
    if (_isDisposed) {
      debugPrint('NotificationService: Cannot initialize - service is disposed');
      return;
    }
    
    await _setupNotificationListener();
  }

  Future<void> _setupNotificationListener() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NotificationService: No user logged in');
        _safeAddToStream(0);
        return;
      }

      debugPrint('NotificationService: Setting up listener for user ${user.uid}');

      await _notificationSubscription?.cancel();
      _unreadCountController ??= StreamController<int>.broadcast();

      _notificationSubscription = _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('user_notifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen(
            (snapshot) {
              final count = snapshot.docs.length;
              debugPrint('NotificationService: Unread count updated: $count');
              _safeAddToStream(count);
            },
            onError: (error) {
              debugPrint('NotificationService: Stream error: $error');
              _safeAddErrorToStream(error);
            },
          );
    } catch (e) {
      debugPrint('NotificationService: Setup error: $e');
      _safeAddErrorToStream(e);
    }
  }

  void _safeAddToStream(int value) {
    if (!_isDisposed && _unreadCountController != null && !_unreadCountController!.isClosed) {
      _unreadCountController!.add(value);
    }
  }

  void _safeAddErrorToStream(Object error) {
    if (!_isDisposed && _unreadCountController != null && !_unreadCountController!.isClosed) {
      _unreadCountController!.addError(error);
    }
  }

 Stream<int> getUnreadCount() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(0); // Return empty stream instead of null
  }
  
  return FirebaseFirestore.instance
      .collection('notifications')
      .doc(user.uid)
      .collection('user_notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length)
      .handleError((error) {
        debugPrint('Error in getUnreadCount stream: $error');
        return 0;
      });
}

  Future<void> sendLocalNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      if (_isDisposed) {
        debugPrint('NotificationService: Cannot send notification - service is disposed');
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NotificationService: Cannot send notification - no user logged in');
        return;
      }

      debugPrint('NotificationService: Sending notification - Title: $title, Type: $type');

      final notificationData = {
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('user_notifications')
          .add(notificationData);

      debugPrint('NotificationService: Notification sent successfully');
    } catch (e) {
      debugPrint('NotificationService: Error sending notification: $e');
    }
  }

  // UPDATED: Simple achievement method with just message (backward compatible)
  Future<void> sendAchievement({
    required String title,
    required String message,
  }) async {
    await sendLocalNotification(
      title: title,
      body: message,
      type: 'achievement',
    );
  }

  Future<void> sendProgressUpdate(String message) async {
    await sendLocalNotification(
      title: '📊 Progress Update',
      body: message,
      type: 'progress',
    );
  }

  Future<void> sendDailyMotivationalQuote() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dayOfWeek = DateTime.now().weekday - 1;
      final quote = _dailyQuotes[dayOfWeek] ?? 'Keep pushing towards your goals!';

      await sendLocalNotification(
        title: '💪 Daily Motivation',
        body: quote,
        type: 'motivational_quote',
      );

      debugPrint('NotificationService: Sent motivational quote for day $dayOfWeek');
    } catch (e) {
      debugPrint('NotificationService: Error sending motivational quote: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('user_notifications')
          .doc(notificationId)
          .update({'read': true});

      debugPrint('NotificationService: Marked notification as read: $notificationId');
    } catch (e) {
      debugPrint('NotificationService: Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('user_notifications')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      debugPrint('NotificationService: Marked all notifications as read');
    } catch (e) {
      debugPrint('NotificationService: Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('user_notifications')
          .doc(notificationId)
          .delete();

      debugPrint('NotificationService: Deleted notification: $notificationId');
    } catch (e) {
      debugPrint('NotificationService: Error deleting notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NotificationService: No user for getAllNotifications');
        return [];
      }

      final snapshot = await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('user_notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      debugPrint('NotificationService: Fetched ${snapshot.docs.length} notifications');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('NotificationService: Error getting notifications: $e');
      return [];
    }
  }

  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    
    if (_unreadCountController != null && !_unreadCountController!.isClosed) {
      _unreadCountController!.close();
    }
    _unreadCountController = null;
    
    debugPrint('NotificationService: Disposed successfully');
  }
}