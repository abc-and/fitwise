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

const int _cooldownDuration = 10;

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback? onComplete;
  final int? setsRemaining;
  final int? totalSets;
  final bool? inCooldown;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.onComplete,
    this.setsRemaining,
    this.totalSets,
    this.inCooldown,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with TickerProviderStateMixin {
  late int remainingTime;
  Timer? _timer;
  bool isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _controller;
  bool _controllerInitialized = false;

  // Video State Variables
  VideoPlayerController? _videoPlayerController;
  String? userSex;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _isVideoMuted = false;

  // Exercise State Variables - COMPLETELY RESET for each exercise
  late int _currentSet;
  late int _totalSets;
  bool _isRestPeriod = false;
  bool _exerciseCompleted = false;
  bool _showCompletionScreen = false;
  bool _isFinalRestPeriod = false;

  // Track current exercise to detect changes
  Exercise? _currentExercise;
  bool _isInitialized = false;

  // Static maps for filename lookup
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
    _initializeExerciseState();
  }

  @override
  void didUpdateWidget(ExerciseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if exercise changed completely (not just sets remaining)
    if (widget.exercise != oldWidget.exercise) {
      debugPrint('=== EXERCISE COMPLETELY CHANGED ===');
      debugPrint('From: ${oldWidget.exercise.name} to: ${widget.exercise.name}');
      
      _cleanupCurrentState();
      _initializeExerciseState();
    } else if ((widget.setsRemaining != oldWidget.setsRemaining || 
               widget.inCooldown != oldWidget.inCooldown) && !_exerciseCompleted) {
      debugPrint('=== EXERCISE STATE UPDATED ===');
      debugPrint('Sets remaining changed from ${oldWidget.setsRemaining} to ${widget.setsRemaining}');
      debugPrint('In cooldown changed from ${oldWidget.inCooldown} to ${widget.inCooldown}');
      
      _cleanupCurrentState();
      _initializeExerciseState();
    }
  }

  void _initializeExerciseState() {
    if (_isInitialized && _currentExercise == widget.exercise) return;
    
    _cleanupCurrentState();
    
    try {
      _currentExercise = widget.exercise;
      
      _totalSets = widget.totalSets ?? widget.exercise.sets;
      
      // SIMPLIFIED LOGIC - Always start fresh for new exercise
      _currentSet = 1;
      _exerciseCompleted = false;
      _showCompletionScreen = false;
      _isRestPeriod = false;
      _isFinalRestPeriod = false;
      remainingTime = widget.exercise.duration;
      
      debugPrint('🟢 STARTING FRESH EXERCISE: ${widget.exercise.name}');
      debugPrint('   Total sets: $_totalSets');
      debugPrint('   Starting with Set 1');

      // Initialize animation controller
      _initAnimationController(remainingTime);
      
      // Load video
      _loadUserSexAndVideo();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error in _initializeExerciseState: $e');
      _isInitialized = false;
    }
  }

  void _cleanupCurrentState() {
    debugPrint('🧹 Cleaning up current state');
    _cleanupTimerAndAnimation();
    
    if (_videoPlayerController != null) {
      _videoPlayerController!.pause();
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    
    _isVideoInitialized = false;
    _hasVideoError = false;
    _isInitialized = false;
    
    _audioPlayer.stop();
  }

  void _initAnimationController(int duration) {
    if (_controllerInitialized) {
      _controller.dispose();
      _controllerInitialized = false;
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: duration),
    );
    
    _controllerInitialized = true;
    _controller.value = 1.0;
  }

  void _startRestPeriod() {
    _cleanupTimerAndAnimation();
    
    setState(() {
      _isRestPeriod = true;
      _isFinalRestPeriod = (_currentSet >= _totalSets); // Final rest after last set
      remainingTime = _cooldownDuration;
      isRunning = false;
    });

    debugPrint('🛌 Starting rest period after Set $_currentSet/$_totalSets');
    if (_isFinalRestPeriod) {
      debugPrint('   🎯 This is the FINAL rest period before completion screen');
    }

    _initAnimationController(_cooldownDuration);

    // Don't pause video during rest, just adjust volume based on mute setting
    if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
      _videoPlayerController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
      _videoPlayerController!.play();
    }

    _startTimer();
  }

  void _startNextSet() {
    _cleanupTimerAndAnimation();
    
    setState(() {
      _isRestPeriod = false;
      _isFinalRestPeriod = false;
      remainingTime = widget.exercise.duration;
      isRunning = false;
    });

    debugPrint('💪 Starting Set $_currentSet/$_totalSets');

    _initAnimationController(widget.exercise.duration);

    // Unmute video for exercise (unless user muted it)
    if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
      _videoPlayerController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
      _videoPlayerController!.seekTo(Duration.zero);
      _videoPlayerController!.play();
    }
  }

  void _completeExercise() {
    _cleanupTimerAndAnimation();
    
    setState(() {
      _exerciseCompleted = true;
      _showCompletionScreen = true;
      _isRestPeriod = false;
      _isFinalRestPeriod = false;
      isRunning = false;
    });

    debugPrint('🎉 Exercise completed: ${widget.exercise.name}');
    debugPrint('🎉 All $_totalSets sets completed');

    _playCompletionAlarm();
  }

  void _cleanupTimerAndAnimation() {
    _timer?.cancel();
    _timer = null;
    
    if (_controllerInitialized) {
      _controller.stop();
    }
  }

  void _handleTimerCompletion() {
    _cleanupTimerAndAnimation();
    _audioPlayer.stop();

    if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
      _videoPlayerController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
    }

    if (_isRestPeriod) {
      // Rest period finished
      if (_isFinalRestPeriod) {
        // Final rest period completed - show completion screen
        debugPrint('✅ Final rest completed, showing completion screen');
        _completeExercise();
      } else {
        // Regular rest period - increment set and start next exercise set
        setState(() {
          _currentSet++;
        });
        debugPrint('🔄 Rest completed, starting Set $_currentSet/$_totalSets');
        _startNextSet();
      }
    } else {
      // Exercise set finished - start rest period
      debugPrint('⏱️ Set $_currentSet/$_totalSets completed, starting rest');
      _startRestPeriod();
    }
  }

  void _toggleVideoMute() {
    if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
      setState(() {
        _isVideoMuted = !_isVideoMuted;
      });
      
      // Apply mute/unmute immediately
      _videoPlayerController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
      
      debugPrint('🔊 Video muted: $_isVideoMuted');
    }
  }

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
          ..setVolume(_isVideoMuted ? 0.0 : 1.0) // Set initial volume based on mute setting
          ..initialize().then((_) {
            if (mounted) {
              setState(() => _isVideoInitialized = true);
              // Always play video, regardless of rest/exercise state
              if (_videoPlayerController != null) {
                _videoPlayerController!.play();
              }
            }
          }).catchError((error) {
            debugPrint("❌ Video init error: $error");
            if (mounted) setState(() => _hasVideoError = true);
          });
      } else {
        if (mounted) setState(() => _hasVideoError = true);
      }
    } catch (e) {
      debugPrint("❌ Video load error: $e");
      if (mounted) setState(() => _hasVideoError = true);
    }
  }

  void _startTimer() {
    if (isRunning || _exerciseCompleted) return;

    int fullDuration = _isRestPeriod ? _cooldownDuration : widget.exercise.duration;
    double initialValue = remainingTime / fullDuration;
    
    try {
      if (_controllerInitialized) {
        _controller.reset();
        _controller.value = initialValue;
        _controller.reverse(from: initialValue);
      }

      // Always play video and set volume based on mute setting
      if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
        _videoPlayerController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
        _videoPlayerController!.play();
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime > 0) {
          setState(() => remainingTime--);
          
          if (_controllerInitialized) {
            double progress = remainingTime / fullDuration;
            _controller.value = progress;
          }
        } else {
          timer.cancel();
          _handleTimerCompletion();
        }
      });

      setState(() => isRunning = true);
    } catch (e) {
      debugPrint("❌ Error starting timer: $e");
      _initAnimationController(_isRestPeriod ? _cooldownDuration : widget.exercise.duration);
    }
  }

  void startTimer() {
    _startTimer();
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    
    if (_controllerInitialized) {
      _controller.stop();
    }
    
    if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
      _videoPlayerController!.pause();
    }
    
    setState(() => isRunning = false);
  }

  void resetTimer() {
    _cleanupTimerAndAnimation();
    _audioPlayer.stop();
    
    if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
      _videoPlayerController!.seekTo(Duration.zero);
      _videoPlayerController!.pause();
      _videoPlayerController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
    }
    
    int initialDuration = _isRestPeriod ? _cooldownDuration : widget.exercise.duration;
    
    _initAnimationController(initialDuration);

    setState(() {
      remainingTime = initialDuration;
      isRunning = false;
    });
  }

  void _moveToNextExercise() {
    debugPrint('🚀 Move to next exercise called');
    debugPrint('   Exercise completed: $_exerciseCompleted');
    debugPrint('   Current exercise: ${widget.exercise.name}');
    debugPrint('   Sets completed: $_currentSet/$_totalSets');
    
    // Only call onComplete if we're actually completed
    if (_exerciseCompleted && widget.onComplete != null) {
      debugPrint('📞 Calling onComplete callback to advance to next exercise');
      widget.onComplete!();
    } else {
      debugPrint('❌ Cannot move to next exercise - exercise not completed or no callback');
    }
  }

  Future<void> _playCompletionAlarm() async {
    if (_isVideoInitialized && !_hasVideoError && _videoPlayerController != null) {
      _videoPlayerController!.pause();
    }
    
    await _audioPlayer.play(AssetSource("sounds/alarm.mp3"));
  }

  @override
  void dispose() {
    _cleanupCurrentState();
    if (_controllerInitialized) {
      _controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  // Correct workout progress calculation
  double _getWorkoutProgress() {
    if (_exerciseCompleted) {
      return 1.0; // 100% when completed
    } else if (_isRestPeriod) {
      // During rest period, progress reflects the set we just completed
      return _currentSet / _totalSets;
    } else {
      // During exercise, progress reflects previously completed sets
      return (_currentSet - 1) / _totalSets;
    }
  }

  // UI Helper Methods
  Color _getTypeColor() {
    switch (widget.exercise.type.toLowerCase()) {
      case "cardio": return AppColors.orange;
      case "strength": return AppColors.accentBlue;
      case "legs": return AppColors.accentPurple;
      case "core": return AppColors.accentCyan;
      default: return AppColors.accentBlue;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "easy": return AppColors.green;
      case "medium": return AppColors.orange;
      case "hard": return AppColors.red;
      default: return AppColors.accentBlue;
    }
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color, ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.primaryText,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video or placeholder content
        if (_hasVideoError || !_isVideoInitialized)
          (widget.exercise.gifUrl != null && widget.exercise.gifUrl!.isNotEmpty)
              ? Image.network(
                  widget.exercise.gifUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                )
              : _buildErrorPlaceholder()
        else
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoPlayerController!.value.size.width,
                height: _videoPlayerController!.value.size.height,
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
          ),
        
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
        ),
        
        // Mute button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: _buildMuteButton(),
        ),
      ],
    );
  }

  Widget _buildMuteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleVideoMute,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isVideoMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.accentBlue.withOpacity(0.3),
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center,
        size: 100,
        color: AppColors.accentBlue,
      ),
    );
  }

  Widget _buildSetsStatCard(ThemeManager theme) {
    final bool isPartOfWorkout = widget.totalSets != null;

    if (isPartOfWorkout) {
      if (_isRestPeriod) {
        if (!_isFinalRestPeriod) {
          return _buildStatCard(
            Icons.snooze,
            "Rest Period",
            "Next: Set ${_currentSet + 1}/$_totalSets",
            AppColors.green,
            theme,
          );
        } else {
          return _buildStatCard(
            Icons.done_all,
            "Final Rest",
            "Next: Complete",
            AppColors.accentBlue,
            theme,
          );
        }
      } else if (_exerciseCompleted) {
        return _buildStatCard(
          Icons.done_all,
          "Status",
          "Completed",
          AppColors.accentBlue,
          theme,
        );
      } else {
        return _buildStatCard(
          Icons.repeat,
          "Current Set",
          "$_currentSet/$_totalSets",
          AppColors.accentPurple,
          theme,
        );
      }
    }
    
    return _buildStatCard(
      Icons.repeat,
      "Sets",
      "${widget.exercise.sets}",
      AppColors.accentPurple,
      theme,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
    bool expanded = true,
  }) {
    final button = ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : color.withOpacity(0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
      ),
    );

    return expanded ? Expanded(child: button) : button;
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
            decoration: const BoxDecoration(
              color: AppColors.accentBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
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

  Widget _buildRestTimerProgress(ThemeManager theme) {
    final double progress = 1.0 - (remainingTime / _cooldownDuration);
    final int percentage = (progress * 100).round();
    
    final String nextInfo;
    if (!_isFinalRestPeriod) {
      nextInfo = "Set ${_currentSet + 1} of $_totalSets";
    } else {
      nextInfo = "Complete Exercise";
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.self_improvement, color: AppColors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  "REST & RECOVER",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            "Great work on Set $_currentSet! Take a breather...",
            style: TextStyle(
              fontSize: 16,
              color: theme.secondaryText,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            "Next: $nextInfo",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$remainingTime",
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                    height: 1.0,
                  ),
                ),
                Text(
                  "seconds remaining",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rest Progress",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    "$percentage%",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.borderColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: 12,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.green, Colors.lightGreen],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Use this time to hydrate and prepare for the next set",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTimer(ThemeManager theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "EXERCISE TIMER",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Set $_currentSet/$_totalSets: Perform ${widget.exercise.reps} reps",
          style: TextStyle(
            fontSize: 14,
            color: theme.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          width: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 220,
                width: 220,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.borderColor,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    height: 220,
                    width: 220,
                    child: CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentBlue,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  );
                },
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$remainingTime",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  Text(
                    "seconds",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen(ThemeManager theme) {
    final bool isPartOfWorkout = widget.onComplete != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accentBlue, AppColors.accentPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 50,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          "EXERCISE COMPLETED!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.accentBlue,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          "You've completed all $_totalSets sets of ${widget.exercise.name}",
          style: TextStyle(
            fontSize: 16,
            color: theme.secondaryText,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentBlue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    "$_totalSets",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  Text(
                    "Sets",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "${widget.exercise.reps * _totalSets}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  Text(
                    "Total Reps",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "${widget.exercise.duration * _totalSets}s",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  Text(
                    "Total Time",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (isPartOfWorkout)
          Column(
            children: [
              _buildControlButton(
                icon: Icons.arrow_forward,
                label: "CONTINUE TO NEXT EXERCISE",
                color: AppColors.accentBlue,
                onPressed: () {
                  debugPrint('🎯 Next Exercise button pressed');
                  _moveToNextExercise();
                },
                expanded: false,
              ),
              const SizedBox(height: 12),
              _buildControlButton(
                icon: Icons.replay,
                label: "REPEAT EXERCISE",
                color: AppColors.orange,
                onPressed: () {
                  debugPrint('🔄 Repeat Exercise button pressed');
                  setState(() {
                    _exerciseCompleted = false;
                    _showCompletionScreen = false;
                    _currentSet = 1;
                    _isRestPeriod = false;
                    _isFinalRestPeriod = false;
                    remainingTime = widget.exercise.duration;
                  });
                  _initAnimationController(widget.exercise.duration);
                },
                expanded: false,
              ),
            ],
          )
        else
          _buildControlButton(
            icon: Icons.done,
            label: "FINISH WORKOUT",
            color: AppColors.green,
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            expanded: false,
          ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.green.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Great job! Consistency is key to achieving your fitness goals.",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final isPartOfWorkout = widget.totalSets != null;
    final double workoutProgress = _getWorkoutProgress();

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
              background: _buildBackgroundContent(),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRestPeriod ? "REST TIME" : 
                          _exerciseCompleted ? "COMPLETED" : widget.exercise.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _isRestPeriod ? AppColors.green : 
                                  _exerciseCompleted ? AppColors.accentBlue : theme.primaryText,
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
                                color: _isRestPeriod 
                                    ? AppColors.green.withOpacity(0.1)
                                    : _exerciseCompleted
                                    ? AppColors.accentBlue.withOpacity(0.1)
                                    : _getTypeColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isRestPeriod 
                                      ? AppColors.green
                                      : _exerciseCompleted
                                      ? AppColors.accentBlue
                                      : _getTypeColor(),
                                ),
                              ),
                              child: Text(
                                _isRestPeriod ? "BREAK" : 
                                _exerciseCompleted ? "DONE" : widget.exercise.type,
                                style: TextStyle(
                                  color: _isRestPeriod ? AppColors.green : 
                                        _exerciseCompleted ? AppColors.accentBlue : _getTypeColor(),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!_isRestPeriod && !_exerciseCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(widget.exercise.difficulty)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getDifficultyColor(widget.exercise.difficulty),
                                  ),
                                ),
                                child: Text(
                                  widget.exercise.difficulty,
                                  style: TextStyle(
                                    color: _getDifficultyColor(widget.exercise.difficulty),
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

                  const SizedBox(height: 16),

                  // Workout progress (only in workout mode)
                  if (isPartOfWorkout)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Workout Progress",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryText,
                                ),
                              ),
                              Text(
                                "${(workoutProgress * 100).round()}%",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: workoutProgress,
                            backgroundColor: theme.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Set $_currentSet/$_totalSets",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.secondaryText,
                                ),
                              ),
                              Text(
                                "${(workoutProgress * 100).round()}% Complete",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  if (isPartOfWorkout) const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.timer,
                          _isRestPeriod ? "Rest Time" : "Duration",
                          _isRestPeriod ? "${_cooldownDuration}s" : "${widget.exercise.duration}s",
                          AppColors.accentCyan,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSetsStatCard(theme),
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

                  const SizedBox(height: 24),

                  // Main timer container
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showCompletionScreen)
                          _buildCompletionScreen(theme)
                        else if (_isRestPeriod)
                          _buildRestTimerProgress(theme)
                        else
                          _buildExerciseTimer(theme),
                        
                        const SizedBox(height: 24),

                        // Control buttons (only show for exercise, not rest or completion)
                        if (!_exerciseCompleted && !_isRestPeriod)
                          Row(
                            children: [
                              _buildControlButton(
                                icon: isRunning ? Icons.pause : Icons.play_arrow,
                                label: isRunning ? "PAUSE" : "START SET",
                                color: isRunning ? AppColors.orange : AppColors.accentBlue,
                                onPressed: isRunning ? pauseTimer : startTimer,
                              ),
                              const SizedBox(width: 12),
                              _buildControlButton(
                                icon: Icons.refresh,
                                label: "RESET",
                                color: Colors.grey,
                                onPressed: resetTimer,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pro tips section (only show during exercise)
                  if (!_exerciseCompleted && !_isRestPeriod)
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
                                child: const Icon(
                                  Icons.tips_and_updates,
                                  color: Colors.white,
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
                          _buildTipItem("Maintain proper form throughout the movement", theme),
                          _buildTipItem("Keep your core engaged for stability", theme),
                          _buildTipItem("Breathe steadily - exhale during exertion", theme),
                          _buildTipItem("Focus on controlled movements, not speed", theme),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Rest tips section (only show during rest)
                  if (_isRestPeriod)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.green.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.self_improvement,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Rest Tips",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTipItem("Take deep breaths to recover your heart rate", theme),
                          _buildTipItem("Hydrate with small sips of water", theme),
                          _buildTipItem("Lightly stretch the muscles you just worked", theme),
                          _buildTipItem("Visualize your next set for better performance", theme),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}