import 'package:flutter/material.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';

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
      gifUrl: "https://media.tenor.com/fjZr42ZT3HAAAAAi/hiit-burpees.gif",
    ),
    Exercise(
      name: "Push Ups",
      type: "Strength",
      duration: 20,
      sets: 3,
      reps: 12,
      difficulty: "Medium",
      gifUrl: "https://media.tenor.com/J-pjAg3tbnMAAAAi/workout.gif",
    ),
    Exercise(
      name: "Squats",
      type: "Legs",
      duration: 25,
      sets: 3,
      reps: 20,
      difficulty: "Easy",
      gifUrl: "https://media.tenor.com/qmkgaJWFgX4AAAAi/legs-workout.gif",
    ),
    Exercise(
      name: "Plank",
      type: "Core",
      duration: 40,
      sets: 2,
      reps: 1,
      difficulty: "Hard",
      gifUrl: "https://media.tenor.com/Ot6fQ3YhKXcAAAAC/plank.gif",
    ),
    Exercise(
      name: "Jumping Jacks",
      type: "Cardio",
      duration: 20,
      sets: 2,
      reps: 20,
      difficulty: "Easy",
      gifUrl: "https://media.tenor.com/3x82cV2I5zQAAAAC/jumping-jacks.gif",
    ),
    Exercise(
      name: "Lunges",
      type: "Legs",
      duration: 25,
      sets: 3,
      reps: 15,
      difficulty: "Medium",
      gifUrl: "https://media.tenor.com/ztc5nD0osL8AAAAC/lunges.gif",
    ),
  ];

  String searchQuery = "";

  // Map type → icon + color
  final Map<String, Map<String, dynamic>> typeStyles = {
    "Cardio": {"icon": Icons.favorite, "color": Colors.redAccent},
    "Strength": {"icon": Icons.fitness_center, "color": Colors.blueAccent},
    "Legs": {"icon": Icons.directions_run, "color": Colors.green},
    "Core": {"icon": Icons.accessibility_new, "color": Colors.orangeAccent},
  };

  @override
  Widget build(BuildContext context) {
    final exercises = allExercises
        .where((e) =>
            e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.type.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercises"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search exercises...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final typeStyle = typeStyles[exercise.type] ?? {};
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: (typeStyle["color"] as Color?)?.withOpacity(0.15) ??
                      Colors.grey[200],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeStyle["color"] ?? Colors.grey,
                      child: Icon(
                        typeStyle["icon"] ?? Icons.sports,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${exercise.type} • ${exercise.difficulty}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExerciseDetailScreen(exercise: exercise),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
