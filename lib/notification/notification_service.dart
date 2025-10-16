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

  // Stream controller for unread count
  final StreamController<int> _unreadCountController = StreamController<int>.broadcast();
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  Future<void> initialize() async {
    debugPrint('NotificationService: Initializing...');
    await _setupNotificationListener();
  }

  Future<void> _setupNotificationListener() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NotificationService: No user logged in');
        _unreadCountController.add(0);
        return;
      }

      debugPrint('NotificationService: Setting up listener for user ${user.uid}');

      // Cancel existing subscription if any
      await _notificationSubscription?.cancel();

      // Listen to notifications collection
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
              _unreadCountController.add(count);
            },
            onError: (error) {
              debugPrint('NotificationService: Stream error: $error');
              _unreadCountController.addError(error);
            },
          );
    } catch (e) {
      debugPrint('NotificationService: Setup error: $e');
      _unreadCountController.addError(e);
    }
  }

  Stream<int> getUnreadCount() {
    debugPrint('NotificationService: getUnreadCount() called');
    
    // Ensure listener is set up
    if (_notificationSubscription == null) {
      _setupNotificationListener();
    }
    
    return _unreadCountController.stream;
  }

  Future<void> sendLocalNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
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

      // Add to Firestore
      await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('user_notifications')
          .add(notificationData);

      debugPrint('NotificationService: Notification sent successfully');
    } catch (e) {
      debugPrint('NotificationService: Error sending notification: $e');
      rethrow;
    }
  }

  Future<void> sendAchievement(String message) async {
    await sendLocalNotification(
      title: '🎉 Achievement Unlocked!',
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
    _notificationSubscription?.cancel();
    _unreadCountController.close();
  }
}