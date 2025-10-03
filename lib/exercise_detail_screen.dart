import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/exercise.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late int remainingTime;
  Timer? _timer;
  bool isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.exercise.duration;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.exercise.duration),
    );
  }

  void startTimer() {
    if (isRunning) return;

    _controller.reverse(
      from: remainingTime / widget.exercise.duration,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        timer.cancel();
        _playAlarm();
      }
    });

    setState(() => isRunning = true);
  }

  void pauseTimer() {
    _timer?.cancel();
    _controller.stop();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    _timer?.cancel();
    _audioPlayer.stop();
    _controller.reset();
    setState(() {
      remainingTime = widget.exercise.duration;
      isRunning = false;
    });
  }

  Future<void> _playAlarm() async {
    await _audioPlayer.play(AssetSource("sounds/alarm.mp3"));

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Time's Up!"),
          content: const Text("Your exercise duration is finished."),
          actions: [
            TextButton(
              onPressed: () {
                _audioPlayer.stop();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.exercise.gifUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(widget.exercise.gifUrl!,
                    height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            Text(
              "Type: ${widget.exercise.type}\n"
              "Sets: ${widget.exercise.sets} • Reps: ${widget.exercise.reps}\n"
              "Difficulty: ${widget.exercise.difficulty}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            // 🔵 Enhanced Circular Timer
            SizedBox(
              height: 250,
              width: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 14,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade300,
                      ),
                    ),
                  ),

                  // Foreground animated circle
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return SizedBox(
                        height: 250,
                        width: 250,
                        child: CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 14,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isRunning
                                ? Colors.blueAccent // Running
                                : Colors.grey,      // Paused
                          ),
                        ),
                      );
                    },
                  ),

                  // Countdown text inside
                  Text(
                    "$remainingTime s",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(isRunning ? "Pause" : "Play"),
                  onPressed: isRunning ? pauseTimer : startTimer,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset"),
                  onPressed: resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
