import 'package:flutter/material.dart';
import '../models/food_recommendation.dart';

class UserInfoData {
  final double currentWeight; // kg
  final double heightCm; // cm
  final int age; // years
  final String sex; // Male, Female, Other
  final String activityLevel; // Sedentary, Lightly Active, Moderately Active, Very Active, Extra Active
  final String targetGoal;// Weight Loss, Weight Gain, Maintenance, etc.
  final String dietType; // Keto, Vegan, Vegetarian, Low Carb, Balanced, etc.
  final String dietaryRestrictions; // Gluten-free, Lactose-free, etc. (Now a single string)
  final String reproductiveStatus;
  final String allergies; // Peanuts, Seafood, etc. (Now a single string)
  final String otherConditions; // Diabetes, Hypertension, etc. (Now a single string)

  UserInfoData({
    required this.currentWeight,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.activityLevel,
    required this.targetGoal,
    required this.dietType,
    required this.reproductiveStatus,
    required this.dietaryRestrictions, // <--- FIX: Comma added here
    required this.allergies,
    required this.otherConditions,
  });
}

// --------------------------------------------------------------------------
// FOODRECOMMENDATIONSERVICE CLASS (LOGIC FIX FOR STRING FIELDS)
// --------------------------------------------------------------------------
class FoodRecommendationService {
  
  // --- Core Recommendation Logic ---
  List<Map<String, dynamic>> getRecommendations({
    required UserInfoData userInfo,
    required String timeOfDay, // 'morning', 'afternoon', 'evening', 'snack', 'any'
  }) {
    
    // 1. Initial Filter by Time
    List<FoodRecommendation> filteredFoods = allFoods
        .where((food) => food.type == timeOfDay || food.type == 'any')
        .toList();

    // 2. Calculate Calorie Target
    final dailyTDEE = _calculateTDEE(userInfo);
    double dailyCalorieTarget = dailyTDEE;

    // Adjust based on goal (simplified example: +/- 500 kcal)
    if (userInfo.targetGoal == 'Weight Loss') {
      dailyCalorieTarget -= 500;
    } else if (userInfo.targetGoal == 'Weight Gain' || userInfo.targetGoal == 'Muscle Building') {
      dailyCalorieTarget += 500;
    } 
    
    double mealCalorieTarget;
    if (timeOfDay == 'morning') {
      mealCalorieTarget = dailyCalorieTarget * 0.30;
    } else if (timeOfDay == 'afternoon') {
      mealCalorieTarget = dailyCalorieTarget * 0.35;
    } else if (timeOfDay == 'evening') {
      mealCalorieTarget = dailyCalorieTarget * 0.30;
    } else { // 'snack' or 'any'
      mealCalorieTarget = dailyCalorieTarget * 0.15;
    }
    
    final minCalorie = mealCalorieTarget * 0.70;
    final maxCalorie = mealCalorieTarget * 1.30;

    // 3. Filter by User Preferences (Diet, Restrictions, Allergies, Conditions)
    filteredFoods = filteredFoods.where((food) {
      final nameLower = food.name.toLowerCase();
      final descLower = food.desc.toLowerCase();

      // a) Calorie Range Filter 
      if (timeOfDay != 'snack' && food.type != 'any') {
        if (food.kcal < minCalorie || food.kcal > maxCalorie) {
          return false;
        }
      }

      // b) Diet Type Filter (Logic is fine for single-string dietType)
      if (userInfo.dietType == 'Vegan' && !descLower.contains('vegan') && !nameLower.contains('tofu') && !descLower.contains('plant-based')) {
        if (nameLower.contains('milk') || nameLower.contains('cheese') || nameLower.contains('yogurt') || nameLower.contains('chicken') || nameLower.contains('beef') || nameLower.contains('egg') || nameLower.contains('pork') || nameLower.contains('fish')) {
          return false;
        }
      }
      if (userInfo.dietType == 'Keto' && !nameLower.contains('bunless') && !nameLower.contains('steak') && !descLower.contains('low-carb')) {
          if (nameLower.contains('rice') || nameLower.contains('noodle') || nameLower.contains('pasta') || nameLower.contains('toast') || nameLower.contains('fruit') || nameLower.contains('oatmeal') || nameLower.contains('potato')) {
            return false;
          }
      }
      
      // c) Dietary Restriction Filter 
      // Split the single string into keywords for accurate checking
      final restrictionKeywords = userInfo.dietaryRestrictions.toLowerCase()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      
      for (var keyword in restrictionKeywords) {
          if (nameLower.contains(keyword) || descLower.contains(keyword)) {
              return false; // Found a restriction match, exclude this food
          }
      }

      // d) Allergy Filter (FIXED LOGIC)
      // Split the single string into keywords for accurate checking
      final allergyKeywords = userInfo.allergies.toLowerCase()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      
      for (var keyword in allergyKeywords) {
          if (nameLower.contains(keyword) || descLower.contains(keyword)) {
              return false; // Found an allergen match, exclude this food
          }
      }

      // e) Condition Filter (Checking the single conditions string)
      if (userInfo.otherConditions.toLowerCase().contains('diabetes') && (nameLower.contains('sweetened') || nameLower.contains('sugar') || nameLower.contains('cake') || nameLower.contains('donut') || nameLower.contains('pudding'))) {
          return false;
      }


      return true; // Pass all filters
    }).toList();

    // 4. Sort Remaining Foods
    filteredFoods.sort((a, b) => 
        (a.kcal - mealCalorieTarget).abs().compareTo((b.kcal - mealCalorieTarget).abs()));
    
    // 5. Return Top 7, converted to Map<String, dynamic>
    return filteredFoods
        .take(7)
        .map((food) => {
              'name': food.name,
              'kcal': food.kcal,
              'desc': food.desc,
              'icon': food.icon,
              'type': food.type,
            })
        .toList();
  }
  
  // --- Helper Functions for Calorie Calculation ---

  // Calculates BMR using Mifflin-St Jeor
  double _calculateBMR(double weight, double height, int age, String sex) {
    if (sex == 'Male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else if (sex == 'Female') {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161; 
    }
  }

  // Calculates TDEE (Total Daily Energy Expenditure)
  double _calculateTDEE(UserInfoData userInfo) {
    final bmr = _calculateBMR(userInfo.currentWeight, userInfo.heightCm, userInfo.age, userInfo.sex);
    
    final Map<String, double> activityFactors = {
      "Sedentary": 1.2,
      "Lightly Active": 1.375,
      "Moderately Active": 1.55,
      "Very Active": 1.725,
      "Extra Active": 1.9,
    };
    return bmr * (activityFactors[userInfo.activityLevel] ?? 1.55);
  }
}






