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
    Exercise(name: "Burpee", type: "Cardio", duration: 30, sets: 3, reps: 15, difficulty: "Hard", gifUrl: "https://i.pinimg.com/originals/f4/b0/f3/f4b0f3e8d89b0a6d7f3b5b5e5f5f5f5f.gif"),
    Exercise(name: "Push Up", type: "Strength", duration: 20, sets: 3, reps: 12, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/18/27/be/1827be8d4f5f3c8f7d3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Squat", type: "Legs", duration: 25, sets: 3, reps: 20, difficulty: "Easy", gifUrl: "https://i.pinimg.com/originals/b4/3f/7f/b43f7f9b0f3c8d7f3f3f3f3f3f3f3f3f3f3f3f.gif"),
    Exercise(name: "Plank", type: "Core", duration: 40, sets: 2, reps: 1, difficulty: "Hard", gifUrl: "https://i.pinimg.com/originals/1e/5c/c8/1e5cc8f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Jumping Jack", type: "Cardio", duration: 20, sets: 2, reps: 20, difficulty: "Easy", gifUrl: "https://i.pinimg.com/originals/85/1e/17/851e17c6f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Lunge", type: "Legs", duration: 25, sets: 3, reps: 15, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/9e/3f/7d/9e3f7df3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Mountain Climber", type: "Cardio", duration: 30, sets: 3, reps: 20, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/6c/8a/1d/6c8a1df3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f.gif"),
    Exercise(name: "Bicep Curl", type: "Strength", duration: 20, sets: 3, reps: 12, difficulty: "Easy", gifUrl: "https://i.pinimg.com/originals/4d/2e/1f/4d2e1ff3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Russian Twist", type: "Core", duration: 30, sets: 3, reps: 20, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/7a/2c/5e/7a2c5ef3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "High Knee", type: "Cardio", duration: 25, sets: 3, reps: 30, difficulty: "Easy", gifUrl: "https://i.pinimg.com/originals/3b/4d/8f/3b4d8ff3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Diamond Push Up", type: "Strength", duration: 25, sets: 3, reps: 10, difficulty: "Hard", gifUrl: "https://i.pinimg.com/originals/5c/7e/2a/5c7e2af3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Bulgarian Squat", type: "Legs", duration: 30, sets: 3, reps: 12, difficulty: "Hard", gifUrl: "https://i.pinimg.com/originals/8d/5f/3c/8d5f3cf3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Bicycle Crunch", type: "Core", duration: 30, sets: 3, reps: 20, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/2f/6a/4b/2f6a4bf3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Box Jump", type: "Legs", duration: 30, sets: 3, reps: 10, difficulty: "Hard", gifUrl: "https://i.pinimg.com/originals/9a/1d/7e/9a1d7ef3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Dip", type: "Strength", duration: 25, sets: 3, reps: 12, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/4e/8c/1f/4e8c1ff3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Jump Rope", type: "Cardio", duration: 45, sets: 3, reps: 50, difficulty: "Easy", gifUrl: "https://i.pinimg.com/originals/6f/3a/9d/6f3a9df3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Leg Raise", type: "Core", duration: 25, sets: 3, reps: 15, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/1c/5d/8e/1c5d8ef3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Calf Raise", type: "Legs", duration: 20, sets: 4, reps: 20, difficulty: "Easy", gifUrl: "https://i.pinimg.com/originals/7b/4e/2f/7b4e2ff3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Shoulder Press", type: "Strength", duration: 25, sets: 3, reps: 12, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/3d/6c/1a/3d6c1af3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Sprint Interval", type: "Cardio", duration: 20, sets: 5, reps: 1, difficulty: "Hard", gifUrl: "https://i.pinimg.com/originals/5e/7f/3b/5e7f3bf3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Side Plank", type: "Core", duration: 30, sets: 3, reps: 2, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/8f/2d/6a/8f2d6af3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Wall Sit", type: "Legs", duration: 45, sets: 3, reps: 1, difficulty: "Medium", gifUrl: "https://i.pinimg.com/originals/2a/9e/4c/2a9e4cf3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Curl Ups", type: "Strength", duration: 25, sets: 3, reps: 8, difficulty: "Hard", gifUrl: "https://i.pinimg.com/originals/6d/1f/8b/6d1f8bf3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
    Exercise(name: "Butt Kick", type: "Cardio", duration: 25, sets: 3, reps: 30, difficulty: "Easy", gifUrl: "https://i.pinimg.com/originals/4f/7c/3d/4f7c3df3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3.gif"),
  ];

  bool loadingUser = true;
  Map<String, dynamic>? userInfo;
  List<Exercise> recommended = [];
  String selectedFilter = "All";

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
    if (selectedFilter == "All") {
      return recommended;
    }
    return recommended
        .where((e) => e.type == selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
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
                        _buildCompactStat("Types", "4", Icons.category, AppColors.accentPurple),
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
                          color: theme.primaryText,
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
                            _buildCompactFilterChip("All", Icons.all_inclusive, theme),
                            _buildCompactFilterChip("Cardio", Icons.favorite, theme),
                            _buildCompactFilterChip("Strength", Icons.fitness_center, theme),
                            _buildCompactFilterChip("Legs", Icons.directions_run, theme),
                            _buildCompactFilterChip("Core", Icons.accessibility_new, theme),
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
                      gradient: LinearGradient(
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
                          color: AppColors.accentBlue.withOpacity(0.3),
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
                            Icons.play_arrow_rounded,
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
                                "Ready to Train?",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Start your personalized workout",
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
                            onPressed: recommended.isEmpty ? null : () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => WorkoutRunner(exercises: recommended)
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.accentBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Begin",
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
                        "Recommended Exercises",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: _buildMasculineExerciseTile(ex, style, theme),
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

  Widget _buildCompactFilterChip(String label, IconData icon, ThemeManager theme) {
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
                    color: isSelected ? Colors.white : theme.primaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.primaryText,
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

  Widget _buildMasculineExerciseTile(Exercise ex, Map<String, dynamic> style, ThemeManager theme) {
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
        border: Border.all(color: theme.borderColor.withOpacity(0.1)),
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
                // Exercise Image/Icon with compact design
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        if (ex.gifUrl != null)
                          Image.network(
                            ex.gifUrl!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorBuilder: (c, e, st) => _buildExerciseIcon(style, theme),
                          )
                        else
                          _buildExerciseIcon(style, theme),
                      ],
                    ),
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
                              ex.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryText,
                              ),
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
                                  color: style["color"] ?? theme.tertiaryText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ex.type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: style["color"] ?? theme.tertiaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildExerciseStat(Icons.timer_outlined, "${ex.duration}s", theme),
                          const SizedBox(width: 8),
                          _buildExerciseStat(Icons.repeat, "${ex.sets}×${ex.reps}", theme),
                        ],
                      ),
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

  Widget _buildExerciseIcon(Map<String, dynamic> style, ThemeManager theme) {
    return Center(
      child: Icon(
        style["icon"] ?? Icons.fitness_center,
        size: 24,
        color: (style["color"] as Color?)?.withOpacity(0.6) ?? theme.tertiaryText,
      ),
    );
  }

  Widget _buildExerciseStat(IconData icon, String text, ThemeManager theme) {
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.tertiaryText),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: theme.tertiaryText,
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

