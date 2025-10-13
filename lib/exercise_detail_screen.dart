import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme.dart';
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
  
  // 💡 VIDEO STATE VARIABLES
  late VideoPlayerController _videoPlayerController;
  String? userSex;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  // Static maps for filename lookup (You must ensure files are named exactly like this)
  static const Map<String, String> _femaleVideoMap = {
    "Bicep Curl": "Female_Bicep_Curls.mp4",
    "Bicycle Crunch": "Female_Bicycle_Crunches.mp4",
    "Box Jump": "Female_Box_Jump.mp4",
    "Bulgarian Squat": "Female_Bulgarian_Squats.mp4",
    "Burpee": "Female_Burpees.mp4",
    "Butt Kick": "Female_Butt_Kicks.mp4",
    "Calf Raise": "Female_Calf_Raises.mp4",
    "Curl Ups": "Female_Curl_Ups.mp4",
    "Diamond Push Up": "Female_Diamond_Push_Ups.mp4",
    "Dip": "Female_Dips.mp4",
    "High Knee": "Female_High_Knees.mp4",
    "Jump Rope": "Female_Jump_Rope.mp4",
    "Jumping Jack": "Female_Jumping_Jacks.mp4",
    "Leg Raise": "Female_Leg_Raise.mp4",
    "Lunge": "Female_Lunges.mp4",
    "Mountain Climber": "Female_Mountain_Climbers.mp4",
    "Plank": "Female_Planks.mp4",
    "Push Up": "Female_Push_Up.mp4",
    "Russian Twist": "Female_Russian_Twists.mp4",
    "Shoulder Press": "Female_Shoulder_Press.mp4",
    "Side Plank": "Female_Side_Planks.mp4",
    "Sprint Interval": "Female_Sprint_Intervals.mp4",
    "Squat": "Female_Squats.mp4",
    "Wall Sit": "Female_Wall_Sit.mp4",
  };

  static const Map<String, String> _maleVideoMap = {
    "Bicep Curl": "Male_Bicep_Curls.mp4",
    "Bicycle Crunch": "Male_Bicycle_Crunches.mp4",
    "Box Jump": "Male_Box_Jumps.mp4",
    "Bulgarian Squat": "Male_Bulgarian_Squats.mp4",
    "Burpee": "Male_Burpees.mp4",
    "Butt Kick": "Male_Butt_Kicks.mp4",
    "Calf Raise": "Male_Calf_Raise.mp4",
    "Curl Ups": "Male_Curl_ups.mp4",
    "Diamond Push Up": "Male_Diamond_Push_Up.mp4",
    "Dip": "Male_Dips.mp4",
    "High Knee": "Male_High_Knees.mp4",
    "Jump Rope": "Male_Jump_Rope.mp4",
    "Jumping Jack": "Male_Jumping-Jacks.mp4",
    "Leg Raise": "Male_Leg_Raise.mp4",
    "Lunge": "Male_Lunges.mp4",
    "Mountain Climber": "Male_Mountain_Climbers.mp4",
    "Plank": "Male_Planks.mp4",
    "Push Up": "Male_Push-Up.mp4", 
    "Russian Twist": "Male_Russian_Twists.mp4",
    "Shoulder Press": "Male_Shoulder_Press.mp4",
    "Side Plank": "Male_Side_Planks.mp4",
    "Sprint Interval": "Male_Sprint_Intervals.mp4",
    "Squat": "Male_Squats.mp4",
    "Wall Sit": "Male_Wall_Sits.mp4",
  };

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

    // 💡 START VIDEO LOADING
    _loadUserSexAndVideo();
  }
  
  // 💡 NEW METHOD: Loads user sex from Firestore and then loads the corresponding video asset.
  Future<void> _loadUserSexAndVideo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('user_info')
            .doc(user.uid)
            .get();
        userSex = doc.exists ? doc['sex'] : null;
      }

      final isFemale = userSex?.toLowerCase() == "female";
      final folder = isFemale ? "female_exercises" : "male_exercises";
      final fileNameMap = isFemale ? _femaleVideoMap : _maleVideoMap;
      final exerciseKey = widget.exercise.name;
      final fileName = fileNameMap[exerciseKey];

      if (fileName != null) {
        final videoPath = "assets/$folder/$fileName";
        _videoPlayerController = VideoPlayerController.asset(videoPath)
          ..setLooping(true)
          ..setVolume(1.0) // Enable full volume
          ..initialize().then((_) {
            _videoPlayerController.play();
            if (mounted) setState(() => _isVideoInitialized = true);
          })
          .catchError((error) {
            debugPrint("VideoPlayerController init failed for path: $videoPath. Error: $error");
            if (mounted) setState(() => _hasVideoError = true);
          });
      } else {
        if (mounted) setState(() => _hasVideoError = true);
      }
    } catch (e) {
      debugPrint("General video load error: $e");
      if (mounted) setState(() => _hasVideoError = true);
    }
  }

  void startTimer() {
    if (isRunning) return;

    _controller.reverse(
      from: remainingTime / widget.exercise.duration,
    );
    
    // Play video if initialized
    if (_isVideoInitialized && !_hasVideoError) {
      _videoPlayerController.play();
    }

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
    // Pause video
    if (_isVideoInitialized && !_hasVideoError) {
      _videoPlayerController.pause();
    }
    setState(() => isRunning = false);
  }

  void resetTimer() {
    _timer?.cancel();
    _audioPlayer.stop();
    _controller.reset();
    // Reset video
    if (_isVideoInitialized && !_hasVideoError) {
      _videoPlayerController.seekTo(Duration.zero);
      _videoPlayerController.pause();
    }
    setState(() {
      remainingTime = widget.exercise.duration;
      isRunning = false;
    });
  }

  Future<void> _playAlarm() async {
    // Stop video when alarm sounds
    if (_isVideoInitialized && !_hasVideoError) {
      _videoPlayerController.pause();
    }
    await _audioPlayer.play(AssetSource("sounds/alarm.mp3"));

    if (mounted) {
      final theme = Provider.of<ThemeManager>(context, listen: false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.accentBlue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Time's Up!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          content: Text(
            "Great job! You've completed this exercise.",
            style: TextStyle(
              fontSize: 16,
              color: theme.secondaryText,
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
                foregroundColor: Colors.white,
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
    // 💡 Dispose video controller if it was initialized
    if (_isVideoInitialized && !_hasVideoError) {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "easy":
        return AppColors.green;
      case "medium":
        return AppColors.orange;
      case "hard":
        return AppColors.orange;
      default:
        return AppColors.accentBlue;
    }
  }
  
  // 💡 NEW METHOD: Builds the background content (Video or GIF)
  Widget _buildBackgroundContent() {
    if (_hasVideoError) {
      // Fallback to GIF/Image on video error
      if (widget.exercise.gifUrl != null) {
        return Image.network(
          widget.exercise.gifUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      }
      return _buildErrorPlaceholder();
    }

    if (_isVideoInitialized) {
      // Display the video once initialized
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoPlayerController.value.size.width,
            height: _videoPlayerController.value.size.height,
            child: VideoPlayer(_videoPlayerController),
          ),
        ),
      );
    }

    // Loading state or initial GIF display
    if (widget.exercise.gifUrl != null) {
      return Image.network(
        widget.exercise.gifUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildLoadingPlaceholder(),
      );
    }
    return _buildLoadingPlaceholder();
  }
  
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.accentBlue.withOpacity(0.3),
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: AppColors.accentBlue),
    );
  }
  
  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.accentBlue.withOpacity(0.3),
      child: Icon(
        Icons.fitness_center,
        size: 100,
        color: AppColors.accentBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
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
                  color: theme.primaryBackground.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.primaryText),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 💡 Use the new background content method here
                  _buildBackgroundContent(),
                  
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.primaryBackground.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Text Content
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: TextStyle(
                            color: theme.primaryText,
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
                                color: theme.primaryBackground,
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
                                style: TextStyle(
                                  color: theme.primaryText,
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
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.repeat,
                          "Sets",
                          "${widget.exercise.sets}",
                          AppColors.accentPurple,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.fitness_center,
                          "Reps",
                          "${widget.exercise.reps}",
                          AppColors.orange,
                          theme,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Timer Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          spreadRadius: 2,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Exercise Timer",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText,
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
                                          theme.borderColor,
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
                                                  : theme.tertiaryText,
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
                                                : theme.primaryText,
                                          ),
                                        ),
                                        Text(
                                          "seconds",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: theme.secondaryText,
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
                                                : theme.borderColor,
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
                                                    : theme.tertiaryText,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isRunning ? "In Progress" : "Paused",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isRunning
                                                      ? AppColors.accentBlue
                                                      : theme.tertiaryText,
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
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
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
                              child: Icon(
                                Icons.tips_and_updates,
                                color: theme.primaryText,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Pro Tips",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTipItem("Maintain proper form throughout", theme),
                        _buildTipItem("Keep your core engaged", theme),
                        _buildTipItem("Breathe steadily - exhale on exertion", theme),
                        _buildTipItem("Stay hydrated before and after", theme),
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

  Widget _buildStatCard(IconData icon, String label, String value, Color color, ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
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
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.secondaryText,
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
          foregroundColor: Colors.white,
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

  Widget _buildTipItem(String text, ThemeManager theme) {
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
            child: Icon(
              Icons.check,
              color: theme.primaryText,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: theme.primaryText,
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
        return AppColors.orange;
      case "strength":
        return AppColors.accentBlue;
      case "legs":
        return AppColors.accentPurple;
      case "core":
        return AppColors.accentCyan;
      default:
        return AppColors.accentBlue;
    }
  }
}