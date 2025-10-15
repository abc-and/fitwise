import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserInitializationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize all necessary collections for a new user
  Future<void> initializeUserCollections(String userId) async {
    try {
      debugPrint('UserInit: Initializing collections for user $userId');

      // Initialize notifications collection with a welcome notification
      await _initializeNotifications(userId);

      // Initialize streaks collection
      await _initializeStreaks(userId);

      // Initialize user_info if not exists
      await _initializeUserInfo(userId);

      debugPrint('UserInit: Successfully initialized all collections');
    } catch (e) {
      debugPrint('UserInit: Error initializing collections: $e');
      rethrow;
    }
  }

  /// Initialize notifications collection with welcome notification
  Future<void> _initializeNotifications(String userId) async {
    try {
      // Create the parent document first
      final notificationDoc = _firestore.collection('notifications').doc(userId);
      
      // Check if it exists
      final docSnapshot = await notificationDoc.get();
      if (!docSnapshot.exists) {
        // Create parent document
        await notificationDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        debugPrint('UserInit: Created notifications parent document');
      }

      // Add a welcome notification in the subcollection
      await notificationDoc.collection('user_notifications').add({
        'title': '👋 Welcome to FitWise!',
        'body': 'Start your fitness journey today. Track your progress, log workouts, and achieve your goals!',
        'type': 'welcome',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('UserInit: Created welcome notification');
    } catch (e) {
      debugPrint('UserInit: Error initializing notifications: $e');
      // Don't rethrow - notifications are not critical for account creation
    }
  }

  /// Initialize streaks collection
  Future<void> _initializeStreaks(String userId) async {
    try {
      final streakDoc = _firestore.collection('streaks').doc(userId);
      final docSnapshot = await streakDoc.get();

      if (!docSnapshot.exists) {
        await streakDoc.set({
          'currentStreak': 0,
          'bestStreak': 0,
          'lastWorkout': DateTime.now().toIso8601String(),
          'workoutDates': [],
        });
        debugPrint('UserInit: Created streaks document');
      }
    } catch (e) {
      debugPrint('UserInit: Error initializing streaks: $e');
    }
  }

  /// Initialize user_info if it doesn't exist
  Future<void> _initializeUserInfo(String userId) async {
    try {
      final userInfoDoc = _firestore.collection('user_info').doc(userId);
      final docSnapshot = await userInfoDoc.get();

      if (!docSnapshot.exists) {
        await userInfoDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
          // Add default values if needed
        });
        debugPrint('UserInit: Created user_info document');
      }
    } catch (e) {
      debugPrint('UserInit: Error initializing user_info: $e');
    }
  }

  /// Check and initialize collections for existing user on login
  Future<void> ensureCollectionsExist() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('UserInit: No user logged in');
        return;
      }

      // Check if notifications collection exists
      final notificationDoc = await _firestore
          .collection('notifications')
          .doc(user.uid)
          .get();

      if (!notificationDoc.exists) {
        debugPrint('UserInit: Notifications collection missing, initializing...');
        await initializeUserCollections(user.uid);
      } else {
        debugPrint('UserInit: All collections exist');
      }
    } catch (e) {
      debugPrint('UserInit: Error checking collections: $e');
    }
  }

  /// Send initial tips notification
  Future<void> sendInitialTips(String userId) async {
    try {
      final tips = [
        {
          'title': '💡 Tip: Track Your Progress',
          'body': 'Regular weigh-ins help you stay on track. Update your weight weekly!',
          'type': 'tip',
        },
        {
          'title': '🔥 Tip: Build Your Streak',
          'body': 'Consistency is key! Try to work out at least 3 times a week.',
          'type': 'tip',
        },
        {
          'title': '🍎 Tip: Log Your Meals',
          'body': 'Keep track of your calories to reach your goals faster!',
          'type': 'tip',
        },
      ];

      final batch = _firestore.batch();
      final notificationCollection = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications');

      for (var tip in tips) {
        batch.set(notificationCollection.doc(), {
          ...tip,
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      debugPrint('UserInit: Sent initial tips notifications');
    } catch (e) {
      debugPrint('UserInit: Error sending initial tips: $e');
    }
  }
}