/// ---------------------- WorkoutRunner ----------------------
class WorkoutRunner extends StatefulWidget {
  final List<Exercise> exercises;
  final int cooldownSeconds;

  const WorkoutRunner({super.key, required this.exercises, this.cooldownSeconds = 10});

  @override
  State<WorkoutRunner> createState() => _WorkoutRunnerState();
}

class _WorkoutRunnerState extends State<WorkoutRunner> {
  int currentIndex = 0;
  bool inCooldown = false;
  int cooldownRemaining = 0;
  Timer? cooldownTimer;

  @override
  void dispose() {
    cooldownTimer?.cancel();
    super.dispose();
  }

  // Called by ExerciseDetailScreen when the ENTIRE exercise is completed
  void _onSetComplete() {
    debugPrint('=== Exercise Complete Called ===');
    debugPrint('Exercise completed: ${widget.exercises[currentIndex].name}');
    debugPrint('Moving to next exercise or finishing workout');
    
    // When ExerciseDetailScreen calls onComplete, it means the ENTIRE exercise is done
    // (all sets + final rest + completion screen)
    if (currentIndex >= widget.exercises.length - 1) {
      debugPrint('🏁 Last exercise completed - finishing workout');
      _finishWorkout();
    } else {
      debugPrint('➡️ Moving to next exercise');
      _advanceToNextExercise();
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
    debugPrint('Next exercise: ${widget.exercises[currentIndex].name}');
  }

  void _skipCooldown() {
    debugPrint('Skipping cooldown');
    cooldownTimer?.cancel();
    _advanceToNextExercise();
  }

  void _finishWorkout() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
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
                    color: AppColors.accentBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 40,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Workout Complete!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Amazing job! You've completed your workout.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // dialog
                      Navigator.of(context).pop(); // exit runner
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Finish Workout",
                      style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final ex = widget.exercises[currentIndex];

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
                color: theme.secondaryText,
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
            child: Icon(Icons.close, size: 20, color: theme.primaryText),
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
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Are you sure you want to stop the workout? Your progress will be saved.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.secondaryText,
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
                                  color: theme.primaryText,
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
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Skip this exercise and go to the next one?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.secondaryText,
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
                                      color: theme.primaryText,
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
                        color: theme.secondaryText,
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
                            color: theme.secondaryText,
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

