import 'package:flutter/material.dart';
import 'models/workout_streak.dart';
import 'constants/app_colors.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _streak = WorkoutStreak.empty();
    _initializeAnimations();
    _initializeStreak();
  }

  Future<void> _initializeStreak() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        print("No user logged in");
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
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading streak: $e');
      setState(() {
        _isLoading = false;
      });
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
      
      if (doc.exists) {
        final data = doc.data()!;
        final lastWorkout = DateTime.parse(data['lastWorkout']);
        final currentStreak = data['currentStreak'] ?? 0;
        final bestStreak = data['bestStreak'] ?? 0;
        final workoutDates = List<String>.from(data['workoutDates'] ?? []);
        
        if (_isSameDay(today, lastWorkout)) {
          throw Exception("You already logged today's workout!");
        }
        
        int newStreak = _isConsecutiveDay(today, lastWorkout) ? currentStreak + 1 : 1;
        int newBestStreak = newStreak > bestStreak ? newStreak : bestStreak;
        
        workoutDates.add(today.toIso8601String());
        
        await userDoc.update({
          'currentStreak': newStreak,
          'bestStreak': newBestStreak,
          'lastWorkout': today.toIso8601String(),
          'workoutDates': workoutDates,
        });
      } else {
        await userDoc.set({
          'currentStreak': 1,
          'bestStreak': 1,
          'lastWorkout': today.toIso8601String(),
          'workoutDates': [today.toIso8601String()],
        });
      }
      
      await _initializeStreak();
      _showSuccessAnimation();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Workout logged successfully!"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
    } catch (e) {
      print("Log workout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to log workout: $e"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  void _showSuccessAnimation() {
    _badgeController.reset();
    _badgeController.forward();
    _weekFireController.reset();
    _weekFireController.forward();
  }

  void _setDebugStreak(int days) async {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to set debug streak: $e"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, dynamic> _getBadgeInfo() {
    if (_streak.currentStreak >= 15) {
      return {"emoji": "🏆", "text": "Legend", "color": AppColors.warning};
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
      return AppColors.warning;
    } else if (_streak.currentStreak >= 20) {
      return AppColors.orange;
    } else {
      return AppColors.accentBlue;
    }
  }

  List<Color> _getBackgroundGradient() {
    if (_streak.currentStreak >= 100) {
      return [
        AppColors.accentPurple.withOpacity(0.15),
        AppColors.primary,
        AppColors.primary,
      ];
    } else if (_streak.currentStreak >= 50) {
      return [
        AppColors.warning.withOpacity(0.15),
        AppColors.primary,
        AppColors.primary,
      ];
    } else if (_streak.currentStreak >= 20) {
      return [
        AppColors.orange.withOpacity(0.12),
        AppColors.primary,
        AppColors.secondary,
      ];
    } else {
      return [
        AppColors.accentBlue.withOpacity(0.08),
        AppColors.primary,
        AppColors.secondary,
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

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugButton(String label, int days) {
    final isActive = _streak.currentStreak == days;
    return Material(
      color: isActive ? AppColors.accentBlue : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _setDebugStreak(days),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.accentCyan : AppColors.textTertiary,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.accentBlue,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                "Loading your streak...",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
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
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Animated Background Gradient
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getBackgroundGradient(),
                  ),
                ),
              );
            },
          ),

          // Floating Particles
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
                      child: Icon(
                        Icons.star,
                        color: streakColor,
                        size: 12 + (index % 3) * 4,
                      ),
                    ),
                  );
                },
              );
            }),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                        color: AppColors.textPrimary,
                      ),
                      const Text(
                        "Workout Streak",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined,
                          color: _showDebugPanel ? AppColors.accentCyan : AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _showDebugPanel = !_showDebugPanel;
                          });
                        },
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
                          // Debug Panel
                          if (_showDebugPanel)
                            Container(
                              margin: const EdgeInsets.only(top: 20, bottom: 10),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.accentCyan.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentCyan.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bug_report, color: AppColors.accentCyan, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "DEBUG MODE",
                                        style: TextStyle(
                                          color: AppColors.accentCyan,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    "Test Different Streak Values:",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildDebugButton("0d", 0),
                                      _buildDebugButton("3d", 3),
                                      _buildDebugButton("7d", 7),
                                      _buildDebugButton("15d", 15),
                                      _buildDebugButton("20d", 20),
                                      _buildDebugButton("30d", 30),
                                      _buildDebugButton("50d", 50),
                                      _buildDebugButton("75d", 75),
                                      _buildDebugButton("100d", 100),
                                      _buildDebugButton("150d", 150),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Current: ${_streak.currentStreak} days",
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _streak.currentStreak = 0;
                                            _streak.bestStreak = 0;
                                          });
                                        },
                                        icon: Icon(Icons.refresh, size: 16, color: AppColors.error),
                                        label: Text(
                                          "Reset",
                                          style: TextStyle(color: AppColors.error, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Animated Flame Icon
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
                                            border: Border.all(
                                              color: streakColor.withOpacity(0.3),
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              streakColor.withOpacity(0.4),
                                              streakColor.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.local_fire_department,
                                          color: streakColor,
                                          size: 100,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Main Streak Card
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
                                      colors: [
                                        streakColor,
                                        streakColor.withOpacity(0.7),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: streakColor.withOpacity(0.4),
                                        blurRadius: _streak.currentStreak >= 50 ? 30 : 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Current Streak",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${_streak.currentStreak}",
                                              style: const TextStyle(
                                                fontSize: 72,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                height: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Padding(
                                              padding: EdgeInsets.only(bottom: 12),
                                              child: Text(
                                                "days",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
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
                                              child: Text(
                                                _getStreakTierText(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
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

                          // Weekly Progress Card
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: streakColor.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: streakColor.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "This Week's Progress",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: List.generate(7, (index) {
                                    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                    final isLit = weeklyWorkouts[index];

                                    return AnimatedBuilder(
                                      animation: _weekFireController,
                                      builder: (context, child) {
                                        final scale = isLit && _weekFireController.isAnimating
                                            ? 1.0 + (_weekFireController.value * 0.3)
                                            : 1.0;

                                        return Transform.scale(
                                          scale: scale,
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 45,
                                                height: 45,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isLit
                                                      ? streakColor.withOpacity(0.2)
                                                      : AppColors.primary,
                                                  border: Border.all(
                                                    color: isLit ? streakColor : AppColors.textTertiary,
                                                    width: 2,
                                                  ),
                                                  boxShadow: isLit
                                                      ? [
                                                          BoxShadow(
                                                            color: streakColor.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Icon(
                                                  Icons.local_fire_department,
                                                  color: isLit ? streakColor : AppColors.textTertiary,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                days[index],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isLit ? AppColors.textPrimary : AppColors.textTertiary,
                                                ),
                                              ),
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

                          // Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "🏅",
                                  "Best Streak",
                                  "${_streak.bestStreak}",
                                  AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildStatCard(
                                  "💪",
                                  "Workouts",
                                  "${_streak.workoutDates.length}",
                                  AppColors.accentBlue,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Badge Card
                          ScaleTransition(
                            scale: _badgeScaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: badgeInfo["color"],
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeInfo["color"].withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _flameController,
                                    builder: (context, child) {
                                      if (_streak.currentStreak >= 100) {
                                        return Transform.rotate(
                                          angle: math.sin(_flameController.value * math.pi * 2) * 0.1,
                                          child: Text(
                                            badgeInfo["emoji"],
                                            style: const TextStyle(fontSize: 48),
                                          ),
                                        );
                                      }
                                      return Text(
                                        badgeInfo["emoji"],
                                        style: const TextStyle(fontSize: 48),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    badgeInfo["text"],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: badgeInfo["color"],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    "Achievement Badge",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Log Workout Button
                          Container(
                            width: double.infinity,
                            height: 65,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              gradient: LinearGradient(
                                colors: _streak.currentStreak >= 50
                                    ? [streakColor, streakColor.withOpacity(0.7)]
                                    : [AppColors.accentBlue, AppColors.accentCyan],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_streak.currentStreak >= 50 ? streakColor : AppColors.accentBlue)
                                      .withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLogging ? null : _logWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                disabledBackgroundColor: AppColors.textDark,
                              ),
                              child: _isLogging
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "Log Today's Workout",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
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