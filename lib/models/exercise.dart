class Exercise {
  String name;
  String type;
  int duration; // in minutes
  int sets;
  int reps;
  String? videoUrl;
  String? gifUrl;
  String difficulty;

  Exercise({
    required this.name,
    required this.type,
    required this.duration,
    required this.sets,
    required this.reps,
    this.videoUrl,
    this.gifUrl,
    required this.difficulty,
  });
}
