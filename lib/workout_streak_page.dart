import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/workout_streak.dart';
import 'constants/app_colors.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme.dart';
import '../notification/notification_service.dart';

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
  bool _isLogging = false;
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
        setState(() {
          _streak = WorkoutStreak.fromMap(doc.data()!);
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

  Future<void> _checkStreakStatus() async {
    try {
      final now = DateTime.now();
      final lastWorkout = _streak.lastWorkout;
      
      debugPrint('WorkoutStreakPage: Checking streak status - Last workout: $lastWorkout, Current: ${_streak.currentStreak}');
      
      if (!_isSameDay(now, lastWorkout)) {
        final daysSinceLastWorkout = now.difference(lastWorkout).inDays;
        
        debugPrint('WorkoutStreakPage: Days since last workout: $daysSinceLastWorkout');
        
        if (daysSinceLastWorkout == 1 && _streak.currentStreak > 0) {
          debugPrint('WorkoutStreakPage: Sending streak warning notification');
          await _notificationService.sendLocalNotification(
            title: '🔥 Streak Alert!',
            body: 'Your ${_streak.currentStreak}-day streak is about to break! Log your workout today.',
            type: 'streak_warning',
          );
        } else if (daysSinceLastWorkout >= 2 && _streak.currentStreak > 0) {
          debugPrint('WorkoutStreakPage: Streak has broken - sending notification');
          await _notificationService.sendLocalNotification(
            title: '💔 Streak Broken',
            body: 'Your streak has ended. Start a new one today!',
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
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isConsecutiveDay(DateTime today, DateTime lastWorkout) {
    final yesterday = today.subtract(const Duration(days: 1));
    return _isSameDay(lastWorkout, yesterday);
  }

  void _logWorkout() async {
    if (_isLogging) return;

    setState(() {
      _isLogging = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Please make sure you're logged in");
      }

      final today = DateTime.now();
      final userDoc = FirebaseFirestore.instance.collection('streaks').doc(user.uid);
      
      final doc = await userDoc.get();
      
      int newStreak = 1;
      int newBestStreak = 1;
      bool isNewRecord = false;
      bool hitMilestone = false;
      int milestoneValue = 0;
      
      if (doc.exists) {
        final data = doc.data()!;
        final lastWorkout = DateTime.parse(data['lastWorkout']);
        final currentStreak = data['currentStreak'] ?? 0;
        final bestStreak = data['bestStreak'] ?? 0;
        final workoutDates = List<String>.from(data['workoutDates'] ?? []);
        
        if (_isSameDay(today, lastWorkout)) {
          throw Exception("You already logged today's workout!");
        }
        
        newStreak = _isConsecutiveDay(today, lastWorkout) ? currentStreak + 1 : 1;
        newBestStreak = newStreak > bestStreak ? newStreak : bestStreak;
        isNewRecord = newStreak > bestStreak;
        
        final milestones = [3, 5, 7, 10, 15, 20, 30, 50, 75, 100, 150, 200, 365];
        if (milestones.contains(newStreak)) {
          hitMilestone = true;
          milestoneValue = newStreak;
        }
        
        workoutDates.add(today.toIso8601String());
        
        await userDoc.update({
          'currentStreak': newStreak,
          'bestStreak': newBestStreak,
          'lastWorkout': today.toIso8601String(),
          'workoutDates': workoutDates,
        });
        
        debugPrint('WorkoutStreakPage: Workout logged - New streak: $newStreak, Best: $newBestStreak');
      } else {
        await userDoc.set({
          'currentStreak': 1,
          'bestStreak': 1,
          'lastWorkout': today.toIso8601String(),
          'workoutDates': [today.toIso8601String()],
        });
        
        debugPrint('WorkoutStreakPage: First workout logged');
        await _notificationService.sendAchievement(
          'Welcome to your fitness journey! Keep it up! 🎉',
        );
      }
      
      await _initializeStreak();
      _showSuccessAnimation();
      
      if (hitMilestone) {
        debugPrint('WorkoutStreakPage: Milestone hit: $milestoneValue');
        await _sendMilestoneNotification(milestoneValue);
      } else if (isNewRecord) {
        debugPrint('WorkoutStreakPage: New record: $newStreak');
        await _notificationService.sendAchievement(
          '🏆 New Personal Record! $newStreak-day streak!',
        );
      } else if (newStreak >= 3) {
        debugPrint('WorkoutStreakPage: Progress update: $newStreak');
        await _notificationService.sendProgressUpdate(
          '🔥 Great work! $newStreak days in a row!',
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Workout logged successfully!"),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      
    } catch (e) {
      debugPrint("WorkoutStreakPage: Log workout error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to log workout: $e"),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  Future<void> _sendMilestoneNotification(int milestone) async {
    String body = '';
    
    switch (milestone) {
      case 3:
        body = 'You\'re building a habit! Keep going! 🌟';
        break;
      case 5:
        body = 'Fantastic! You\'re on fire! 🔥';
        break;
      case 7:
        body = 'Amazing! A full week of commitment! 🎯';
        break;
      case 10:
        body = 'You\'re unstoppable! Double digits! 💪';
        break;
      case 15:
        body = '15 days straight! You\'re a fitness legend! 🏆';
        break;
      case 20:
        body = '20 days! You\'re absolutely crushing it! 🔥';
        break;
      case 30:
        body = 'Incredible! 30 days of dedication! 🌟';
        break;
      case 50:
        body = '50 days! You\'re pure inspiration! 👑';
        break;
      case 75:
        body = '75 days! Your dedication is remarkable! 💎';
        break;
      case 100:
        body = '100 DAYS! You\'re a fitness legend! ✨';
        break;
      case 150:
        body = '150 days! You\'re in elite territory! 🚀';
        break;
      case 200:
        body = '200 days! You\'re a true master! 👑';
        break;
      case 365:
        body = 'UNBELIEVABLE! 365 days! You\'re a FITNESS GOD! 🎊';
        break;
      default:
        body = '$milestone-day streak! Keep it up!';
    }
    
    debugPrint('WorkoutStreakPage: Sending milestone notification - $milestone days: $body');
    try {
      await _notificationService.sendAchievement(body);
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

  // Enhanced debug streak setter with notification trigger option
  Future<void> _setDebugStreak(int days, {bool triggerNotification = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final debugStreak = WorkoutStreak(
        currentStreak: days,
        bestStreak: days > _streak.bestStreak ? days : _streak.bestStreak,
        lastWorkout: DateTime.now(),
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
      
      // Optionally trigger a milestone notification
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
                ? '✅ Streak set to $days days + notification sent!' 
                : '✅ Streak set to $days days'),
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

  // Set last workout date to specific days ago
  Future<void> _setLastWorkoutDaysAgo(int daysAgo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final lastWorkoutDate = DateTime.now().subtract(Duration(days: daysAgo));
      
      final debugStreak = WorkoutStreak(
        currentStreak: _streak.currentStreak,
        bestStreak: _streak.bestStreak,
        lastWorkout: lastWorkoutDate,
        workoutDates: _streak.workoutDates,
      );

      await FirebaseFirestore.instance
          .collection('streaks')
          .doc(user.uid)
          .set(debugStreak.toMap());
      
      setState(() {
        _streak = debugStreak;
      });
      
      debugPrint('WorkoutStreakPage: Set last workout to $daysAgo days ago ($lastWorkoutDate)');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Last workout set to $daysAgo days ago'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('WorkoutStreakPage: Failed to set last workout date: $e');
    }
  }

  // Test all notification types
  Future<void> _testAllNotifications() async {
    debugPrint('WorkoutStreakPage: Testing all notification types...');
    
    try {
      // 1. Test local notification
      await _notificationService.sendLocalNotification(
        title: '🔔 Test: Local Notification',
        body: 'This is a basic local notification test',
        type: 'test',
      );
      await Future.delayed(const Duration(seconds: 2));
      
      // 2. Test achievement notification
      await _notificationService.sendAchievement(
        '🏆 Test: Achievement Notification - You did it!',
      );
      await Future.delayed(const Duration(seconds: 2));
      
      // 3. Test progress update
      await _notificationService.sendProgressUpdate(
        '📈 Test: Progress Update - Keep going!',
      );
      await Future.delayed(const Duration(seconds: 2));
      
      // 4. Test streak warning
      await _notificationService.sendLocalNotification(
        title: '⚠️ Test: Streak Warning',
        body: 'Your streak is about to break! This is a test.',
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

  // Test specific milestone notification
  Future<void> _testMilestoneNotification(int milestone) async {
    debugPrint('WorkoutStreakPage: Testing milestone notification for $milestone days');
    
    try {
      await _sendMilestoneNotification(milestone);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Milestone notification sent for $milestone days!'),
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
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var workoutDate in _streak.workoutDates) {
      int daysDifference = workoutDate.difference(startOfWeek).inDays;
      if (daysDifference >= 0 && daysDifference < 7) {
        weekStatus[daysDifference] = true;
      }
    }

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
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                        color: theme.primaryText,
                      ),
                      Text("Workout Streak", style: TextStyle(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined, color: _showDebugPanel ? AppColors.accentCyan : theme.secondaryText),
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
                                  
                                  // Section 1: Streak Values
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
                                  
                                  // Section 2: Last Workout Date
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
                                  
                                  // Section 3: Notification Tests
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
                                  
                                  // Section 4: Current Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Current Status:", style: TextStyle(color: theme.tertiaryText, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text("Streak: ${_streak.currentStreak} days", style: TextStyle(color: theme.primaryText, fontSize: 12, fontWeight: FontWeight.w600)),
                                            Text("Last: ${_isSameDay(DateTime.now(), _streak.lastWorkout) ? 'Today' : '${DateTime.now().difference(_streak.lastWorkout).inDays}d ago'}", 
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
                                            const Padding(
                                              padding: EdgeInsets.only(bottom: 12),
                                              child: Text("days", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500)),
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
                              Expanded(child: _buildStatCard("🏅", "Best Streak", "${_streak.bestStreak}", AppColors.orange, theme)),
                              const SizedBox(width: 15),
                              Expanded(child: _buildStatCard("💪", "Workouts", "${_streak.workoutDates.length}", AppColors.accentBlue, theme)),
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
                            width: double.infinity,
                            height: 65,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              gradient: LinearGradient(
                                colors: _streak.currentStreak >= 50 ? [streakColor, streakColor.withOpacity(0.7)] : [AppColors.accentBlue, AppColors.accentCyan],
                              ),
                              boxShadow: [BoxShadow(color: (_streak.currentStreak >= 50 ? streakColor : AppColors.accentBlue).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLogging ? null : _logWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                                disabledBackgroundColor: theme.primaryText,
                              ),
                              child: _isLogging
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.fitness_center, color: Colors.white, size: 28),
                                        SizedBox(width: 12),
                                        Text("Log Today's Workout", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                      ],
                                    ),
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