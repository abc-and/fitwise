import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_streak.dart';
import 'constants/app_colors.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme.dart';
import '../notification/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class WorkoutStreakPage extends StatefulWidget {
  const WorkoutStreakPage({super.key});

  @override
  State<WorkoutStreakPage> createState() => _WorkoutStreakPageState();
}

class _WorkoutStreakPageState extends State<WorkoutStreakPage>
    with TickerProviderStateMixin {
  late WorkoutStreak _streak;
  late AnimationController _flameController;
  late AnimationController _pulseController;
  late AnimationController _badgeController;
  late AnimationController _weekFireController;
  late AnimationController _particleController;
  late AnimationController _backgroundController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _badgeScaleAnimation;
  bool _showDebugPanel = false;
  bool _isLoading = true;
  bool _showStreakBrokenMessage = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _streak = WorkoutStreak.empty();
    _initializeAnimations();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _initializeNotifications();
    await _initializeStreak();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      debugPrint('WorkoutStreakPage: Notification service initialized');
    } catch (e) {
      debugPrint('WorkoutStreakPage: Failed to initialize notifications: $e');
    }
  }

  // Helper function to get Philippine time
  DateTime _getPhilippineNow() {
    final philippineLocation = tz.getLocation('Asia/Manila');
    return tz.TZDateTime.now(philippineLocation);
  }

  Future<void> _initializeStreak() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        debugPrint("WorkoutStreakPage: No user logged in");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('streaks')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final loadedStreak = WorkoutStreak.fromMap(doc.data()!);
        
        // Check if streak is broken and reset if needed
        final updatedStreak = _checkAndUpdateStreak(loadedStreak);
        
        setState(() {
          _streak = updatedStreak;
          _isLoading = false;
        });
        
        debugPrint('WorkoutStreakPage: Loaded streak - Current: ${_streak.currentStreak}, Best: ${_streak.bestStreak}');
        
        // Check if user needs a reminder
        await _checkStreakStatus();
      } else {
        debugPrint('WorkoutStreakPage: No existing streak found for user');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('WorkoutStreakPage: Error loading streak: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check and update streak based on current date
WorkoutStreak _checkAndUpdateStreak(WorkoutStreak streak) {
  final now = _getPhilippineNow();
  final lastWorkout = streak.lastWorkout;
  
  // If never worked out, return as is
  if (lastWorkout == DateTime(1970)) return streak;
  
  // NORMALIZE DATES - Compare only calendar days, not exact times
  final normalizedNow = DateTime(now.year, now.month, now.day);
  final normalizedLastWorkout = DateTime(lastWorkout.year, lastWorkout.month, lastWorkout.day);
  
  final daysSinceLastWorkout = normalizedNow.difference(normalizedLastWorkout).inDays;
  
  debugPrint('WorkoutStreakPage: Raw last workout: $lastWorkout');
  debugPrint('WorkoutStreakPage: Normalized last workout: $normalizedLastWorkout');
  debugPrint('WorkoutStreakPage: Normalized now: $normalizedNow');
  debugPrint('WorkoutStreakPage: Calendar days since last workout: $daysSinceLastWorkout');
  
  // If streak is already 0, no need to check
  if (streak.currentStreak == 0) return streak;
  
  // If worked out today, streak continues
  if (daysSinceLastWorkout == 0) {
    debugPrint('WorkoutStreakPage: Worked out today - streak continues');
    return streak;
  }
  
  // If 1 calendar day has passed (yesterday), streak continues until end of today
  if (daysSinceLastWorkout == 1) {
    debugPrint('WorkoutStreakPage: Last workout was yesterday - streak continues until end of today');
    return streak;
  }
  
  // If 2 or more calendar days have passed, streak is broken
  if (daysSinceLastWorkout >= 2) {
    debugPrint('WorkoutStreakPage: Streak broken! $daysSinceLastWorkout calendar days since last workout');
    
    // Show non-invasive message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStreakBrokenSnackbar();
    });
    
    // Reset current streak but keep best streak
    return WorkoutStreak(
      currentStreak: 0,
      bestStreak: math.max(streak.bestStreak, streak.currentStreak),
      lastWorkout: streak.lastWorkout,
      workoutDates: streak.workoutDates,
    );
  }
  
  return streak;
}

  // Show non-invasive snackbar for broken streak
  void _showStreakBrokenSnackbar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '💔 Streak Broken',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complete ALL exercises today to start a new streak!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Got it',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _checkStreakStatus() async {
    try {
      final now = _getPhilippineNow();
      final lastWorkout = _streak.lastWorkout;
      
      debugPrint('WorkoutStreakPage: Checking streak status - Last workout: $lastWorkout, Current: ${_streak.currentStreak}');
      
      if (!_isSameDay(now, lastWorkout)) {
        final daysSinceLastWorkout = now.difference(lastWorkout).inDays;
        
        debugPrint('WorkoutStreakPage: Days since last workout: $daysSinceLastWorkout');
        
        if (daysSinceLastWorkout == 1 && _streak.currentStreak > 0) {
          debugPrint('WorkoutStreakPage: Sending streak warning notification');
          await _notificationService.sendLocalNotification(
            title: '🔥 Streak Alert!',
            body: 'Your ${_getGrammaticalDays(_streak.currentStreak)} streak is about to break! Complete your workout today.',
            type: 'streak_warning',
          );
        } else if (daysSinceLastWorkout >= 2 && _streak.currentStreak > 0) {
          debugPrint('WorkoutStreakPage: Streak has broken - sending notification');
          await _notificationService.sendLocalNotification(
            title: '💔 Streak Broken',
            body: 'Your ${_getGrammaticalDays(_streak.currentStreak)} streak has ended. Complete ALL exercises to start a new one!',
            type: 'streak_warning',
          );
        }
      } else {
        debugPrint('WorkoutStreakPage: User already worked out today');
      }
    } catch (e) {
      debugPrint('WorkoutStreakPage: Error checking streak status: $e');
    }
  }

  void _initializeAnimations() {
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _weekFireController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _badgeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );

    _badgeController.forward();
  }

