// models/exercise.dart
class Exercise {
  final String name;
  final String type;
  final int duration;
  final int sets;
  final int reps;
  final String difficulty;
  final String? gifUrl;

  const Exercise({
    required this.name,
    required this.type,
    required this.duration,
    required this.sets,
    required this.reps,
    required this.difficulty,
    this.gifUrl,
  });

  // Add this method to your Exercise class
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'duration': duration,
      'sets': sets,
      'reps': reps,
      'difficulty': difficulty,
      'gifUrl': gifUrl,
    };
  }

  // Add this factory constructor to your Exercise class
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      sets: (map['sets'] as num?)?.toInt() ?? 0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      difficulty: map['difficulty'] as String? ?? '',
      gifUrl: map['gifUrl'] as String?,
    );
  }

  // Add this copyWith method to your Exercise class
  Exercise copyWith({
    String? name,
    String? type,
    int? duration,
    int? sets,
    int? reps,
    String? difficulty,
    String? gifUrl,
  }) {
    return Exercise(
      name: name ?? this.name,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      difficulty: difficulty ?? this.difficulty,
      gifUrl: gifUrl ?? this.gifUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.name == name &&
        other.type == type &&
        other.duration == duration &&
        other.sets == sets &&
        other.reps == reps &&
        other.difficulty == difficulty;
  }

  @override
  int get hashCode {
    return Object.hash(name, type, duration, sets, reps, difficulty);
  }
}