import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/food_recommendation.dart';
import '../models/workout_streak.dart';

class FitnessProvider extends ChangeNotifier {
  final WorkoutStreak _streak = WorkoutStreak(
    currentStreak: 5,
    bestStreak: 12,
    lastWorkout: DateTime.now().subtract(Duration(days: 1)),
    workoutDates: [],
  );

  final List<Exercise> _exercises = [
    Exercise(name: "Push-ups", type: "Strength", duration: 15, sets: 3, reps: 10, difficulty: "Beginner"),
    Exercise(name: "Squats", type: "Strength", duration: 20, sets: 3, reps: 15, difficulty: "Intermediate"),
    Exercise(name: "Plank", type: "Core", duration: 30, sets: 3, reps: 1, difficulty: "Beginner"),
    Exercise(name: "Burpees", type: "Cardio", duration: 25, sets: 3, reps: 8, difficulty: "Advanced"),
  ];

  int _dailyCalories = 1250;
  final double _bmi = 22.5;
  final Map<String, double> _weeklyProgress = {
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
  int get dailyCalories => _dailyCalories;
  double get bmi => _bmi;
  Map<String, double> get weeklyProgress => _weeklyProgress;

  /// 🎯 Main Recommendation Engine
  List<FoodRecommendation> getRecommendations({
    required String lifestyle,
    required String fitnessGoal,
    required String reproductiveStatus,
  }) {
    List<FoodRecommendation> foods = allFoods;

    // Fitness Goal filter
    switch (fitnessGoal.toLowerCase()) {
      case "weight loss":
        foods = foods.where((f) => f.kcal <= 300).toList();
        break;
      case "muscle building":
        foods = foods.where((f) => f.kcal >= 250).toList();
        break;
      case "endurance & stamina":
        foods = foods.where((f) => f.kcal >= 200 && f.kcal <= 450).toList();
        break;
      case "weight gain":
        foods = foods.where((f) => f.kcal >= 300).toList();
        break;
      case "general fitness":
      case "maintenance":
        foods = foods.where((f) => f.kcal >= 150 && f.kcal <= 400).toList();
        break;
    }

    // Lifestyle filter
    switch (lifestyle.toLowerCase()) {
      case "sedentary":
        foods = foods.where((f) => f.kcal <= 350).toList();
        break;
      case "lightly active":
        foods = foods.where((f) => f.kcal <= 400).toList();
        break;
      case "moderately active":
        foods = foods.where((f) => f.kcal >= 200 && f.kcal <= 450).toList();
        break;
      case "very active":
      case "extra active":
        foods = foods.where((f) => f.kcal >= 250).toList();
        break;
    }

    // Reproductive status filter
    switch (reproductiveStatus.toLowerCase()) {
      case "pregnant":
      case "breastfeeding":
        foods = foods.where((f) =>
          f.desc.toLowerCase().contains("protein") ||
          f.desc.toLowerCase().contains("calcium") ||
          f.desc.toLowerCase().contains("omega-3")
        ).toList();
        break;
      case "menopausal":
        foods = foods.where((f) =>
          f.desc.toLowerCase().contains("calcium") ||
          f.desc.toLowerCase().contains("fiber")
        ).toList();
        break;
      case "on period":
        foods = foods.where((f) =>
          f.desc.toLowerCase().contains("iron") ||
          f.desc.toLowerCase().contains("protein")
        ).toList();
        break;
    }

    // Fallback: if no results, return full list
    if (foods.isEmpty) {
      foods = allFoods;
    }

    return foods;
  }

  /// ✅ Get 5 random foods overall
  List<FoodRecommendation> getFiveRecommendations({
    required String lifestyle,
    required String fitnessGoal,
    required String reproductiveStatus,
  }) {
    final recos = getRecommendations(
      lifestyle: lifestyle,
      fitnessGoal: fitnessGoal,
      reproductiveStatus: reproductiveStatus,
    );

    recos.shuffle(Random());
    return recos.take(5).toList();
  }

  /// ✅ Get 5 meals by time of day (Morning, Afternoon, Evening, Snack)
  Map<String, List<FoodRecommendation>> getDailyMeals({
    required String lifestyle,
    required String fitnessGoal,
    required String reproductiveStatus,
  }) {
    final recos = getRecommendations(
      lifestyle: lifestyle,
      fitnessGoal: fitnessGoal,
      reproductiveStatus: reproductiveStatus,
    );

    recos.shuffle(Random());

    // Helper: pick 5 foods or fewer if not enough
    List<FoodRecommendation> pickFive(List<FoodRecommendation> list) {
      return list.take(5).toList();
    }

    return {
      "morning": pickFive(recos.where((f) => f.type == "morning").toList()),
      "afternoon": pickFive(recos.where((f) => f.type == "afternoon").toList()),
      "evening": pickFive(recos.where((f) => f.type == "evening").toList()),
      "snack": pickFive(recos.where((f) => f.type == "any").toList()),
    };
  }

  /// Workout streak handling
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