bool _isSameDay(DateTime date1, DateTime date2) {
  final normalized1 = DateTime(date1.year, date1.month, date1.day);
  final normalized2 = DateTime(date2.year, date2.month, date2.day);
  return normalized1 == normalized2;
}

  String _getGrammaticalDays(int days) {
    return days == 1 ? '$days day' : '$days days';
  }

  String _getGrammaticalWorkouts(int workouts) {
    return workouts == 1 ? '$workouts workout' : '$workouts workouts';
  }

  Future<void> _setDebugStreak(int days, {bool triggerNotification = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final debugStreak = WorkoutStreak(
        currentStreak: days,
        bestStreak: days > _streak.bestStreak ? days : _streak.bestStreak,
        lastWorkout: _getPhilippineNow(),
        workoutDates: _streak.workoutDates,
      );

      await FirebaseFirestore.instance
          .collection('streaks')
          .doc(user.uid)
          .set(debugStreak.toMap());
      
      setState(() {
        _streak = debugStreak;
      });
      _showSuccessAnimation();
      
      debugPrint('WorkoutStreakPage: Debug streak set to $days days');
      
      if (triggerNotification) {
        final milestones = [3, 5, 7, 10, 15, 20, 30, 50, 75, 100, 150, 200, 365];
        if (milestones.contains(days)) {
          debugPrint('WorkoutStreakPage: Triggering milestone notification for $days');
          await _sendMilestoneNotification(days);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(triggerNotification 
                ? '✅ Streak set to ${_getGrammaticalDays(days)} + notification sent!' 
                : '✅ Streak set to ${_getGrammaticalDays(days)}'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('WorkoutStreakPage: Failed to set debug streak: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to set debug streak: $e"),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setLastWorkoutDaysAgo(int daysAgo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final lastWorkoutDate = _getPhilippineNow().subtract(Duration(days: daysAgo));
      
      final debugStreak = WorkoutStreak(
        currentStreak: _streak.currentStreak,
        bestStreak: _streak.bestStreak,
        lastWorkout: lastWorkoutDate,
        workoutDates: _streak.workoutDates,
      );

      final updatedStreak = _checkAndUpdateStreak(debugStreak);
      
      await FirebaseFirestore.instance
          .collection('streaks')
          .doc(user.uid)
          .set(updatedStreak.toMap());
      
      setState(() {
        _streak = updatedStreak;
      });
      
      debugPrint('WorkoutStreakPage: Set last workout to $daysAgo days ago ($lastWorkoutDate)');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Last workout set to ${_getGrammaticalDays(daysAgo)} ago'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('WorkoutStreakPage: Failed to set last workout date: $e');
    }
  }

  Future<void> _testAllNotifications() async {
    debugPrint('WorkoutStreakPage: Testing all notification types...');
    
    try {
      await _notificationService.sendLocalNotification(
        title: '🔔 Test: Local Notification',
        body: 'This is a basic local notification test',
        type: 'test',
      );
      await Future.delayed(const Duration(seconds: 2));
      
      await _notificationService.sendAchievement(
        title: '🏆 Test: Achievement',
        message: 'You did it! This is a test achievement notification.',
      );
      await Future.delayed(const Duration(seconds: 2));
      
      await _notificationService.sendProgressUpdate(
        '📈 Test: Progress Update - Keep going!',
      );
      await Future.delayed(const Duration(seconds: 2));
      
      await _notificationService.sendLocalNotification(
        title: '⚠️ Test: Streak Warning',
        body: 'Your streak is about to break! Complete ALL exercises to maintain it.',
        type: 'streak_warning',
      );
      
      debugPrint('WorkoutStreakPage: All test notifications sent!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ 4 test notifications sent! Check notification center.'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('WorkoutStreakPage: Error testing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _testMilestoneNotification(int milestone) async {
    debugPrint('WorkoutStreakPage: Testing milestone notification for $milestone days');
    
    try {
      await _sendMilestoneNotification(milestone);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Milestone notification sent for ${_getGrammaticalDays(milestone)}!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('WorkoutStreakPage: Error sending milestone notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendMilestoneNotification(int milestone) async {
  String title = '🔥 ${milestone} Day Streak Milestone!';
  String body = '';
  
  switch (milestone) {
    case 3:
      title = '🌟 3 Day Streak!';
      body = 'You\'re building a habit! Complete ALL exercises to keep going!';
      break;
    case 5:
      title = '🔥 5 Day Streak!';
      body = 'Fantastic! You\'re on fire! Complete ALL exercises to maintain your streak!';
      break;
    case 7:
      title = '🎯 7 Day Streak!';
      body = 'Amazing! A full week of commitment! Complete ALL exercises to continue!';
      break;
    case 10:
      title = '💪 10 Day Streak!';
      body = 'You\'re unstoppable! Double digits! Complete ALL exercises to keep it up!';
      break;
    case 15:
      title = '🏆 15 Day Streak!';
      body = '15 days straight! You\'re a fitness legend! Complete ALL exercises to continue!';
      break;
    case 20:
      title = '🔥 20 Day Streak!';
      body = '20 days! You\'re absolutely crushing it! Complete ALL exercises to maintain!';
      break;
    case 30:
      title = '🌟 30 Day Streak!';
      body = 'Incredible! 30 days of dedication! Complete ALL exercises to continue!';
      break;
    case 50:
      title = '👑 50 Day Streak!';
      body = '50 days! You\'re pure inspiration! Complete ALL exercises to keep going!';
      break;
    case 75:
      title = '💎 75 Day Streak!';
      body = '75 days! Your dedication is remarkable! Complete ALL exercises to continue!';
      break;
    case 100:
      title = '✨ 100 Day Streak!';
      body = '100 DAYS! You\'re a fitness legend! Complete ALL exercises to maintain!';
      break;
    case 150:
      title = '🚀 150 Day Streak!';
      body = '150 days! You\'re in elite territory! Complete ALL exercises to continue!';
      break;
    case 200:
      title = '👑 200 Day Streak!';
      body = '200 days! You\'re a true master! Complete ALL exercises to keep going!';
      break;
    case 365:
      title = '🎊 365 Day Streak!';
      body = 'UNBELIEVABLE! 365 days! You\'re a FITNESS GOD! Complete ALL exercises to continue!';
      break;
    default:
      title = '🔥 ${milestone} Day Streak!';
      body = '${_getGrammaticalDays(milestone)} streak! Complete ALL exercises to maintain it!';
  }
  
  debugPrint('WorkoutStreakPage: Sending milestone notification - $milestone days: $body');
  try {
    await _notificationService.sendAchievement(
      title: title,
      message: body,
    );
    debugPrint('WorkoutStreakPage: Milestone notification sent successfully');
  } catch (e) {
    debugPrint('WorkoutStreakPage: Failed to send milestone notification: $e');
  }
}

  void _showSuccessAnimation() {
    _badgeController.reset();
    _badgeController.forward();
    _weekFireController.reset();
    _weekFireController.forward();
  }

  Map<String, dynamic> _getBadgeInfo() {
    if (_streak.currentStreak >= 15) {
      return {"emoji": "🏆", "text": "Legend", "color": Colors.amber};
    }
    if (_streak.currentStreak >= 10) {
      return {"emoji": "💪", "text": "Advanced", "color": AppColors.accentPurple};
    }
    if (_streak.currentStreak >= 5) {
      return {"emoji": "🔥", "text": "Intermediate", "color": AppColors.orange};
    }
    return {"emoji": "🌱", "text": "Beginner", "color": AppColors.green};
  }

  Color _getStreakColor() {
    if (_streak.currentStreak >= 100) {
      return AppColors.accentPurple;
    } else if (_streak.currentStreak >= 50) {
      return AppColors.orange;
    } else if (_streak.currentStreak >= 20) {
      return AppColors.orange;
    } else {
      return AppColors.accentBlue;
    }
  }

  List<Color> _getBackgroundGradient(ThemeManager theme) {
    if (_streak.currentStreak >= 100) {
      return [
        AppColors.accentPurple.withOpacity(0.15),
        theme.primaryBackground,
        theme.primaryBackground,
      ];
    } else if (_streak.currentStreak >= 50) {
      return [
        AppColors.orange.withOpacity(0.15),
        theme.primaryBackground,
        theme.primaryBackground,
      ];
    } else if (_streak.currentStreak >= 20) {
      return [
        AppColors.orange.withOpacity(0.12),
        theme.primaryBackground,
        theme.secondaryBackground,
      ];
    } else {
      return [
        AppColors.accentBlue.withOpacity(0.08),
        theme.primaryBackground,
        theme.secondaryBackground,
      ];
    }
  }

  int _getParticleCount() {
    if (_streak.currentStreak >= 100) return 20;
    if (_streak.currentStreak >= 50) return 15;
    if (_streak.currentStreak >= 20) return 10;
    return 0;
  }

List<bool> _getWeeklyWorkouts() {
  List<bool> weekStatus = List.filled(7, false);
  final now = _getPhilippineNow();
  
  // Calculate start of week (Monday = 1, Sunday = 7)
  // For Sunday, we want the previous Monday
  int daysToSubtract = now.weekday == 7 ? 6 : now.weekday - 1;
  DateTime startOfWeek = now.subtract(Duration(days: daysToSubtract));
  
  // Normalize startOfWeek to midnight Philippine time
  startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  debugPrint('Weekly check - Start of week: $startOfWeek, Today: $now');

  for (var workoutDate in _streak.workoutDates) {
    // Normalize the workout date to just the date part (ignoring time)
    DateTime normalizedWorkoutDate = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);
    
    // Calculate days since start of week
    int daysDifference = normalizedWorkoutDate.difference(startOfWeek).inDays;
    
    debugPrint('Workout date: $normalizedWorkoutDate, Days difference: $daysDifference');
    
    if (daysDifference >= 0 && daysDifference < 7) {
      weekStatus[daysDifference] = true;
    }
  }

  debugPrint('Week status: $weekStatus');
  return weekStatus;
}

  String _getStreakTierText() {
    if (_streak.currentStreak >= 100) {
      return "✨ LEGENDARY TIER ✨";
    } else if (_streak.currentStreak >= 50) {
      return "👑 GOLD TIER 👑";
    } else if (_streak.currentStreak >= 20) {
      return "🔥 FIRE TIER 🔥";
    } else {
      return "🌱 GROWING STRONG 🌱";
    }
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color, ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: theme.secondaryText, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDebugButton(String label, int days, ThemeManager theme, {bool showNotificationOption = false}) {
    final isActive = _streak.currentStreak == days;
    return Material(
      color: isActive ? AppColors.accentBlue : theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _setDebugStreak(days),
        onLongPress: showNotificationOption ? () => _setDebugStreak(days, triggerNotification: true) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.accentCyan : theme.borderColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : theme.secondaryText,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (showNotificationOption)
                Text(
                  'Hold: +🔔',
                  style: TextStyle(
                    color: theme.tertiaryText,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastWorkoutButton(String label, int daysAgo, Color color, ThemeManager theme) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _setLastWorkoutDaysAgo(daysAgo),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildNotificationTestButton(String label, VoidCallback onTap, {IconData? icon, Color? color, bool isMain = false}) {
    final theme = Provider.of<ThemeManager>(context);
    final buttonColor = color ?? (isMain ? AppColors.accentBlue : theme.secondaryText);
    return Material(
      color: isMain ? AppColors.accentBlue.withOpacity(0.1) : theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: buttonColor, width: isMain ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: buttonColor),
                const SizedBox(width: 6),
              ],
              Text(
                label, 
                style: TextStyle(
                  color: buttonColor, 
                  fontSize: 13,
                  fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flameController.dispose();
    _pulseController.dispose();
    _badgeController.dispose();
    _weekFireController.dispose();
    _particleController.dispose();
    _backgroundController.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 3),
              const SizedBox(height: 20),
              Text("Loading your streak...", style: TextStyle(color: theme.secondaryText, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final badgeInfo = _getBadgeInfo();
    final weeklyWorkouts = _getWeeklyWorkouts();
    final streakColor = _getStreakColor();
    final particleCount = _getParticleCount();

    final now = _getPhilippineNow();
    final daysSinceLastWorkout = now.difference(_streak.lastWorkout).inDays;
    final lastWorkoutText = _isSameDay(now, _streak.lastWorkout) 
        ? 'Today' 
        : '$daysSinceLastWorkout ${daysSinceLastWorkout == 1 ? 'day' : 'days'} ago';

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getBackgroundGradient(theme),
                  ),
                ),
              );
            },
          ),
          
          if (particleCount > 0)
            ...List.generate(particleCount, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  final offset = (_particleController.value + (index / particleCount)) % 1.0;
                  final x = 50 + (index * 30) % MediaQuery.of(context).size.width;
                  final y = MediaQuery.of(context).size.height * offset;
                  
                  return Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: 0.25 * (1 - offset),
                      child: Icon(Icons.star, color: streakColor, size: 12 + (index % 3) * 4),
                    ),
                  );
                },
              );
            }),
          SafeArea(
            child: Column(
              children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Switch to the first tab (Home)
                          DefaultTabController.of(context).animateTo(0);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: theme.primaryText,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Workout Streak",
                      style: TextStyle(
                        color: theme.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined,
                        color: _showDebugPanel ? AppColors.accentCyan : theme.secondaryText,
                      ),
                      onPressed: () => setState(() => _showDebugPanel = !_showDebugPanel),
                      tooltip: "Debug Panel",
                    ),
                  ],
                ),
              ),
                              Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (_showDebugPanel)
                            Container(
                              margin: const EdgeInsets.only(top: 20, bottom: 10),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.accentCyan.withOpacity(0.3), width: 1),
                                boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bug_report, color: AppColors.accentCyan, size: 20),
                                      const SizedBox(width: 8),
                                      Text("DEBUG MODE", style: TextStyle(color: AppColors.accentCyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  
                                  Text("Set Streak Value:", style: TextStyle(color: theme.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text("Tap to set, Hold milestone for notification", style: TextStyle(color: theme.tertiaryText, fontSize: 11)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildDebugButton("0d", 0, theme),
                                      _buildDebugButton("3d", 3, theme, showNotificationOption: true),
                                      _buildDebugButton("5d", 5, theme, showNotificationOption: true),
                                      _buildDebugButton("7d", 7, theme, showNotificationOption: true),
                                      _buildDebugButton("10d", 10, theme, showNotificationOption: true),
                                      _buildDebugButton("15d", 15, theme, showNotificationOption: true),
                                      _buildDebugButton("20d", 20, theme, showNotificationOption: true),
                                      _buildDebugButton("30d", 30, theme, showNotificationOption: true),
                                      _buildDebugButton("50d", 50, theme, showNotificationOption: true),
                                      _buildDebugButton("75d", 75, theme, showNotificationOption: true),
                                      _buildDebugButton("100d", 100, theme, showNotificationOption: true),
                                      _buildDebugButton("150d", 150, theme, showNotificationOption: true),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  Divider(color: theme.borderColor),
                                  const SizedBox(height: 15),
                                  
                                  Text("Set Last Workout Date:", style: TextStyle(color: theme.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text("Test streak warnings", style: TextStyle(color: theme.tertiaryText, fontSize: 11)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildLastWorkoutButton('Today', 0, AppColors.green, theme),
                                      _buildLastWorkoutButton('1 day ago ⚠️', 1, AppColors.orange, theme),
                                      _buildLastWorkoutButton('2 days ago 💔', 2, Colors.red, theme),
                                      _buildLastWorkoutButton('1 week ago', 7, theme.secondaryText, theme),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  Divider(color: theme.borderColor),
                                  const SizedBox(height: 15),
                                  
                                  Text("Test Notifications:", style: TextStyle(color: theme.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildNotificationTestButton(
                                        'Test All (4)', 
                                        _testAllNotifications,
                                        icon: Icons.notifications_active,
                                        isMain: true,
                                      ),
                                      _buildNotificationTestButton(
                                        'Basic',
                                        () async {
                                          await _notificationService.sendLocalNotification(
                                            title: '🔔 Basic Test',
                                            body: 'Simple notification test',
                                            type: 'test',
                                          );
                                        },
                                      ),
                                      _buildNotificationTestButton('7-Day 🎯', () => _testMilestoneNotification(7)),
                                      _buildNotificationTestButton('30-Day 🌟', () => _testMilestoneNotification(30)),
                                      _buildNotificationTestButton('100-Day ✨', () => _testMilestoneNotification(100)),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  Divider(color: theme.borderColor),
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Current Status:", style: TextStyle(color: theme.tertiaryText, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text("Streak: ${_getGrammaticalDays(_streak.currentStreak)}", style: TextStyle(color: theme.primaryText, fontSize: 12, fontWeight: FontWeight.w600)),
                                            Text("Last: $lastWorkoutText", 
                                              style: TextStyle(color: theme.secondaryText, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _checkStreakStatus(),
                                        icon: Icon(Icons.refresh, size: 16, color: AppColors.accentCyan),
                                        label: Text("Check", style: TextStyle(color: AppColors.accentCyan, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: _flameController,
                            builder: (context, child) {
                              final intensity = _streak.currentStreak >= 50 ? 0.15 : 0.1;
                              return Transform.scale(
                                scale: 1.0 + (_flameController.value * intensity),
                                child: Transform.rotate(
                                  angle: math.sin(_flameController.value * math.pi) * 0.1,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_streak.currentStreak >= 50)
                                        Container(
                                          width: 160,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: streakColor.withOpacity(0.3), width: 3),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(colors: [streakColor.withOpacity(0.4), streakColor.withOpacity(0.0)]),
                                        ),
                                        child: Icon(Icons.local_fire_department, color: streakColor, size: 100),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [streakColor, streakColor.withOpacity(0.7)],
                                    ),
                                    boxShadow: [BoxShadow(color: streakColor.withOpacity(0.4), blurRadius: _streak.currentStreak >= 50 ? 30 : 20, offset: const Offset(0, 10))],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Column(
                                      children: [
                                        Text("Current Streak", style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500, letterSpacing: 1)),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text("${_streak.currentStreak}", style: const TextStyle(fontSize: 72, color: Colors.white, fontWeight: FontWeight.bold, height: 1)),
                                            const SizedBox(width: 8),
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Text(
                                                _streak.currentStreak == 1 ? "day" : "days",
                                                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 + (_pulseController.value * 0.05),
                                              child: Text(_getStreakTierText(), style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: streakColor.withOpacity(0.2), width: 1),
                              boxShadow: [BoxShadow(color: streakColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              children: [
                                Text("This Week's Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryText)),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: List.generate(7, (index) {
                                    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                    final isLit = weeklyWorkouts[index];
                                    return AnimatedBuilder(
                                      animation: _weekFireController,
                                      builder: (context, child) {
                                        final scale = isLit && _weekFireController.isAnimating ? 1.0 + (_weekFireController.value * 0.3) : 1.0;
                                        return Transform.scale(
                                          scale: scale,
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 45,
                                                height: 45,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isLit ? streakColor.withOpacity(0.2) : theme.primaryBackground,
                                                  border: Border.all(color: isLit ? streakColor : theme.borderColor, width: 2),
                                                  boxShadow: isLit ? [BoxShadow(color: streakColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                                                ),
                                                child: Icon(Icons.local_fire_department, color: isLit ? streakColor : theme.borderColor, size: 28),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(days[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isLit ? theme.primaryText : theme.tertiaryText)),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard("🏅", "Best Streak", _getGrammaticalDays(_streak.bestStreak), AppColors.orange, theme)),
                              const SizedBox(width: 15),
                              Expanded(child: _buildStatCard("💪", "Total Workouts", _getGrammaticalWorkouts(_streak.workoutDates.length), AppColors.accentBlue, theme)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          ScaleTransition(
                            scale: _badgeScaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: badgeInfo["color"], width: 2),
                                boxShadow: [BoxShadow(color: badgeInfo["color"].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _flameController,
                                    builder: (context, child) {
                                      if (_streak.currentStreak >= 100) {
                                        return Transform.rotate(
                                          angle: math.sin(_flameController.value * math.pi * 2) * 0.1,
                                          child: Text(badgeInfo["emoji"], style: const TextStyle(fontSize: 48)),
                                        );
                                      }
                                      return Text(badgeInfo["emoji"], style: const TextStyle(fontSize: 48));
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Text(badgeInfo["text"], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: badgeInfo["color"])),
                                  const SizedBox(height: 5),
                                  Text("Achievement Badge", style: TextStyle(fontSize: 14, color: theme.secondaryText)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.green.withOpacity(0.3), width: 2),
                              boxShadow: [BoxShadow(color: AppColors.green.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.auto_awesome, color: AppColors.green, size: 40),
                                const SizedBox(height: 12),
                                Text("Automatic Streak Tracking", 
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryText)),
                                const SizedBox(height: 8),
                                Text(
                                  "Your streak updates automatically when you complete ALL recommended exercises in your daily workout.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: theme.secondaryText, height: 1.4),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: AppColors.green, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isSameDay(now, _streak.lastWorkout) 
                                          ? "Streak updated today! 🔥"
                                          : "Complete ALL exercises to continue streak",
                                        style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}