import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/food_recommendation.dart';
import '../models/workout_streak.dart';

class FitnessProvider extends ChangeNotifier {
  WorkoutStreak _streak = WorkoutStreak(
    currentStreak: 5,
    bestStreak: 12,
    lastWorkout: DateTime.now().subtract(Duration(days: 1)),
    workoutDates: [],
  );
  
  List<Exercise> _exercises = [
    Exercise(name: "Push-ups", type: "Strength", duration: 15, sets: 3, reps: 10, difficulty: "Beginner"),
    Exercise(name: "Squats", type: "Strength", duration: 20, sets: 3, reps: 15, difficulty: "Intermediate"),
    Exercise(name: "Plank", type: "Core", duration: 30, sets: 3, reps: 1, difficulty: "Beginner"),
    Exercise(name: "Burpees", type: "Cardio", duration: 25, sets: 3, reps: 8, difficulty: "Advanced"),
  ];

  List<FoodRecommendation> _foodRecommendations = [
    FoodRecommendation(
      name: "Grilled Chicken Salad",
      imageUrl: "",
      calories: 350,
      description: "High protein, low carb meal perfect for muscle building",
      nutrients: ["Protein: 35g", "Carbs: 15g", "Fat: 18g"],
    ),
    FoodRecommendation(
      name: "Quinoa Bowl",
      imageUrl: "",
      calories: 420,
      description: "Complete protein with complex carbs",
      nutrients: ["Protein: 20g", "Carbs: 45g", "Fat: 12g"],
    ),
    FoodRecommendation(
      name: "Avocado Toast",
      imageUrl: "",
      calories: 280,
      description: "Healthy fats and fiber for sustained energy",
      nutrients: ["Protein: 8g", "Carbs: 24g", "Fat: 18g"],
    ),
    FoodRecommendation(
      name: "Greek Yogurt Bowl",
      imageUrl: "",
      calories: 190,
      description: "Probiotics and protein for digestive health",
      nutrients: ["Protein: 15g", "Carbs: 12g", "Fat: 8g"],
    ),
  ];

  int _dailyCalories = 1250;
  double _bmi = 22.5;
  Map<String, double> _weeklyProgress = {
    'Mon': 80,
    'Tue': 65,
    'Wed': 90,
    'Thu': 75,
    'Fri': 95,
    'Sat': 60,
    'Sun': 85,
  };

  WorkoutStreak get streak => _streak;
  List<Exercise> get exercises => _exercises;
  List<FoodRecommendation> get foodRecommendations => _foodRecommendations;
  int get dailyCalories => _dailyCalories;
  double get bmi => _bmi;
  Map<String, double> get weeklyProgress => _weeklyProgress;

  void completeWorkout() {
    _streak.currentStreak++;
    _streak.lastWorkout = DateTime.now();
    _streak.workoutDates.add(DateTime.now());
    if (_streak.currentStreak > _streak.bestStreak) {
      _streak.bestStreak = _streak.currentStreak;
    }
    notifyListeners();
  }

  void updateCalories(int calories) {
    _dailyCalories = calories;
    notifyListeners();
  }
}