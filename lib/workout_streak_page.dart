import 'package:flutter/material.dart';
import 'models/workout_streak.dart';

class WorkoutStreakPage extends StatefulWidget {
  const WorkoutStreakPage({super.key});

  @override
  State<WorkoutStreakPage> createState() => _WorkoutStreakPageState();
}

class _WorkoutStreakPageState extends State<WorkoutStreakPage> {
  late WorkoutStreak _streak;

  @override
  void initState() {
    super.initState();
    _streak = WorkoutStreak(
      currentStreak: 0,
      bestStreak: 0,
      lastWorkout: DateTime.now().subtract(const Duration(days: 2)),
      workoutDates: [],
    );
  }

  void _logWorkout() {
    DateTime today = DateTime.now();
    DateTime lastWorkout = _streak.lastWorkout;

    if (today.difference(lastWorkout).inDays == 1) {
      _streak.currentStreak++;
    } else if (today.difference(lastWorkout).inDays == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already logged today's workout!")),
      );
      return;
    } else {
      _streak.currentStreak = 1;
    }

    if (_streak.currentStreak > _streak.bestStreak) {
      _streak.bestStreak = _streak.currentStreak;
    }

    _streak.lastWorkout = today;
    _streak.workoutDates.add(today);
    setState(() {});
  }

  String _getBadge() {
    if (_streak.currentStreak >= 15) return "🏆 Legend";
    if (_streak.currentStreak >= 10) return "💪 Advanced";
    if (_streak.currentStreak >= 5) return "🔥 Intermediate";
    return "🌱 Beginner";
  }

  @override
  Widget build(BuildContext context) {
    const appGreen = Color(0xFF8BC34A); // same green as your app theme

    return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text(
            "Workout Streak",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: appGreen,
        ),
        body: Center( // <---- centers the column horizontally and vertically
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 100),
                const SizedBox(height: 25),

              // Streak Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "🔥 Current Streak: ${_streak.currentStreak} days",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "🏅 Best Streak: ${_streak.bestStreak} days",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Badge: ${_getBadge()}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Log Button
              ElevatedButton.icon(
                onPressed: _logWorkout,
                icon: const Icon(Icons.fitness_center),
                label: const Text("Log Today’s Workout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 25, vertical: 15),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}