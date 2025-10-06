class WorkoutStreak {
  int currentStreak;
  int bestStreak;
  DateTime lastWorkout;
  List<DateTime> workoutDates;

  WorkoutStreak({
    required this.currentStreak,
    required this.bestStreak,
    required this.lastWorkout,
    required this.workoutDates,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastWorkout': lastWorkout.toIso8601String(),
      'workoutDates': workoutDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  // Create from Map from Firestore
  factory WorkoutStreak.fromMap(Map<String, dynamic> map) {
    return WorkoutStreak(
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      lastWorkout: DateTime.parse(map['lastWorkout']),
      workoutDates: (map['workoutDates'] as List<dynamic>)
          .map((dateString) => DateTime.parse(dateString as String))
          .toList(),
    );
  }

  // Create empty streak
  factory WorkoutStreak.empty() {
    return WorkoutStreak(
      currentStreak: 0,
      bestStreak: 0,
      lastWorkout: DateTime.now().subtract(const Duration(days: 2)),
      workoutDates: [],
    );
  }
}