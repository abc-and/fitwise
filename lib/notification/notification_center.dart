import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme.dart';
import '../constants/app_colors.dart';
import 'notification_service.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getAllNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'progress':
        return Icons.trending_up;
      case 'streak_warning':
        return Icons.warning_amber;
      case 'test':
        return Icons.bug_report;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'achievement':
        return AppColors.accentPurple;
      case 'progress':
        return AppColors.accentBlue;
      case 'streak_warning':
        return AppColors.orange;
      case 'test':
        return AppColors.accentCyan;
      default:
        return AppColors.accentBlue;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp == null) {
        return 'Just now';
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        // Firestore Timestamp
        date = timestamp.toDate();
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: theme.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_notifications.any((n) => n['read'] == false))
            TextButton.icon(
              onPressed: () async {
                await _notificationService.markAllAsRead();
                _loadNotifications();
              },
              icon: Icon(Icons.done_all, color: AppColors.accentBlue, size: 18),
              label: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accentBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Loading notifications...',
                    style: TextStyle(color: theme.secondaryText),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.borderColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_off_outlined,
                          size: 80,
                          color: theme.tertiaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see updates here when they arrive',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppColors.accentBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['read'] == true;
                      final type = notification['type']?.toString() ?? 'default';
                      final color = _getNotificationColor(type);

                      return Dismissible(
                        key: Key(notification['id'] ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) async {
                          await _notificationService.deleteNotification(
                            notification['id'],
                          );
                          _loadNotifications();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead
                                ? theme.cardColor
                                : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? theme.borderColor.withOpacity(0.3)
                                  : color.withOpacity(0.3),
                              width: isRead ? 1 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRead
                                    ? theme.shadowColor
                                    : color.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                if (!isRead) {
                                  await _notificationService.markAsRead(
                                    notification['id'],
                                  );
                                  _loadNotifications();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color,
                                            color.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _getNotificationIcon(type),
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification['title'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.bold,
                                                    color: theme.primaryText,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notification['body'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: theme.secondaryText,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatTimestamp(
                                                notification['timestamp'] ??
                                                    notification['createdAt']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.tertiaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}