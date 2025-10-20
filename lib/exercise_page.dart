import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../constants/app_colors.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  // --- all 25 exercises ---
  final List<Exercise> allExercises = [
    Exercise(name: "Burpee", type: "Cardio", duration: 30, sets: 3, reps: 15, difficulty: "Hard"),
    Exercise(name: "Push Up", type: "Strength", duration: 20, sets: 3, reps: 12, difficulty: "Medium"),
    Exercise(name: "Squat", type: "Legs", duration: 25, sets: 3, reps: 20, difficulty: "Easy"),
    Exercise(name: "Plank", type: "Core", duration: 40, sets: 2, reps: 1, difficulty: "Hard"),
    Exercise(name: "Jumping Jack", type: "Cardio", duration: 20, sets: 2, reps: 20, difficulty: "Easy"),
    Exercise(name: "Lunge", type: "Legs", duration: 25, sets: 3, reps: 15, difficulty: "Medium"),
    Exercise(name: "Mountain Climber", type: "Cardio", duration: 30, sets: 3, reps: 20, difficulty: "Medium"),
    Exercise(name: "Bicep Curl", type: "Strength", duration: 20, sets: 3, reps: 12, difficulty: "Easy"),
    Exercise(name: "Russian Twist", type: "Core", duration: 30, sets: 3, reps: 20, difficulty: "Medium"),
    Exercise(name: "High Knee", type: "Cardio", duration: 25, sets: 3, reps: 30, difficulty: "Easy"),
    Exercise(name: "Diamond Push Up", type: "Strength", duration: 25, sets: 3, reps: 10, difficulty: "Hard"),
    Exercise(name: "Bulgarian Squat", type: "Legs", duration: 30, sets: 3, reps: 12, difficulty: "Hard"),
    Exercise(name: "Bicycle Crunch", type: "Core", duration: 30, sets: 3, reps: 20, difficulty: "Medium"),
    Exercise(name: "Box Jump", type: "Legs", duration: 30, sets: 3, reps: 10, difficulty: "Hard"),
    Exercise(name: "Dip", type: "Strength", duration: 25, sets: 3, reps: 12, difficulty: "Medium"),
    Exercise(name: "Jump Rope", type: "Cardio", duration: 45, sets: 3, reps: 50, difficulty: "Easy"),
    Exercise(name: "Leg Raise", type: "Core", duration: 25, sets: 3, reps: 15, difficulty: "Medium"),
    Exercise(name: "Calf Raise", type: "Legs", duration: 20, sets: 4, reps: 20, difficulty: "Easy"),
    Exercise(name: "Shoulder Press", type: "Strength", duration: 25, sets: 3, reps: 12, difficulty: "Medium"),
    Exercise(name: "Sprint Interval", type: "Cardio", duration: 20, sets: 5, reps: 1, difficulty: "Hard"),
    Exercise(name: "Side Plank", type: "Core", duration: 30, sets: 3, reps: 2, difficulty: "Medium"),
    Exercise(name: "Wall Sit", type: "Legs", duration: 45, sets: 3, reps: 1, difficulty: "Medium"),
    Exercise(name: "Curl Ups", type: "Strength", duration: 25, sets: 3, reps: 8, difficulty: "Hard"),
    Exercise(name: "Butt Kick", type: "Cardio", duration: 25, sets: 3, reps: 30, difficulty: "Easy"),
  ];

  bool loadingUser = true;
  Map<String, dynamic>? userInfo;
  List<Exercise> recommended = [];
  List<Exercise> customExercises = [];
  String selectedFilter = "All";
  bool workoutCompleted = false;

  final Map<String, Map<String, dynamic>> typeStyles = {
    "Cardio": {"icon": Icons.favorite, "color": AppColors.orange},
    "Strength": {"icon": Icons.fitness_center, "color": AppColors.accentBlue},
    "Legs": {"icon": Icons.directions_run, "color": AppColors.accentPurple},
    "Core": {"icon": Icons.accessibility_new, "color": AppColors.accentCyan},
  };

  @override
  void initState() {
    super.initState();
    _loadUserInfoAndPrepareRecommendations();
    _checkIfWorkoutCompletedToday();
    _loadCustomExercises();
  }

        Future<void> _loadCustomExercises() async {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            final doc = await FirebaseFirestore.instance  
                .collection('user_custom_exercises')
                .doc(user.uid)
                .get();

            if (doc.exists && doc.data() != null) {
              final exercisesData = doc.data()!['exercises'] as List<dynamic>? ?? [];
              setState(() {
                customExercises = exercisesData.map((data) {
                  return Exercise.fromMap(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
                }).toList();
              });
            }
          } catch (e) {
            debugPrint("Error loading custom exercises: $e");
          }
        }

        Future<void> _saveCustomExercises() async {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            await FirebaseFirestore.instance
                .collection('user_custom_exercises')
                .doc(user.uid)
                .set({
                  'exercises': customExercises.map((ex) => ex.toMap()).toList(),
                  'lastUpdated': DateTime.now().toIso8601String(),
                });
          } catch (e) {
            debugPrint("Error saving custom exercises: $e");
          }
        }

        void _addCustomExercise(Exercise exercise) {
          setState(() {
            customExercises.add(exercise);
          });
          _saveCustomExercises();
        }

        void _removeCustomExercise(int index) {
          setState(() {
            customExercises.removeAt(index);
          });
          _saveCustomExercises();
        }

        void _updateCustomExerciseSets(int index, int newSets) {
          setState(() {
            customExercises[index] = customExercises[index].copyWith(sets: newSets);
          });
          _saveCustomExercises();
        }



  Future<void> _loadUserInfoAndPrepareRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          loadingUser = false;
          recommended = allExercises.take(7).toList();
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('user_info').doc(user.uid).get();
      if (!doc.exists) {
        setState(() {
          loadingUser = false;
          recommended = allExercises.take(7).toList();
        });
        return;
      }

      userInfo = Map<String, dynamic>.from(doc.data() ?? {});
      final pool = _computePoolFromUserInfo(userInfo!);
      recommended = _dailyPick(pool, FirebaseAuth.instance.currentUser!.uid, count: min(7, pool.length));
    } catch (e) {
      debugPrint("Error preparing recommendations: $e");
      recommended = allExercises.take(7).toList();
    } finally {
      setState(() => loadingUser = false);
    }
  }

  // NEW METHOD: Check if user already worked out today
  Future<void> _checkIfWorkoutCompletedToday() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('streaks')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        DateTime lastWorkout;
        
        // Handle both Timestamp and String formats
        if (data['lastWorkout'] is Timestamp) {
          lastWorkout = (data['lastWorkout'] as Timestamp).toDate();
        } else if (data['lastWorkout'] is String) {
          lastWorkout = DateTime.parse(data['lastWorkout'] as String);
        } else {
          debugPrint('❌ Unknown lastWorkout format: ${data['lastWorkout']}');
          return;
        }
        
        final today = DateTime.now();
        
        if (_isSameDay(today, lastWorkout)) {
          setState(() {
            workoutCompleted = true;
          });
          debugPrint('✅ User already worked out today - marking as completed');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking workout status: $e');
    }
  }
  List<Exercise> _computePoolFromUserInfo(Map<String, dynamic> info) {
    final int age = (info['age'] is int) ? info['age'] as int : int.tryParse('${info['age']}') ?? 30;
    final String sex = (info['sex'] ?? '').toString().toLowerCase();
    final String activityLevel = (info['activityLevel'] ?? '').toString().toLowerCase();
    final String targetGoal = (info['targetGoal'] ?? info['goal'] ?? '').toString().toLowerCase();
    final String reproductiveStatus = (info['reproductiveStatus'] ?? '').toString().toLowerCase();
    final String otherConditions = (info['otherConditions'] ?? '').toString().toLowerCase();
    final String dietaryRestrictions = (info['dietaryRestrictions'] ?? '').toString().toLowerCase();
    final String allergies = (info['allergies'] ?? '').toString().toLowerCase();

    List<Exercise> pool = List<Exercise>.from(allExercises);

    // 1) Target Goal
    if (targetGoal.contains("weight loss") || targetGoal.contains("lose")) {
      pool = pool.where((e) => e.type.toLowerCase() == "cardio" || e.type.toLowerCase() == "core").toList();
    } else if (targetGoal.contains("weight gain") || targetGoal.contains("gain")) {
      pool = pool.where((e) => e.type.toLowerCase() == "strength" || e.type.toLowerCase() == "legs").toList();
    }

    // 2) Age: remove hard if age >= 50
    if (age >= 50) {
      pool = pool.where((e) => e.difficulty.toLowerCase() != "hard").toList();
    }

    // 3) Activity level -> map allowed difficulties
    final Set<String> allowed = {};
    switch (activityLevel) {
      case "sedentary":
        allowed.addAll(["easy"]);
        break;
      case "lightly active":
        allowed.addAll(["easy", "medium"]);
        break;
      case "moderately active":
        allowed.addAll(["medium"]);
        break;
      case "very active":
        allowed.addAll(["medium", "hard"]);
        break;
      case "extra active":
        allowed.addAll(["easy", "medium", "hard"]);
        break;
      default:
        allowed.addAll(["easy", "medium", "hard"]);
    }
    pool = pool.where((e) => allowed.contains(e.difficulty.toLowerCase())).toList();

    // 4) Reproductive status (pregnancy)
    final bool isPregnant = reproductiveStatus.contains("pregnant") || reproductiveStatus.contains("expecting") || reproductiveStatus.contains("pregnancy");
    if (isPregnant) {
      final blockedForPregnancy = {
        "burpee", "plank", "box jump", "mountain climber", "jump rope", "sprint interval", "bicycle crunch", "high knee", "butt kick"
      };
      pool = pool.where((e) => !blockedForPregnancy.contains(e.name.toLowerCase())).toList();
    }

    // 5) Other conditions
    final cond = otherConditions;
    if (cond.contains("hypertension") || cond.contains("high blood pressure") || cond.contains("heart")) {
      final blocked = {"burpee", "sprint interval", "jump rope", "high knee", "box jump"};
      pool = pool.where((e) => !blocked.contains(e.name.toLowerCase())).toList();
    }
    if (cond.contains("knee") || cond.contains("arthritis")) {
      final blocked = {"squat", "lunge", "bulgarian squat", "box jump"};
      pool = pool.where((e) => !blocked.contains(e.name.toLowerCase())).toList();
    }
    if (cond.contains("back") || cond.contains("lower back") || cond.contains("sciatica")) {
      final blocked = {"plank", "russian twist", "leg raise", "bicycle crunch"};
      pool = pool.where((e) => !blocked.contains(e.name.toLowerCase())).toList();
    }
    if (cond.contains("asthma") || cond.contains("low stamina")) {
      final blocked = {"sprint interval", "burpee", "jump rope"};
      pool = pool.where((e) => !blocked.contains(e.name.toLowerCase())).toList();
    }

    // final ordering preference by goal
    if (targetGoal.contains("weight gain")) {
      pool.sort((a, b) {
        final aPref = (a.type.toLowerCase() == "strength" || a.type.toLowerCase() == "legs") ? 0 : 1;
        final bPref = (b.type.toLowerCase() == "strength" || b.type.toLowerCase() == "legs") ? 0 : 1;
        return aPref.compareTo(bPref);
      });
    } else if (targetGoal.contains("weight loss")) {
      pool.sort((a, b) {
        final aPref = (a.type.toLowerCase() == "cardio" || a.type.toLowerCase() == "core") ? 0 : 1;
        final bPref = (b.type.toLowerCase() == "cardio" || b.type.toLowerCase() == "core") ? 0 : 1;
        return aPref.compareTo(bPref);
      });
    }

    return pool;
  }

  List<Exercise> _dailyPick(List<Exercise> pool, String uid, {int count = 7}) {
    if (pool.isEmpty) return [];
    final now = DateTime.now();
    final int seed = uid.hashCode.abs() + now.year * 10000 + now.month * 100 + now.day;
    final rnd = Random(seed);
    final poolCopy = List<Exercise>.from(pool);
    for (int i = poolCopy.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = poolCopy[i];
      poolCopy[i] = poolCopy[j];
      poolCopy[j] = tmp;
    }
    return poolCopy.take(count).toList();
  }

  List<Exercise> _getFilteredRecommendedExercises() {
    List<Exercise> combined = [...recommended, ...customExercises];
    
    if (selectedFilter == "All") {
      return combined;
    }
    return combined
        .where((e) => e.type == selectedFilter)
        .toList();
  }

  // Check if exercise is suitable for user
  List<String> _getExerciseWarnings(Exercise exercise) {
    if (userInfo == null) return [];

    List<String> warnings = [];
    final int age = (userInfo!['age'] is int) ? userInfo!['age'] as int : int.tryParse('${userInfo!['age']}') ?? 30;
    final String activityLevel = (userInfo!['activityLevel'] ?? '').toString().toLowerCase();
    final String reproductiveStatus = (userInfo!['reproductiveStatus'] ?? '').toString().toLowerCase();
    final String otherConditions = (userInfo!['otherConditions'] ?? '').toString().toLowerCase();

    // Age restrictions
    if (age >= 50 && exercise.difficulty.toLowerCase() == "hard") {
      warnings.add("Not recommended for age 50+");
    }

    // Activity level restrictions
    final Set<String> allowed = {};
    switch (activityLevel) {
      case "sedentary":
        allowed.addAll(["easy"]);
        break;
      case "lightly active":
        allowed.addAll(["easy", "medium"]);
        break;
      case "moderately active":
        allowed.addAll(["medium"]);
        break;
      case "very active":
        allowed.addAll(["medium", "hard"]);
        break;
      case "extra active":
        allowed.addAll(["easy", "medium", "hard"]);
        break;
      default:
        allowed.addAll(["easy", "medium", "hard"]);
    }

    if (!allowed.contains(exercise.difficulty.toLowerCase())) {
      warnings.add("May be too difficult for your activity level");
    }

    // Pregnancy restrictions
    final bool isPregnant = reproductiveStatus.contains("pregnant") || reproductiveStatus.contains("expecting") || reproductiveStatus.contains("pregnancy");
    if (isPregnant) {
      final blockedForPregnancy = {
        "burpee", "plank", "box jump", "mountain climber", "jump rope", "sprint interval", "bicycle crunch", "high knee", "butt kick"
      };
      if (blockedForPregnancy.contains(exercise.name.toLowerCase())) {
        warnings.add("Not recommended during pregnancy");
      }
    }

    // Health condition restrictions
    final cond = otherConditions;
    if (cond.contains("hypertension") || cond.contains("high blood pressure") || cond.contains("heart")) {
      final blocked = {"burpee", "sprint interval", "jump rope", "high knee", "box jump"};
      if (blocked.contains(exercise.name.toLowerCase())) {
        warnings.add("Not recommended with heart conditions");
      }
    }
    if (cond.contains("knee") || cond.contains("arthritis")) {
      final blocked = {"squat", "lunge", "bulgarian squat", "box jump"};
      if (blocked.contains(exercise.name.toLowerCase())) {
        warnings.add("Not recommended with knee issues");
      }
    }
    if (cond.contains("back") || cond.contains("lower back") || cond.contains("sciatica")) {
      final blocked = {"plank", "russian twist", "leg raise", "bicycle crunch"};
      if (blocked.contains(exercise.name.toLowerCase())) {
        warnings.add("Not recommended with back issues");
      }
    }
    if (cond.contains("asthma") || cond.contains("low stamina")) {
      final blocked = {"sprint interval", "burpee", "jump rope"};
      if (blocked.contains(exercise.name.toLowerCase())) {
        warnings.add("Not recommended with breathing issues");
      }
    }

    return warnings;
  }

  // Callback function to update workout completion status
  void _onWorkoutCompleted(bool isCompleted, int completedExercises, int totalExercises) {
    setState(() {
      workoutCompleted = isCompleted;
    });
    
    // Automatically log streak if ALL exercises were completed (not skipped)
    if (isCompleted && completedExercises == totalExercises) {
      _logStreakAutomatically();
    }
  }

  // Automatically log streak to Firebase
    Future<void> _logStreakAutomatically() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

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
          
          // Handle both Timestamp and String formats for lastWorkout
          DateTime lastWorkout;
          if (data['lastWorkout'] is Timestamp) {
            lastWorkout = (data['lastWorkout'] as Timestamp).toDate();
          } else if (data['lastWorkout'] is String) {
            lastWorkout = DateTime.parse(data['lastWorkout'] as String);
          } else {
            // If no valid lastWorkout, treat as first workout
            lastWorkout = DateTime.now().subtract(const Duration(days: 2));
          }
          
          final currentStreak = data['currentStreak'] ?? 0;
          final bestStreak = data['bestStreak'] ?? 0;
          final workoutDates = List<String>.from(data['workoutDates'] ?? []);
          
          // Check if already logged today
          if (_isSameDay(today, lastWorkout)) {
            debugPrint('Streak already logged for today');
            return;
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
            'lastWorkout': today.toIso8601String(), // Store as string for consistency
            'workoutDates': workoutDates,
          });
          
          debugPrint('✅ Workout streak automatically logged - New streak: $newStreak, Best: $newBestStreak');
        } else {
          // First workout
          await userDoc.set({
            'currentStreak': 1,
            'bestStreak': 1,
            'lastWorkout': today.toIso8601String(), // Store as string
            'workoutDates': [today.toIso8601String()],
          });
          
          debugPrint('✅ First workout streak automatically logged');
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🔥 Streak updated! $newStreak days in a row!"),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
      } catch (e) {
        debugPrint("❌ Error automatically logging streak: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update streak: $e"),
              backgroundColor: AppColors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }

  // Helper methods for date comparison
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isConsecutiveDay(DateTime today, DateTime lastWorkout) {
    final yesterday = today.subtract(const Duration(days: 1));
    return _isSameDay(lastWorkout, yesterday) || _isSameDay(lastWorkout, today);
  }

  // Show custom exercise dialog
  void _showCustomExerciseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomExerciseDialog(
        allExercises: allExercises,
        customExercises: customExercises,
        userInfo: userInfo,
        onAddExercise: _addCustomExercise,
        onRemoveExercise: _removeCustomExercise,
        onUpdateSets: _updateCustomExerciseSets,
        getExerciseWarnings: _getExerciseWarnings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final themeData = Theme.of(context);
    final filteredExercises = _getFilteredRecommendedExercises();

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: CustomScrollView(
        slivers: [
          // Compact App Bar with Masculine Design
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 2,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentBlue.withOpacity(0.95),
                      AppColors.accentPurple.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Geometric background pattern
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 20, right: 24),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Fitness Library",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tailored workouts for your goals",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Compact Stats Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: theme.borderColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCompactStat("Recommended", "${recommended.length}", Icons.auto_awesome, AppColors.orange),
                        Container(
                          height: 40,
                          width: 1,
                          color: theme.borderColor.withOpacity(0.3),
                        ),
                        _buildCompactStat("Custom", "${customExercises.length}", Icons.edit, AppColors.accentPurple),
                        Container(
                          height: 40,
                          width: 1,
                          color: theme.borderColor.withOpacity(0.3),
                        ),
                        _buildCompactStat("Types", "4", Icons.category, AppColors.accentBlue),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Compact Filters Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Filter by Type",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            const SizedBox(width: 4),
                            _buildCompactFilterChip("All", Icons.all_inclusive, theme, themeData),
                            _buildCompactFilterChip("Cardio", Icons.favorite, theme, themeData),
                            _buildCompactFilterChip("Strength", Icons.fitness_center, theme, themeData),
                            _buildCompactFilterChip("Legs", Icons.directions_run, theme, themeData),
                            _buildCompactFilterChip("Core", Icons.accessibility_new, theme, themeData),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Start Workout Card - Masculine Design
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: workoutCompleted 
                        ? LinearGradient(
                            colors: [
                              AppColors.green.withOpacity(0.8),
                              AppColors.green.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.accentBlue,
                              AppColors.accentPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: workoutCompleted 
                            ? AppColors.green.withOpacity(0.3)
                            : AppColors.accentBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon with masculine design
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            workoutCompleted ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workoutCompleted ? "Workout Completed!" : "Ready to Train?",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                workoutCompleted 
                                  ? "You've completed today's workout"
                                  : "Start your personalized workout",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Action button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: workoutCompleted 
                              ? null 
                              : filteredExercises.isEmpty ? null : () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => WorkoutRunner(
                                      exercises: filteredExercises,
                                      onWorkoutCompleted: _onWorkoutCompleted,
                                    )
                                  ));
                                },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: workoutCompleted 
                                ? Colors.grey 
                                : Colors.white,
                              foregroundColor: workoutCompleted 
                                ? Colors.white 
                                : AppColors.accentBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              workoutCompleted ? "Completed" : "Begin",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Exercises Header
                  Row(
                    children: [
                      Text(
                        "Your Exercises",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${filteredExercises.length} exercises",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Exercises List
         SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ex = filteredExercises[index];
              final style = typeStyles[ex.type] ?? {};
              final bool isCustom = index >= recommended.length;
              // FIX: Apply warnings to ALL exercises, not just custom ones
              final warnings = _getExerciseWarnings(ex);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: _buildMasculineExerciseTile(ex, style, theme, themeData, isCustom: isCustom, warnings: warnings),
              );
            },
            childCount: filteredExercises.length,
          ),
        ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCustomExerciseDialog,
        backgroundColor: AppColors.accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFilterChip(String label, IconData icon, ThemeManager theme, ThemeData themeData) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [
              AppColors.accentBlue,
              AppColors.accentPurple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.borderColor.withOpacity(0.3),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.accentBlue.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => selectedFilter = label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : themeData.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasculineExerciseTile(Exercise ex, Map<String, dynamic> style, ThemeManager theme, ThemeData themeData, {bool isCustom = false, List<String> warnings = const []}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: warnings.isNotEmpty ? AppColors.orange.withOpacity(0.3) : theme.borderColor.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: ex)),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise Icon with compact design
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        (style["color"] as Color?)?.withOpacity(0.2) ?? AppColors.accentBlue.withOpacity(0.2),
                        (style["color"] as Color?)?.withOpacity(0.1) ?? AppColors.accentBlue.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _buildExerciseIcon(style, themeData),
                ),

                const SizedBox(width: 12),

                // Exercise Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  ex.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: themeData.colorScheme.onSurface,
                                  ),
                                ),
                                if (isCustom)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "CUSTOM",
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentBlue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(ex.difficulty).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ex.difficulty,
                              style: TextStyle(
                                color: _getDifficultyColor(ex.difficulty),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (style["color"] as Color?)?.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  style["icon"] ?? Icons.sports,
                                  size: 12,
                                  color: style["color"] ?? themeData.colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ex.type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: style["color"] ?? themeData.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildExerciseStat(Icons.timer_outlined, "${ex.duration}s", themeData),
                          const SizedBox(width: 8),
                          _buildExerciseStat(Icons.repeat, "${ex.sets}×${ex.reps}", themeData),
                        ],
                      ),
                      if (warnings.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: warnings.map((warning) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 10, color: AppColors.orange),
                                const SizedBox(width: 2),
                                Text(
                                  warning,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.accentBlue,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseIcon(Map<String, dynamic> style, ThemeData themeData) {
    return Center(
      child: Icon(
        style["icon"] ?? Icons.fitness_center,
        size: 24,
        color: (style["color"] as Color?)?.withOpacity(0.6) ?? themeData.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  Widget _buildExerciseStat(IconData icon, String text, ThemeData themeData) {
    return Row(
      children: [
        Icon(icon, size: 12, color: themeData.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: themeData.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "easy":
        return AppColors.green;
      case "medium":
        return AppColors.orange;
      case "hard":
        return AppColors.orange;
      default:
        return AppColors.accentBlue;
    }
  }
}

/// ---------------------- Custom Exercise Dialog ----------------------
/// ---------------------- Custom Exercise Dialog ----------------------
class CustomExerciseDialog extends StatefulWidget {
  final List<Exercise> allExercises;
  final List<Exercise> customExercises;
  final Map<String, dynamic>? userInfo;
  final Function(Exercise) onAddExercise;
  final Function(int) onRemoveExercise;
  final Function(int, int) onUpdateSets;
  final List<String> Function(Exercise) getExerciseWarnings;

  const CustomExerciseDialog({
    super.key,
    required this.allExercises,
    required this.customExercises,
    required this.userInfo,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onUpdateSets,
    required this.getExerciseWarnings,
  });

  @override
  State<CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<CustomExerciseDialog> with SingleTickerProviderStateMixin {
  late List<Exercise> availableExercises;
  final Map<Exercise, int> exerciseSets = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateAvailableExercises();
    
    // Initialize sets for custom exercises
    for (var ex in widget.customExercises) {
      exerciseSets[ex] = ex.sets;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateAvailableExercises() {
    setState(() {
      availableExercises = widget.allExercises.where((ex) => 
        !widget.customExercises.any((customEx) => customEx.name == ex.name) &&
        ex.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    });
  }

  void _addExerciseWithConfirmation(Exercise exercise) {
    final warnings = widget.getExerciseWarnings(exercise);
    
    if (warnings.isNotEmpty) {
      // Show confirmation dialog for non-recommended exercises
      _showExerciseWarningDialog(exercise, warnings);
    } else {
      // Add directly if no warnings
      _addExercise(exercise);
    }
  }

  void _showExerciseWarningDialog(Exercise exercise, List<String> warnings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Exercise Not Recommended",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTypeColor(exercise.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(exercise.type),
                      color: _getTypeColor(exercise.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${exercise.type} • ${exercise.difficulty}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "This exercise may not be suitable for you:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...warnings.map((warning) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withOpacity(0.2)),
              ),
              child: Text(
                "Are you sure you want to add this exercise?",
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addExercise(exercise);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Add Anyway"),
          ),
        ],
      ),
    );
  }

  void _addExercise(Exercise exercise) {
    widget.onAddExercise(exercise);
    setState(() {
      exerciseSets[exercise] = exercise.sets;
    });
    _updateAvailableExercises();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${exercise.name} added to custom exercises',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.green.withOpacity(0.3)),
        ),
      ),
    );
  }

  void _removeExerciseWithConfirmation(int index) {
    final exercise = widget.customExercises[index];
    final warnings = widget.getExerciseWarnings(exercise);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "Remove Exercise?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to remove ${exercise.name} from your custom exercises?",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            if (warnings.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This exercise is suitable for your profile",
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeExercise(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _removeExercise(int index) {
    final exercise = widget.customExercises[index];
    widget.onRemoveExercise(index);
    setState(() {
      exerciseSets.remove(exercise);
    });
    _updateAvailableExercises();
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.delete, color: AppColors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${exercise.name} removed',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.orange.withOpacity(0.3)),
        ),
      ),
    );
  }

  void _updateSets(int index, int newSets) {
    widget.onUpdateSets(index, newSets);
    setState(() {
      exerciseSets[widget.customExercises[index]] = newSets;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final themeData = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.all(8), // Minimal margin for almost full screen
      height: screenHeight * 0.95, // 95% of screen height
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // COMPACT Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentBlue.withOpacity(0.95),
                  AppColors.accentPurple.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Title Row - More Compact
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Custom Workout Builder",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Build your perfect workout routine",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Available", "${availableExercises.length}", Icons.explore),
                      _buildStatItem("Custom", "${widget.customExercises.length}", Icons.my_library_add),
                      _buildStatItem("Total", "${widget.allExercises.length}", Icons.library_books),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _updateAvailableExercises();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search exercises...",
                  hintStyle: TextStyle(
                    color: themeData.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(Icons.search, color: AppColors.accentBlue, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.orange, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _updateAvailableExercises();
                      });
                    },
                  ) : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor.withOpacity(0.2)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.accentPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: themeData.colorScheme.onSurface.withOpacity(0.6),
                tabs: const [
               Tab(
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Added padding
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, size: 18),
                    SizedBox(width: 8),
                    Text("Available Exercises"),
                  ],
                ),
              ),
            ),
            Tab(
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Added padding
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_library_add, size: 18),
                    SizedBox(width: 8),
                    Text("My Exercises"),
                  ],
                ),
              ),
            ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tab Content - Takes most of the space
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Available Exercises Tab
                _buildAvailableExercisesTab(theme, themeData),

                // Your Exercises Tab
                _buildCustomExercisesTab(theme, themeData),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.borderColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Workout Summary",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeData.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.customExercises.length} custom exercises • ${widget.customExercises.fold(0, (sum, ex) => sum + ex.sets)} total sets",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: AppColors.accentBlue.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Done",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableExercisesTab(ThemeManager theme, ThemeData themeData) {
    if (availableExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.fitness_center : Icons.search_off,
              size: 80,
              color: themeData.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty ? "All Exercises Added!" : "No Exercises Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeData.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty 
                  ? "You've added all available exercises to your custom workout"
                  : "Try searching for something else",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: themeData.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableExercises.length,
      itemBuilder: (context, index) {
        final exercise = availableExercises[index];
        final warnings = widget.getExerciseWarnings(exercise);
        
        return _buildExerciseTile(exercise, warnings, theme, themeData);
      },
    );
  }

  Widget _buildExerciseTile(Exercise exercise, List<String> warnings, ThemeManager theme, ThemeData themeData) {
    final typeColor = _getTypeColor(exercise.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: warnings.isNotEmpty ? AppColors.orange.withOpacity(0.3) : theme.borderColor.withOpacity(0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _addExerciseWithConfirmation(exercise),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        typeColor.withOpacity(0.2),
                        typeColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(exercise.type),
                    color: typeColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // Exercise Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          _buildDifficultyBadge(exercise.difficulty),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildExerciseTypeChip(exercise.type, typeColor),
                          const SizedBox(width: 8),
                          _buildExerciseStat(Icons.timer_outlined, "${exercise.duration}s"),
                          const SizedBox(width: 8),
                          _buildExerciseStat(Icons.repeat, "${exercise.sets}×${exercise.reps}"),
                        ],
                      ),
                      if (warnings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.orange.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Not recommended for your profile",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Add Button
                Container(
                  decoration: BoxDecoration(
                    gradient: warnings.isEmpty 
                      ? LinearGradient(
                          colors: [AppColors.accentBlue, AppColors.accentPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [AppColors.orange, Colors.orange.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (warnings.isEmpty ? AppColors.accentBlue : AppColors.orange).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _addExerciseWithConfirmation(exercise),
                    icon: Icon(
                      warnings.isEmpty ? Icons.add : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(10),
                    tooltip: warnings.isEmpty ? 'Add exercise' : 'Exercise has warnings',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomExercisesTab(ThemeManager theme, ThemeData themeData) {
    if (widget.customExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center, size: 50, color: AppColors.accentBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              "No Custom Exercises",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeData.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Add exercises from the Available tab\nto build your custom workout",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: themeData.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore, size: 16),
                  SizedBox(width: 6),
                  Text("Browse Exercises"),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.customExercises.length,
      itemBuilder: (context, index) {
        final exercise = widget.customExercises[index];
        final currentSets = exerciseSets[exercise] ?? exercise.sets;
        final warnings = widget.getExerciseWarnings(exercise);
        
        return _buildCustomExerciseTile(exercise, index, currentSets, warnings, theme, themeData);
      },
    );
  }

  Widget _buildCustomExerciseTile(Exercise exercise, int index, int currentSets, List<String> warnings, ThemeManager theme, ThemeData themeData) {
    final typeColor = _getTypeColor(exercise.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: warnings.isNotEmpty ? AppColors.orange.withOpacity(0.3) : AppColors.accentBlue.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Drag Handle
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Exercise Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTypeIcon(exercise.type),
                  color: typeColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Exercise Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        _buildDifficultyBadge(exercise.difficulty),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildExerciseTypeChip(exercise.type, typeColor),
                        const SizedBox(width: 8),
                        _buildExerciseStat(Icons.timer_outlined, "${exercise.duration}s"),
                      ],
                    ),
                    if (warnings.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 12, color: AppColors.orange),
                            const SizedBox(width: 4),
                            Text(
                              "Not recommended",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Sets Selector and Remove Button
              Column(
                children: [
                  // Sets Selector
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        // Decrease Button
                        Container(
                          decoration: BoxDecoration(
                            color: currentSets > 1 ? AppColors.accentBlue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: IconButton(
                            onPressed: currentSets > 1 ? () => _updateSets(index, currentSets - 1) : null,
                            icon: Icon(
                              Icons.remove,
                              size: 16,
                              color: currentSets > 1 ? AppColors.accentBlue : Colors.grey,
                            ),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        
                        // Sets Display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(color: theme.borderColor.withOpacity(0.3)),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "$currentSets",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                              Text(
                                "sets",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: themeData.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Increase Button
                        Container(
                          decoration: BoxDecoration(
                            color: currentSets < 10 ? AppColors.accentBlue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: IconButton(
                            onPressed: currentSets < 10 ? () => _updateSets(index, currentSets + 1) : null,
                            icon: Icon(
                              Icons.add,
                              size: 16,
                              color: currentSets < 10 ? AppColors.accentBlue : Colors.grey,
                            ),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Remove Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => _removeExerciseWithConfirmation(index),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.orange,
                        size: 18,
                      ),
                      padding: const EdgeInsets.all(6),
                      tooltip: 'Remove exercise',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTypeChip(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case "easy":
        color = AppColors.green;
        break;
      case "medium":
        color = AppColors.orange;
        break;
      case "hard":
        color = AppColors.orange;
        break;
      default:
        color = AppColors.accentBlue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExerciseStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "cardio":
        return AppColors.orange;
      case "strength":
        return AppColors.accentBlue;
      case "legs":
        return AppColors.accentPurple;
      case "core":
        return AppColors.accentCyan;
      default:
        return AppColors.accentBlue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case "cardio":
        return Icons.favorite;
      case "strength":
        return Icons.fitness_center;
      case "legs":
        return Icons.directions_run;
      case "core":
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }
}
/// ---------------------- WorkoutRunner ----------------------
class WorkoutRunner extends StatefulWidget {
  final List<Exercise> exercises;
  final int cooldownSeconds;
  final Function(bool, int, int) onWorkoutCompleted;

  const WorkoutRunner({
    super.key, 
    required this.exercises, 
    this.cooldownSeconds = 10,
    required this.onWorkoutCompleted,
  });

  @override
  State<WorkoutRunner> createState() => _WorkoutRunnerState();
}

class _WorkoutRunnerState extends State<WorkoutRunner> {
  int currentIndex = 0;
  bool inCooldown = false;
  int cooldownRemaining = 0;
  Timer? cooldownTimer;
  int completedExercises = 0;
  int skippedExercises = 0;

  @override
  void dispose() {
    cooldownTimer?.cancel();
    super.dispose();
  }

  void _onSetComplete() {
    debugPrint('=== Exercise Complete Called ===');
    debugPrint('Exercise completed: ${widget.exercises[currentIndex].name}');
    
    completedExercises++;
    debugPrint('Completed exercises: $completedExercises');
    
    debugPrint('Moving to next exercise or finishing workout');
    
    if (currentIndex >= widget.exercises.length - 1) {
      debugPrint('🏁 Last exercise completed - finishing workout');
      _finishWorkout();
    } else {
      debugPrint('➡️ Moving to next exercise');
      _startCooldown();
    }
  }

  void _startCooldown() {
    setState(() {
      inCooldown = true;
      cooldownRemaining = widget.cooldownSeconds;
    });

    cooldownTimer?.cancel();
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (cooldownRemaining > 0) {
        setState(() => cooldownRemaining--);
      } else {
        t.cancel();
        _advanceToNextExercise();
      }
    });
  }

  void _advanceToNextExercise() {
    debugPrint('Advancing to next exercise');
    debugPrint('Current index: $currentIndex');
    debugPrint('Total exercises: ${widget.exercises.length}');
    
    setState(() {
      inCooldown = false;
      currentIndex = currentIndex + 1;
    });
    
    debugPrint('New current index: $currentIndex');
    if (currentIndex < widget.exercises.length) {
      debugPrint('Next exercise: ${widget.exercises[currentIndex].name}');
    }
  }

  void _skipCooldown() {
    debugPrint('Skipping cooldown');
    cooldownTimer?.cancel();
    _advanceToNextExercise();
  }

  void _finishWorkout() {
    final bool allExercisesCompleted = completedExercises == widget.exercises.length;
    final bool isWorkoutCompleted = completedExercises > 0;
    
    debugPrint('=== Workout Finish Summary ===');
    debugPrint('Total exercises: ${widget.exercises.length}');
    debugPrint('Completed exercises: $completedExercises');
    debugPrint('Skipped exercises: $skippedExercises');
    debugPrint('All exercises completed: $allExercisesCompleted');
    debugPrint('Workout marked as completed: $isWorkoutCompleted');
    
    widget.onWorkoutCompleted(isWorkoutCompleted, completedExercises, widget.exercises.length);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        final bool streakLogged = allExercisesCompleted;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: streakLogged 
                      ? AppColors.green.withOpacity(0.1)
                      : isWorkoutCompleted 
                        ? AppColors.accentBlue.withOpacity(0.1)
                        : AppColors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    streakLogged ? Icons.celebration_rounded : 
                    isWorkoutCompleted ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    size: 40,
                    color: streakLogged ? AppColors.green : 
                           isWorkoutCompleted ? AppColors.accentBlue : AppColors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  streakLogged ? "Workout Complete! 🎉" : 
                  isWorkoutCompleted ? "Workout Complete!" : "Workout Ended",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: streakLogged ? AppColors.green : 
                           isWorkoutCompleted ? AppColors.accentBlue : AppColors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  streakLogged 
                    ? "Amazing job! You completed all exercises and your streak has been updated! 🔥"
                    : isWorkoutCompleted 
                      ? "Great work! You completed $completedExercises/${widget.exercises.length} exercises."
                      : "You skipped all exercises. Complete ALL exercises to count towards your streak.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (streakLogged) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Your dedication is inspiring! 💪",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (!isWorkoutCompleted) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Complete ALL exercises to count towards your streak.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // dialog
                      Navigator.of(context).pop(); // exit runner
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: streakLogged ? AppColors.green : 
                                     isWorkoutCompleted ? AppColors.accentBlue : AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      streakLogged ? "Awesome! 🎯" : 
                      isWorkoutCompleted ? "Finish Workout" : "Exit Workout",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLastExerciseWarning() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                "Last Exercise",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "This is the last exercise. If you skip it, it will not count towards your streak. Complete ALL exercises to maintain your streak.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        skippedExercises++;
                        _finishWorkout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Skip & Finish",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final themeData = Theme.of(context);
    final ex = widget.exercises[currentIndex];
    final isLastExercise = currentIndex >= widget.exercises.length - 1;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Exercise ${currentIndex + 1}/${widget.exercises.length}", 
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ex.name,
              style: TextStyle(
                fontSize: 13,
                color: themeData.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 20, color: themeData.colorScheme.onSurface),
          ), 
          onPressed: () {
            showDialog(
              context: context, 
              builder: (_) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Exit Workout?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Are you sure you want to exit the workout? Your progress will NOT be saved if you exit mid-exercise.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: themeData.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: themeData.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // dialog
                                Navigator.of(context).pop(); // runner
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Exit",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
        actions: [
          if (inCooldown)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 14, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Text(
                    "$cooldownRemaining s",
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (inCooldown)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _skipCooldown,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  "SKIP",
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          if (!inCooldown)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.skip_next, size: 20, color: AppColors.accentBlue),
              ),
              onPressed: () {
                if (isLastExercise) {
                  _showLastExerciseWarning();
                } else {
                  showDialog(
                    context: context, 
                    builder: (_) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Skip Exercise?",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Skip this exercise and go to the next one? Skipped exercises will not count towards your streak. Complete ALL exercises to maintain your streak.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeData.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: themeData.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      skippedExercises++;
                                      if (currentIndex >= widget.exercises.length - 1) {
                                        _finishWorkout();
                                      } else {
                                        _advanceToNextExercise();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Skip",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Workout progress bar with improved design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progress",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeData.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      "${currentIndex + 1}/${widget.exercises.length}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (currentIndex + 1) / widget.exercises.length,
                  backgroundColor: theme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 8,
                ),
              ],
            ),
          ),
          
          // Next exercise preview during cooldown
          if (inCooldown && currentIndex < widget.exercises.length - 1)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentBlue.withOpacity(0.08),
                    AppColors.accentCyan.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentBlue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Next Up",
                          style: TextStyle(
                            fontSize: 12,
                            color: themeData.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.exercises[currentIndex + 1].name,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Exercise detail screen
          Expanded(
            child: ExerciseDetailScreen(
              exercise: ex,
              onComplete: _onSetComplete,
              totalSets: ex.sets,
              inCooldown: inCooldown,
            ),
          ),
        ],
      ),
    );
  }
}