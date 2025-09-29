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
}