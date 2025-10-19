// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme.dart';
import '../constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _workoutReminders = true;
  bool _achievements = true;
  bool _motivationalQuotes = false;
  bool _pushNotifications = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _loading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final doc = await _firestore
          .collection('user_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _workoutReminders = data['workoutReminders'] ?? true;
            _achievements = data['achievements'] ?? true;
            _motivationalQuotes = data['motivationalQuotes'] ?? false;
            _pushNotifications = data['pushNotifications'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_settings').doc(user.uid).set({
        'workoutReminders': _workoutReminders,
        'achievements': _achievements,
        'motivationalQuotes': _motivationalQuotes,
        'pushNotifications': _pushNotifications,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.cardColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: theme.cardColor, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader(theme, "Notification Types", Icons.notifications_active),
                _buildSwitchTile(
                  theme,
                  "Workout Reminders",
                  "Get reminded about your scheduled workouts",
                  _workoutReminders,
                  (val) {
                    setState(() => _workoutReminders = val);
                    _saveNotificationSettings();
                  },
                ),
                _buildSwitchTile(
                  theme,
                  "Achievements",
                  "Celebrate your milestones and achievements",
                  _achievements,
                  (val) {
                    setState(() => _achievements = val);
                    _saveNotificationSettings();
                  },
                ),
                _buildSwitchTile(
                  theme,
                  "Motivational Quotes",
                  "Daily motivation to keep you going",
                  _motivationalQuotes,
                  (val) {
                    setState(() => _motivationalQuotes = val);
                    _saveNotificationSettings();
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(theme, "Delivery Methods", Icons.send),
                _buildSwitchTile(
                  theme,
                  "Push Notifications",
                  "Receive push notifications on your device",
                  _pushNotifications,
                  (val) {
                    setState(() => _pushNotifications = val);
                    _saveNotificationSettings();
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(ThemeManager theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeManager theme,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: theme.secondaryText,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accentBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}