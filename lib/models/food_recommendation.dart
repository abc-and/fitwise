// lib/models/food/food_recommendations.dart
import 'package:flutter/material.dart';

class FoodRecommendation {
  final String name;
  final int kcal;
  final String desc;
  final IconData icon;
  final String type; // morning / afternoon / evening / any

  FoodRecommendation({
    required this.name,
    required this.kcal,
    required this.desc,
    required this.icon,
    required this.type,
  });
}

// Master food list with 25+ items
final List<FoodRecommendation> allFoods = [
  // Morning foods
  FoodRecommendation(
    name: 'Oatmeal',
    kcal: 280,
    desc: 'Filling breakfast rich in fiber',
    icon: Icons.breakfast_dining,
    type: 'morning',
  ),
  FoodRecommendation(
    name: 'Greek Yogurt',
    kcal: 150,
    desc: 'Protein-rich dairy for a light start',
    icon: Icons.local_cafe,
    type: 'morning',
  ),
  FoodRecommendation(
    name: 'Scrambled Eggs',
    kcal: 200,
    desc: 'High-protein breakfast option',
    icon: Icons.egg,
    type: 'morning',
  ),
  FoodRecommendation(
    name: 'Avocado Toast',
    kcal: 250,
    desc: 'Healthy fats and whole grain',
    icon: Icons.grass,
    type: 'morning',
  ),
  FoodRecommendation(
    name: 'Fruit Bowl',
    kcal: 180,
    desc: 'Vitamins and antioxidants',
    icon: Icons.apple,
    type: 'morning',
  ),

  // Afternoon foods
  FoodRecommendation(
    name: 'Grilled Chicken Wrap',
    kcal: 420,
    desc: 'Lean protein lunch option',
    icon: Icons.lunch_dining,
    type: 'afternoon',
  ),
  FoodRecommendation(
    name: 'Quinoa Salad',
    kcal: 350,
    desc: 'High in fiber and plant protein',
    icon: Icons.eco,
    type: 'afternoon',
  ),
  FoodRecommendation(
    name: 'Turkey Sandwich',
    kcal: 400,
    desc: 'Balanced protein and carbs',
    icon: Icons.fastfood,
    type: 'afternoon',
  ),
  FoodRecommendation(
    name: 'Veggie Soup',
    kcal: 220,
    desc: 'Light and warm meal',
    icon: Icons.soup_kitchen,
    type: 'afternoon',
  ),
  FoodRecommendation(
    name: 'Brown Rice & Tofu',
    kcal: 380,
    desc: 'Plant-based balanced meal',
    icon: Icons.set_meal,
    type: 'afternoon',
  ),

  // Evening foods
  FoodRecommendation(
    name: 'Steamed Fish',
    kcal: 360,
    desc: 'Light dinner with omega-3',
    icon: Icons.set_meal,
    type: 'evening',
  ),
  FoodRecommendation(
    name: 'Veg Stir Fry',
    kcal: 300,
    desc: 'Low-calorie vegetable mix',
    icon: Icons.soup_kitchen,
    type: 'evening',
  ),
  FoodRecommendation(
    name: 'Grilled Salmon',
    kcal: 420,
    desc: 'Rich in protein and omega-3',
    icon: Icons.local_dining,
    type: 'evening',
  ),
  FoodRecommendation(
    name: 'Chickpea Curry',
    kcal: 370,
    desc: 'Plant protein with spices',
    icon: Icons.restaurant_menu,
    type: 'evening',
  ),
  FoodRecommendation(
    name: 'Cauliflower Rice Bowl',
    kcal: 260,
    desc: 'Low-carb alternative for dinner',
    icon: Icons.rice_bowl,
    type: 'evening',
  ),

];
