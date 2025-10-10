// ...existing code...
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../constants/app_colors.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
final List<Exercise> allExercises = [
    Exercise(
      name: "Burpees",
      type: "Cardio",
      duration: 30,
      sets: 3,
      reps: 15,
      difficulty: "Hard",
      gifUrl: "https://i.pinimg.com/originals/f4/b0/f3/f4b0f3e8d89b0a6d7f3b5b5e5f5f5f5f.gif",
    ),
    Exercise(
      name: "Push Ups",
      type: "Strength",
      duration: 20,
      sets: 3,
      reps: 12,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/18/27/be/1827be8d4f5f3c8f7d3f3f3f3f3f3f3f.gif",
    ),
    Exercise(
      name: "Squats",
      type: "Legs",
      duration: 25,
      sets: 3,
      reps: 20,
      difficulty: "Easy",
      gifUrl: "https://i.pinimg.com/originals/b4/3f/7f/b43f7f9b0f3c8d7f3f3f3f3f3f3f3f3f.gif",
    ),
    Exercise(
      name: "Plank",
      type: "Core",
      duration: 40,
      sets: 2,
      reps: 1,
      difficulty: "Hard",
      gifUrl: "https://i.pinimg.com/originals/1e/5c/c8/1e5cc8f3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Jumping Jacks",
      type: "Cardio",
      duration: 20,
      sets: 2,
      reps: 20,
      difficulty: "Easy",
      gifUrl: "https://i.pinimg.com/originals/85/1e/17/851e17c6f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Lunges",
      type: "Legs",
      duration: 25,
      sets: 3,
      reps: 15,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/9e/3f/7d/9e3f7df3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Mountain Climbers",
      type: "Cardio",
      duration: 30,
      sets: 3,
      reps: 20,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/6c/8a/1d/6c8a1df3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Bicep Curls",
      type: "Strength",
      duration: 20,
      sets: 3,
      reps: 12,
      difficulty: "Easy",
      gifUrl: "https://i.pinimg.com/originals/4d/2e/1f/4d2e1ff3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Russian Twists",
      type: "Core",
      duration: 30,
      sets: 3,
      reps: 20,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/7a/2c/5e/7a2c5ef3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "High Knees",
      type: "Cardio",
      duration: 25,
      sets: 3,
      reps: 30,
      difficulty: "Easy",
      gifUrl: "https://i.pinimg.com/originals/3b/4d/8f/3b4d8ff3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Diamond Push Ups",
      type: "Strength",
      duration: 25,
      sets: 3,
      reps: 10,
      difficulty: "Hard",
      gifUrl: "https://i.pinimg.com/originals/5c/7e/2a/5c7e2af3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Bulgarian Split Squats",
      type: "Legs",
      duration: 30,
      sets: 3,
      reps: 12,
      difficulty: "Hard",
      gifUrl: "https://i.pinimg.com/originals/8d/5f/3c/8d5f3cf3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Bicycle Crunches",
      type: "Core",
      duration: 30,
      sets: 3,
      reps: 20,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/2f/6a/4b/2f6a4bf3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Box Jumps",
      type: "Legs",
      duration: 30,
      sets: 3,
      reps: 10,
      difficulty: "Hard",
      gifUrl: "https://i.pinimg.com/originals/9a/1d/7e/9a1d7ef3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Dips",
      type: "Strength",
      duration: 25,
      sets: 3,
      reps: 12,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/4e/8c/1f/4e8c1ff3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Jump Rope",
      type: "Cardio",
      duration: 45,
      sets: 3,
      reps: 50,
      difficulty: "Easy",
      gifUrl: "https://i.pinimg.com/originals/6f/3a/9d/6f3a9df3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Leg Raises",
      type: "Core",
      duration: 25,
      sets: 3,
      reps: 15,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/1c/5d/8e/1c5d8ef3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Calf Raises",
      type: "Legs",
      duration: 20,
      sets: 4,
      reps: 20,
      difficulty: "Easy",
      gifUrl: "https://i.pinimg.com/originals/7b/4e/2f/7b4e2ff3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Shoulder Press",
      type: "Strength",
      duration: 25,
      sets: 3,
      reps: 12,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/3d/6c/1a/3d6c1af3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Sprint Intervals",
      type: "Cardio",
      duration: 20,
      sets: 5,
      reps: 1,
      difficulty: "Hard",
      gifUrl: "https://i.pinimg.com/originals/5e/7f/3b/5e7f3bf3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Side Plank",
      type: "Core",
      duration: 30,
      sets: 3,
      reps: 2,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/8f/2d/6a/8f2d6af3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Wall Sits",
      type: "Legs",
      duration: 45,
      sets: 3,
      reps: 1,
      difficulty: "Medium",
      gifUrl: "https://i.pinimg.com/originals/2a/9e/4c/2a9e4cf3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Pull Ups",
      type: "Strength",
      duration: 25,
      sets: 3,
      reps: 8,
      difficulty: "Hard",
      gifUrl: "https://i.pinimg.com/originals/6d/1f/8b/6d1f8bf3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
    Exercise(
      name: "Butt Kicks",
      type: "Cardio",
      duration: 25,
      sets: 3,
      reps: 30,
      difficulty: "Easy",
      gifUrl: "https://i.pinimg.com/originals/4f/7c/3d/4f7c3df3f3f3f3f3f3f3f3f3f3f3f3f3.gif",
    ),
  ];

  String searchQuery = "";
  String selectedFilter = "All";

  final Map<String, Map<String, dynamic>> typeStyles = {
    "Cardio": {"icon": Icons.favorite, "color": AppColors.red},
    "Strength": {"icon": Icons.fitness_center, "color": AppColors.accentBlue},
    "Legs": {"icon": Icons.directions_run, "color": AppColors.primary},
    "Core": {"icon": Icons.accessibility_new, "color": AppColors.orange},
  };

  @override
  Widget build(BuildContext context) {
    final exercises = allExercises.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.type.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter = selectedFilter == "All" || e.type == selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Exercise Library",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search exercises...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip("All"),
                      _buildFilterChip("Cardio"),
                      _buildFilterChip("Strength"),
                      _buildFilterChip("Legs"),
                      _buildFilterChip("Core"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${exercises.length} Exercises",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, 
                        size: 18, 
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Stay Active",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No exercises found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final typeStyle = typeStyles[exercise.type] ?? {};
                      return _buildExerciseCard(exercise, typeStyle);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => selectedFilter = label);
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.secondary,
        checkmarkColor: Colors.white,
        elevation: isSelected ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, Map<String, dynamic> typeStyle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(exercise: exercise),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: (typeStyle["color"] as Color?)?.withOpacity(0.1) ?? AppColors.lightGray,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: exercise.gifUrl != null
                      ? Image.network(
                          exercise.gifUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              typeStyle["icon"] ?? Icons.sports,
                              size: 40,
                              color: typeStyle["color"] ?? AppColors.mediumGray,
                            );
                          },
                        )
                      : Icon(
                          typeStyle["icon"] ?? Icons.sports,
                          size: 40,
                          color: typeStyle["color"] ?? AppColors.mediumGray,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeStyle["color"]?.withOpacity(0.15) ?? AppColors.lightGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                typeStyle["icon"] ?? Icons.sports,
                                size: 14,
                                color: typeStyle["color"] ?? AppColors.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                exercise.type,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: typeStyle["color"] ?? AppColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(exercise.difficulty).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise.difficulty,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getDifficultyColor(exercise.difficulty),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: AppColors.darkGray),
                        const SizedBox(width: 4),
                        Text(
                          "${exercise.duration}s",
                          style: TextStyle(fontSize: 13, color: AppColors.darkGray),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.repeat, size: 16, color: AppColors.darkGray),
                        const SizedBox(width: 4),
                        Text(
                          "${exercise.sets}×${exercise.reps}",
                          style: TextStyle(fontSize: 13, color: AppColors.darkGray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "easy":
        return AppColors.primary;
      case "medium":
        return AppColors.orange;
      case "hard":
        return AppColors.red;
      default:
        return AppColors.mediumGray;
    }
  }
}