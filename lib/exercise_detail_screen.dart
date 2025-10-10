import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/exercise.dart';
import '../constants/app_colors.dart';

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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.exercise.duration;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.exercise.duration),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.cardLight,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.accentBlue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Time's Up!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: const Text(
            "Great job! You've completed this exercise.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.mediumGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _audioPlayer.stop();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Awesome!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "easy":
        return AppColors.green;
      case "medium":
        return AppColors.orange;
      case "hard":
        return AppColors.error;
      default:
        return AppColors.mediumGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.accentBlue,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.exercise.gifUrl != null)
                    Image.network(
                      widget.exercise.gifUrl!,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.accentBlue.withOpacity(0.3),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 100,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.exercise.type,
                                style: TextStyle(
                                  color: _getTypeColor(),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(widget.exercise.difficulty)
                                    .withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.exercise.difficulty,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.timer,
                          "Duration",
                          "${widget.exercise.duration}s",
                          AppColors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.repeat,
                          "Sets",
                          "${widget.exercise.sets}",
                          AppColors.accentPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.fitness_center,
                          "Reps",
                          "${widget.exercise.reps}",
                          AppColors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Timer Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Exercise Timer",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Circular Timer
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isRunning ? _scaleAnimation.value : 1.0,
                              child: SizedBox(
                                height: 240,
                                width: 240,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Background circle
                                    SizedBox(
                                      height: 240,
                                      width: 240,
                                      child: CircularProgressIndicator(
                                        value: 1.0,
                                        strokeWidth: 16,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.lightGray,
                                        ),
                                      ),
                                    ),

                                    // Animated progress circle
                                    AnimatedBuilder(
                                      animation: _controller,
                                      builder: (context, child) {
                                        return SizedBox(
                                          height: 240,
                                          width: 240,
                                          child: CircularProgressIndicator(
                                            value: _controller.value,
                                            strokeWidth: 16,
                                            backgroundColor: Colors.transparent,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              isRunning
                                                  ? AppColors.accentBlue
                                                  : AppColors.mediumGray,
                                            ),
                                            strokeCap: StrokeCap.round,
                                          ),
                                        );
                                      },
                                    ),

                                    // Center content
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "$remainingTime",
                                          style: TextStyle(
                                            fontSize: 64,
                                            fontWeight: FontWeight.bold,
                                            color: isRunning
                                                ? AppColors.accentBlue
                                                : AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          "seconds",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.mediumGray,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isRunning
                                                ? AppColors.accentBlue.withOpacity(0.15)
                                                : AppColors.lightGray,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isRunning ? Icons.play_arrow : Icons.pause,
                                                size: 16,
                                                color: isRunning
                                                    ? AppColors.accentBlue
                                                    : AppColors.mediumGray,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isRunning ? "In Progress" : "Paused",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isRunning
                                                      ? AppColors.accentBlue
                                                      : AppColors.mediumGray,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Control Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlButton(
                              icon: isRunning ? Icons.pause : Icons.play_arrow,
                              label: isRunning ? "Pause" : "Start",
                              color: AppColors.accentBlue,
                              onPressed: isRunning ? pauseTimer : startTimer,
                            ),
                            const SizedBox(width: 16),
                            _buildControlButton(
                              icon: Icons.refresh,
                              label: "Reset",
                              color: AppColors.orange,
                              onPressed: resetTimer,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tips_and_updates,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Pro Tips",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTipItem("Maintain proper form throughout"),
                        _buildTipItem("Keep your core engaged"),
                        _buildTipItem("Breathe steadily - exhale on exertion"),
                        _buildTipItem("Stay hydrated before and after"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.textPrimary,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.exercise.type.toLowerCase()) {
      case "cardio":
        return AppColors.red;
      case "strength":
        return AppColors.accentBlue;
      case "legs":
        return AppColors.accentPurple;
      case "core":
        return AppColors.orange;
      default:
        return AppColors.mediumGray;
    }
  }
}