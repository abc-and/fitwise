import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme.dart';
import 'login_page.dart';
import 'exercise_page.dart';
import 'workout_streak_page.dart';
import 'constants/app_colors.dart';
import '../models/food_recommendation.dart';
import '../providers/food_recommendation_service.dart';
import 'profile_page.dart'; 
import 'calorie_log_page.dart';
import 'notification/notification_service.dart';
import 'notification/notification_center.dart';
import '../providers/quote_scheduler.dart'; 

// Controls whether the new goal input is shown after clicking 'Update Goal'
bool _showNewGoalInput = false;
bool _showGoalOptions = false; // Add this new state variable
String _selectedNewGoalType = 'lose';

Route createRouteLeft(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

// --- BMR/BMI Calculator Helper Class ---
class HealthCalculator {
  // Calculate BMR using Mifflin-St Jeor Equation
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String sex,
    String? activityLevel,
    String? reproductiveStatus,
  }) {
    double bmr;
    
    // Base BMR calculation
    if (sex.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
      
      // Adjust for reproductive status (females only)
      if (reproductiveStatus != null) {
        switch (reproductiveStatus) {
          case 'Pregnant':
            bmr += 300; // Additional calories during pregnancy
            break;
          case 'Breastfeeding':
            bmr += 500; // Additional calories while breastfeeding
            break;
          case 'On Period':
            bmr += 50; // Slight increase during menstruation
            break;
        }
      }
    }
    
    // Apply activity multiplier
    if (activityLevel != null) {
      double multiplier = 1.2; // Default: Sedentary
      switch (activityLevel) {
        case 'Lightly Active':
          multiplier = 1.375;
          break;
        case 'Moderately Active':
          multiplier = 1.55;
          break;
        case 'Very Active':
          multiplier = 1.725;
          break;
        case 'Extra Active':
          multiplier = 1.9;
          break;
      }
      bmr *= multiplier;
    }
    
    return bmr;
  }
  
  // Calculate BMI
  static double calculateBMI({
    required double weightKg,
    required double heightCm,
  }) {
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

  // Achievement definitions with thresholds
  class AchievementDefinition {
    final String id;
    final String title;
    final String description;
    final IconData icon;
    final double threshold; // Weight loss/gain threshold in kg
    final String type; // 'weight_loss', 'weight_gain', 'bmi_milestone', 'consistency'

    AchievementDefinition({
      required this.id,
      required this.title,
      required this.description,
      required this.icon,
      required this.threshold,
      required this.type,
    });
  }

    // Achievement system
  Set<String> _unlockedAchievements = {};

  // List of achievements to check against
  final List<AchievementDefinition> _achievements = [
    AchievementDefinition(
      id: 'first_step',
      title: 'First Step',
      description: 'You\'ve started your fitness journey!',
      icon: Icons.directions_walk,
      threshold: 0.1,
      type: 'weight_loss',
    ),
    AchievementDefinition(
      id: 'halfway_there',
      title: '🎯 Halfway There',
      description: 'You\'ve reached 50% of your goal!',
      icon: Icons.trending_down,
      threshold: 0.5,
      type: 'weight_loss',
    ),
    AchievementDefinition(
      id: 'five_kg_milestone',
      title: '💪 5kg Milestone',
      description: 'Incredible! You\'ve lost 5kg!',
      icon: Icons.emoji_events,
      threshold: 5.0,
      type: 'weight_loss',
    ),
    AchievementDefinition(
      id: 'ten_kg_milestone',
      title: '🏆 10kg Milestone',
      description: 'Outstanding dedication! 10kg down!',
      icon: Icons.emoji_events,
      threshold: 10.0,
      type: 'weight_loss',
    ),
    AchievementDefinition(
      id: 'bmi_improvement',
      title: 'Health Improved',
      description: 'Your BMI has moved to a healthier category!',
      icon: Icons.favorite,
      threshold: 0.0, // Checked separately
      type: 'bmi_milestone',
    ),
    AchievementDefinition(
      id: 'goal_reached',
      title: '⭐ Goal Achieved',
      description: 'You\'ve reached your fitness goal!',
      icon: Icons.star,
      threshold: 1.0,
      type: 'consistency',
    ),
    AchievementDefinition(
      id: 'weight_gain_milestone',
      title: 'Strong Start',
      description: 'Great progress! You\'ve gained 5kg of muscle!',
      icon: Icons.fitness_center,
      threshold: 5.0,
      type: 'weight_gain',
    ),
  ];

// --- Main Dashboard Implementation ---
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          createRouteLeft(const LoginPage()),
          (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You have been logged out.'),
            backgroundColor: AppColors.accentBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: AppColors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final screens = <Widget>[
      const HomeContent(),
      const ExercisePage(),
      const CalorieLogPage(),
      const WorkoutStreakPage(),
      ProfilePage(onLogout: () => _logout(context)),
    ];

    return DefaultTabController(
      length: screens.length,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryBackground.withOpacity(0.12),
                theme.secondaryBackground.withOpacity(0.10),
                theme.surfaceColor.withOpacity(0.95),
              ],
            ),
          ),
          child: Stack(
            children: [
              TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: screens,
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor,
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 4, color: AppColors.accentBlue),
              insets: const EdgeInsets.symmetric(horizontal: 24),
            ),
            labelColor: theme.primaryText,
            unselectedLabelColor: theme.tertiaryText,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Icons.home, color: AppColors.accentBlue), text: 'Home'),
              Tab(icon: Icon(Icons.fitness_center, color: AppColors.orange), text: 'Exercise'),
              Tab(icon: Icon(Icons.restaurant, color: AppColors.green), text: 'Calories'),
              Tab(icon: Icon(Icons.local_fire_department, color: AppColors.orange), text: 'Streak'),
              Tab(icon: Icon(Icons.person, color: AppColors.accentPurple), text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class SimplePlaceholder extends StatelessWidget {
  final String title;
  const SimplePlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primaryText),
      ),
    );
  }
}

// --- Home Content with Firebase Integration ---
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Food recommendation user info model
  UserInfoData? _userInfo;
  final NotificationService _notificationService = NotificationService();
  final FoodRecommendationService _recommendationService = FoodRecommendationService();
  // Persistent controllers and state for new goal input
  final TextEditingController _newGoalController = TextEditingController();
  String _selectedNewGoalType = 'lose';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  String _username = 'User';
  bool _loadingUser = true;
  
  // Onboarding data from Firebase
  double _currentWeight = 70.0;
  double _goalWeight = 65.0;
  double _startWeight = 80.0;
  double _heightCm = 170.0;
  int _age = 25;
  String _sex = 'Male';
  String _goalType = 'lose';
  String? _activityLevel;
  String? _reproductiveStatus;
  String? _targetDate;
  
  // Calculated values
  double _bmr = 0;
  double _bmi = 0;
  String _bmiCategory = '';
  
  // Battery
  bool _goalCompleted = false;

  // Add the new state variables
  bool _showNewGoalInput = false;
  bool _showGoalOptions = false;

  // Helper to determine if user reached the goal by value (independent of firestore flag)
  bool _hasReachedGoal() {
    final isGain = _goalType == 'gain';
    return isGain ? (_currentWeight >= _goalWeight) : (_currentWeight <= _goalWeight);
  }

  // Call this when you want to mark completion (and show dialog once).
  Future<void> _markGoalCompleted({bool showCongratsDialog = true}) async {
    if (_goalCompleted) return;
    if (!_hasReachedGoal()) return;

    setState(() => _goalCompleted = true);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('user_info').doc(user.uid).update({
          'goalCompleted': true,
          'goalCompletedAt': DateTime.now(),
        });
      } catch (e) {
        debugPrint('Failed to mark goalCompleted in firestore: $e');
      }
    }

    if (showCongratsDialog && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: AlertDialog(
                  backgroundColor: Provider.of<ThemeManager>(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.all(32),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Trophy Icon
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.8, end: 1.0),
                        curve: Curves.easeInOut,
                        builder: (context, iconScale, child) {
                          return Transform.scale(
                            scale: iconScale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    AppColors.orange,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppColors.accentPurple,
                            AppColors.accentBlue,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Congratulations! 🎉',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Message
                      Text(
                        'You\'ve reached your goal of\n${_goalWeight.toStringAsFixed(1)} kg!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Provider.of<ThemeManager>(context).secondaryText,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Amazing dedication! 💪',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Provider.of<ThemeManager>(context).tertiaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Button
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Awesome!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      });
    }
  }

  // Health warning checker
  Map<String, dynamic> _checkGoalHealth(double targetWeight) {
    // Calculate projected BMI
    double projectedBMI = HealthCalculator.calculateBMI(
      weightKg: targetWeight,
      heightCm: _heightCm,
    );
    
    bool isDangerous = false;
    bool isUnhealthy = false;
    String warningTitle = '';
    String warningMessage = '';
    Color warningColor = AppColors.orange;
    
    // Critical danger zones
    if (projectedBMI < 16.0) {
      isDangerous = true;
      warningTitle = '⚠️ Severe Underweight Warning';
      warningMessage = 'Your target BMI of ${projectedBMI.toStringAsFixed(1)} is severely underweight (< 16.0). This can lead to:\n\n'
          '• Malnutrition and weakened immune system\n'
          '• Organ damage\n'
          '• Severe health complications\n\n'
          'Please consult a healthcare professional before setting this goal.';
      warningColor = AppColors.orange;
    } else if (projectedBMI >= 35.0) {
      isDangerous = true;
      warningTitle = '⚠️ Severe Obesity Warning';
      warningMessage = 'Your target BMI of ${projectedBMI.toStringAsFixed(1)} is in the obese range (≥ 35.0). This can lead to:\n\n'
          '• Increased risk of heart disease\n'
          '• Type 2 diabetes\n'
          '• Joint problems\n\n'
          'Please consult a healthcare professional before setting this goal.';
      warningColor = AppColors.orange;
    }
    // Unhealthy zones
    else if (projectedBMI < 18.5) {
      isUnhealthy = true;
      warningTitle = '⚠️ Underweight Target';
      warningMessage = 'Your target BMI of ${projectedBMI.toStringAsFixed(1)} is underweight (< 18.5). This may cause:\n\n'
          '• Nutrient deficiencies\n'
          '• Weakened immunity\n'
          '• Fatigue and low energy\n\n'
          'Consider a healthier weight goal or consult a nutritionist.';
      warningColor = AppColors.orange;
    } else if (projectedBMI >= 30.0) {
      isUnhealthy = true;
      warningTitle = '⚠️ Overweight Target';
      warningMessage = 'Your target BMI of ${projectedBMI.toStringAsFixed(1)} is in the obese range (≥ 30.0). This may increase risk of:\n\n'
          '• Cardiovascular issues\n'
          '• High blood pressure\n'
          '• Metabolic disorders\n\n'
          'Consider a healthier weight goal or consult a healthcare provider.';
      warningColor = AppColors.orange;
    }
    
    // Check for extreme weight changes
    double weightChange = (targetWeight - _currentWeight).abs();
    double percentChange = (weightChange / _currentWeight) * 100;
    
    if (percentChange > 20 && !isDangerous) {
      isUnhealthy = true;
      warningTitle = '⚠️ Extreme Weight Change';
      warningMessage = 'You\'re targeting a ${percentChange.toStringAsFixed(1)}% change in body weight (${weightChange.toStringAsFixed(1)} kg).\n\n'
          'Extreme weight changes can be harmful. Recommended safe rate:\n'
          '• Weight loss: 0.5-1 kg per week\n'
          '• Weight gain: 0.25-0.5 kg per week\n\n'
          'Consider setting a more gradual goal.';
      warningColor = AppColors.orange;
    }
    
    return {
      'isDangerous': isDangerous,
      'isUnhealthy': isUnhealthy,
      'title': warningTitle,
      'message': warningMessage,
      'color': warningColor,
      'projectedBMI': projectedBMI,
    };
  }

  // Call this to set a brand-new goal (user inputs weight + optional type)
  Future<void> _updateGoalWeightAndType(double targetDelta, String newType) async {
    final user = _auth.currentUser;
    double newGoalWeight = _currentWeight;
    if (newType == 'gain') {
      newGoalWeight = _currentWeight + targetDelta.abs();
    } else if (newType == 'lose') {
      newGoalWeight = _currentWeight - targetDelta.abs();
    }
    
    // Check if goal is healthy
    final healthCheck = _checkGoalHealth(newGoalWeight);
    
    // Show warning dialog if unhealthy or dangerous
    if (healthCheck['isDangerous'] == true || healthCheck['isUnhealthy'] == true) {
      // Get theme BEFORE async operations
      final theme = Provider.of<ThemeManager>(context, listen: false);
      
      final shouldProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: healthCheck['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  healthCheck['isDangerous'] == true 
                      ? Icons.dangerous 
                      : Icons.warning_amber,
                  color: healthCheck['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  healthCheck['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: healthCheck['color'],
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Weight:',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_currentWeight.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target Weight:',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${newGoalWeight.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: healthCheck['color'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target BMI:',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            healthCheck['projectedBMI'].toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: healthCheck['color'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  healthCheck['message'],
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (healthCheck['isDangerous'] == true) ...[
              // Only cancel button for dangerous goals
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Cancel Goal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Both options for unhealthy (but not dangerous) goals
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Change Goal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed Anyway',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      );
      
      // If user cancels or it's dangerous, don't set the goal
      if (shouldProceed != true) {
        return;
      }
    }
    
    // Proceed with setting the goal
    setState(() {
      _goalWeight = newGoalWeight;
      _goalType = newType;
      _startWeight = _currentWeight;
      _goalCompleted = false;
      _showNewGoalInput = false;
      _showGoalOptions = false;
    });

    if (user != null) {
      try {
        final updateData = {
          'goalWeight': newGoalWeight,
          'goalType': newType,
          'goalCompleted': false,
        };
        if (newType == 'gain') {
          updateData['targetWeightGain'] = targetDelta.abs().toStringAsFixed(1);
          updateData['targetWeightLoss'] = '';
        } else if (newType == 'lose') {
          updateData['targetWeightLoss'] = targetDelta.abs().toStringAsFixed(1);
          updateData['targetWeightGain'] = '';
        }
        await _firestore.collection('user_info').doc(user.uid).update(updateData);
      } catch (e) {
        debugPrint('Error saving new goal to firestore: $e');
      }
    }
  }

  // Historical data for graph (simulated)
  List<Map<String, dynamic>> _progressData = [];
  
  // Food carousel
  late List<Map<String, dynamic>> _timeFoods = [];

  // Controllers
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _fetchUserData(); 
     _scheduleMotivationalQuotes(); // Add this line
  }

  Future<void> _scheduleMotivationalQuotes() async {
  // Only for Option A (Android AlarmManager)
  final quoteScheduler = QuoteScheduler();
  
  try {
    // Schedule quotes for 8:00 AM daily
    // Adjust time as needed
    await quoteScheduler.scheduleDailyQuote(hour: 8, minute: 0);
  } catch (e) {
    debugPrint('Error setting up quote scheduler: $e');
  }
}

  Future<void> _initializeServices() async {
    // Initialize notification service first
    await _notificationService.initialize();
    
    // Then fetch user data
    await _fetchUserData();
  }

  void _filterFoodsByTime() {
    if (_userInfo == null) return;
    final h = DateTime.now().hour;
    String type = (h >= 5 && h < 12) ? 'morning' : (h >= 12 && h < 18) ? 'afternoon' : 'evening';
    _timeFoods = _recommendationService.getRecommendations(
      userInfo: _userInfo!,
      timeOfDay: type,
    );
    if (mounted) setState(() {});
  }

  // Fetch user data from Firebase
  Future<void> _fetchUserData() async {
    setState(() => _loadingUser = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _username = 'User';
          _loadingUser = false;
        });
        return;
      }
      
      // Fetch from users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('username')) {
          _username = userData['username'] ?? 'User';
        }
      }
      
      final infoDoc = await _firestore.collection('user_info').doc(user.uid).get();
      if (infoDoc.exists) {
        final data = infoDoc.data();
        if (data != null) {
          // Collect all data points
          final currentWeight = _parseWeight(data['weight']);
          final heightCm = _parseHeight(data['height']);
          final age = int.tryParse(data['age'].toString()) ?? 25;
          final sex = data['sex']?.toString() ?? 'Other';
          final activityLevel = data['activityLevel']?.toString() ?? 'Sedentary';
          final reproductiveStatus = data['reproductiveStatus']?.toString() ?? 'Not Applicable';

          // Assign user info for food recommendations
          _userInfo = UserInfoData(
            currentWeight: currentWeight,
            heightCm: heightCm,
            age: age,
            sex: sex,
            activityLevel: activityLevel,
            targetGoal: data['targetGoal']?.toString() ?? '',
            dietType: data['dietType']?.toString() ?? '',
            reproductiveStatus: data['reproductiveStatus']?.toString() ?? '',
            dietaryRestrictions: data['dietaryRestrictions']?.toString() ?? '',
            allergies: data['allergies']?.toString() ?? '',
            otherConditions: data['otherConditions']?.toString() ?? '',
          );
          _filterFoodsByTime();

          // Update state variables and call food filtering/recommendation
          _currentWeight = currentWeight;
          // Persist start weight if not set in Firestore
          if (data.containsKey('startWeight') && data['startWeight'] != null) {
            _startWeight = double.tryParse(data['startWeight'].toString()) ?? _currentWeight;
          } else {
            _startWeight = _currentWeight;
            // Save startWeight to Firestore for persistence
            final user = _auth.currentUser;
            if (user != null) {
              await _firestore.collection('user_info').doc(user.uid).set({'startWeight': _startWeight}, SetOptions(merge: true));
            }
          }
          _heightCm = heightCm;
          _age = age;
          _sex = sex;
          _activityLevel = activityLevel;
          _reproductiveStatus = reproductiveStatus;
          
          // Get target goal and determine goal type
          if (data.containsKey('targetWeightLoss') && data['targetWeightLoss'] != null && data['targetWeightLoss'].toString().isNotEmpty) {
            final loss = double.tryParse(data['targetWeightLoss'].toString());
            if (loss != null) {
              _goalWeight = _currentWeight - loss;
            }
          } else if (data.containsKey('targetWeightGain') && data['targetWeightGain'] != null && data['targetWeightGain'].toString().isNotEmpty) {
            final gain = double.tryParse(data['targetWeightGain'].toString());
            if (gain != null) {
              _goalWeight = _currentWeight + gain;
            }
          }

          // Load stored goal type if present (make lowercase)
          if (data.containsKey('goalType')) {
            _goalType = data['goalType']?.toString().toLowerCase() ?? _goalType;
          } else if (data.containsKey('targetGoal')) {
            // fallback to older field (if you used targetGoal strings)
            final goalText = data['targetGoal']?.toString() ?? '';
            if (goalText.toLowerCase().contains('loss')) _goalType = 'lose';
            if (goalText.toLowerCase().contains('gain')) _goalType = 'gain';
          }

          // Load persisted completed flag (default false)
          _goalCompleted = data['goalCompleted'] == true;
          
          // Load unlocked achievements
          if (data.containsKey('unlockedAchievements') && data['unlockedAchievements'] != null) {
            _unlockedAchievements = Set<String>.from(data['unlockedAchievements'] as List);
          }
          
          // Get target date and duration
          if (data.containsKey('targetDate')) {
            _targetDate = data['targetDate'].toString();
          }
          
          // Calculate BMR and BMI
          _calculateHealthMetrics();
          
          // Generate simulated progress data
          await _fetchProgressData();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }
  
  // Parse weight from string (handles kg and lbs)
  double _parseWeight(dynamic weightStr) {
    String str = weightStr.toString().toLowerCase();
    double value = double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 70.0;
    
    // Convert lbs to kg if needed
    if (str.contains('lb')) {
      value = value * 0.453592; // lbs to kg
    }
    return value;
  }
  
  // Parse height from string (handles cm and m)
  double _parseHeight(dynamic heightStr) {
    String str = heightStr.toString().toLowerCase();
    double value = double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 170.0;
    
    // Convert m to cm if needed
    if (str.contains('m') && !str.contains('cm') && value < 3) {
      value = value * 100; // m to cm
    }
    return value;
  }
  
  // Calculate BMR and BMI
  void _calculateHealthMetrics() {
    _bmr = HealthCalculator.calculateBMR(
      weightKg: _currentWeight,
      heightCm: _heightCm,
      age: _age,
      sex: _sex,
      activityLevel: _activityLevel,
      reproductiveStatus: _reproductiveStatus,
    );
    
    _bmi = HealthCalculator.calculateBMI(
      weightKg: _currentWeight,
      heightCm: _heightCm,
    );
    
    _bmiCategory = HealthCalculator.getBMICategory(_bmi);
  }
  
  // Fetch progress data from Firebase
  Future<void> _fetchProgressData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in for progress data');
        return;
      }
      
      _progressData.clear();
      
      // Fetch weight history from Firestore
      final querySnapshot = await _firestore
          .collection('user_info')
          .doc(user.uid)
          .collection('weight_history')
          .orderBy('timestamp', descending: false)
          .limit(30)
          .get();
      
      debugPrint('Fetched ${querySnapshot.docs.length} history entries');
      
      // Process each history entry
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        
        if (timestamp == null) {
          debugPrint('Skipping entry with no timestamp: ${doc.id}');
          continue;
        }
        
        final weight = double.tryParse(data['weight']?.toString() ?? '') ?? _currentWeight;
        final height = double.tryParse(data['height']?.toString() ?? '') ?? _heightCm;
        
        // Use stored BMR/BMI if available, otherwise calculate
        final bmr = data['bmr'] != null 
            ? (data['bmr'] is double ? data['bmr'] : double.tryParse(data['bmr'].toString()) ?? _bmr)
            : HealthCalculator.calculateBMR(
                weightKg: weight,
                heightCm: height,
                age: _age,
                sex: _sex,
                activityLevel: _activityLevel,
                reproductiveStatus: _reproductiveStatus,
              );
        
        final bmi = data['bmi'] != null
            ? (data['bmi'] is double ? data['bmi'] : double.tryParse(data['bmi'].toString()) ?? _bmi)
            : HealthCalculator.calculateBMI(
                weightKg: weight,
                heightCm: height,
              );
        
        _progressData.add({
          'date': timestamp,
          'weight': weight,
          'height': height,
          'bmr': bmr,
          'bmi': bmi,
        });
        
        debugPrint('Added history point: ${timestamp.toString().split(' ')[0]} - Weight: $weight, BMI: ${bmi.toStringAsFixed(1)}, BMR: ${bmr.round()}');
      }
      
      // If no history exists, create initial entry
      if (_progressData.isEmpty) {
        debugPrint('No history found, creating initial entry');
        _progressData.add({
          'date': DateTime.now(),
          'weight': _currentWeight,
          'height': _heightCm,
          'bmr': _bmr,
          'bmi': _bmi,
        });
      }
      
      debugPrint('Total progress data points: ${_progressData.length}');
    } catch (e) {
      debugPrint('Error fetching progress data: $e');
      // Fallback to current data
      _progressData = [{
        'date': DateTime.now(),
        'weight': _currentWeight,
        'height': _heightCm,
        'bmr': _bmr,
        'bmi': _bmi,
      }];
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _newGoalController.dispose(); 
    _notificationService.dispose(); 
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

double _batteryPercent() {
  // For weight loss and gain, use the original calculation
  if (_goalType == 'lose' || _goalType == 'gain') {
    final isGain = _goalType == 'gain';
    
    if (_startWeight == _goalWeight) return 0.0;
    if (_currentWeight == _startWeight) return 0.0;
    
    final bool isGoalReached = (isGain && _currentWeight >= _goalWeight) || 
                            (!isGain && _currentWeight <= _goalWeight);
    
    if (isGoalReached) return 1.0;
    
    double progress;
    if (isGain) {
      progress = (_currentWeight - _startWeight) / (_goalWeight - _startWeight);
    } else {
      progress = (_startWeight - _currentWeight) / (_startWeight - _goalWeight);
    }
    
    return progress.clamp(0.0, 1.0);
  }
  
  // For all other goals (muscle building, endurance, general fitness, maintenance)
  // Show 100% battery since these are ongoing/maintenance goals
  return 1.0;
}

  // Method to check and trigger achievements
  Future<void> _checkAndTriggerAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get previously unlocked achievements from Firestore
      final userDoc = await _firestore.collection('user_info').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['unlockedAchievements'] != null) {
          _unlockedAchievements = Set<String>.from(data['unlockedAchievements'] as List);
        }
      }

      for (final achievement in _achievements) {
        // Skip if already unlocked
        if (_unlockedAchievements.contains(achievement.id)) continue;

        bool isUnlocked = false;

        if (achievement.type == 'weight_loss') {
          final weightLost = _startWeight - _currentWeight;
          if (_goalType == 'lose' && weightLost >= achievement.threshold) {
            isUnlocked = true;
          }
        } else if (achievement.type == 'weight_gain') {
          final weightGained = _currentWeight - _startWeight;
          if (_goalType == 'gain' && weightGained >= achievement.threshold) {
            isUnlocked = true;
          }
        } else if (achievement.type == 'bmi_milestone') {
          // Check if BMI improved to a better category
          final previousBmiCategory = HealthCalculator.getBMICategory(
            HealthCalculator.calculateBMI(
              weightKg: _startWeight,
              heightCm: _heightCm,
            ),
          );
          final currentBmiCategory = _bmiCategory;
          
          // Define category rankings
          const categoryRanking = {
            'Underweight': 0,
            'Normal': 1,
            'Overweight': 2,
            'Obese': 3,
          };

          if ((categoryRanking[currentBmiCategory] ?? 0) < 
              (categoryRanking[previousBmiCategory] ?? 0)) {
            isUnlocked = true;
          }
        } else if (achievement.type == 'consistency') {
          // This is for goal completion
          if (_goalCompleted) {
            isUnlocked = true;
          }
        }

        if (isUnlocked) {
          // Unlock the achievement
          _unlockedAchievements.add(achievement.id);

          // Send notification
          await _notificationService.sendAchievement(
            title: achievement.title,
            message: achievement.description,
          );

          // Save to Firestore
          await _firestore.collection('user_info').doc(user.uid).update({
            'unlockedAchievements': _unlockedAchievements.toList(),
          });

          debugPrint('Achievement Unlocked: ${achievement.id}');
        }
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

 // Call this method after updating weight
Future<void> _saveWeightUpdateWithAchievementCheck(double weight, double? height) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in');
      return;
    }

    final timestamp = DateTime.now();

    Map<String, dynamic> updateData = {
      'weight': weight.toString(),
      'lastWeightUpdate': Timestamp.fromDate(timestamp),
    };

    if (height != null) {
      updateData['height'] = height.toString();
    }

    await _firestore.collection('user_info').doc(user.uid).update(updateData);
    debugPrint('Main document updated successfully');

    final historyRef = _firestore.collection('user_info').doc(user.uid).collection('weight_history');

    final historyData = {
      'weight': weight.toString(),
      'height': height?.toString() ?? _heightCm.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'bmr': _bmr,
      'bmi': _bmi,
    };

    await historyRef.add(historyData);
    debugPrint('Added to weight_history: $historyData');

    // Check for new achievements after weight update
    await _checkAndTriggerAchievements();
  } catch (e) {
    debugPrint('Error saving weight update: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.orange,
        ),
      );
    }
  }
}

// Add this handleSave method for weight updates
Future<void> handleSave() async {
  final wt = double.tryParse(_weightController.text);
  if (wt == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid weight')),
    );
    return;
  }

  setState(() {
    _currentWeight = wt;
    _calculateHealthMetrics();
  });

  await _saveWeightUpdateWithAchievementCheck(wt, null);
  
  // Check for new achievements after saving
  await _checkAndTriggerAchievements();

  if (!_goalCompleted && _hasReachedGoal()) {
    _markGoalCompleted();
  }
}

  Widget _buildTopGreeting() {
    final theme = Provider.of<ThemeManager>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentBlue, AppColors.accentCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Icon(Icons.self_improvement, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(fontSize: 14, color: theme.secondaryText),
                ),
                const SizedBox(height: 4),
                _loadingUser 
                  ? Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText,
                      ),
                    ) 
                  : Text(
                      _username,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText,
                      ),
                    ),
              ],
            ),
          ),
          // Notification Bell
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(), // Use instance instead of creating new one
            initialData: 0,
            builder: (context, snapshot) {
              // Show icon immediately, don't wait for stream
              final unreadCount = snapshot.data ?? 0;
              final hasUnread = unreadCount > 0;
              
              // Only show error state if there's an actual error
              if (snapshot.hasError) {
                debugPrint('Notification stream error: ${snapshot.error}');
                return Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationCenter(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.notifications_off,
                          color: AppColors.orange,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main notification button with animated background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: hasUnread 
                              ? AppColors.orange.withOpacity(0.3)
                              : theme.shadowColor,
                          blurRadius: hasUnread ? 12 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: hasUnread 
                          ? Border.all(
                              color: AppColors.orange.withOpacity(0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationCenter(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              hasUnread
                                  ? Icons.notifications_active
                                  : Icons.notifications_outlined,
                              key: ValueKey(hasUnread),
                              color: hasUnread
                                  ? AppColors.orange
                                  : theme.primaryText,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Enhanced badge with red circle
                  if (hasUnread)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade700,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryBackground,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: AppColors.orange),
                const SizedBox(width: 6),
                Text(
                  '${_bmr.round()} kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmrBmiCard() {
    final theme = Provider.of<ThemeManager>(context);
    return _cardWrapper(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _smallIconBox(Icons.insights),
          const SizedBox(width: 12),
          Expanded(child: Text('Health Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryText))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getBMIColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_bmiCategory, style: TextStyle(color: _getBMIColor(), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                label: 'BMR',
                value: '${_bmr.round()}',
                unit: 'kcal/day',
                icon: Icons.local_fire_department,
                color: AppColors.accentCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                label: 'BMI',
                value: _bmi.toStringAsFixed(1),
                unit: 'kg/m²',
                icon: Icons.monitor_weight,
                color: _getBMIColor(),
              ),
            ),
          ],
        ),
        if (_targetDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: theme.primaryText),
                const SizedBox(width: 8),
                Text('Target Date: $_targetDate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryText)),
              ],
            ),
          ),
        ],
      ]),
    );
  }
  
  Color _getBMIColor() {
    if (_bmi < 18.5) return AppColors.orange;
    if (_bmi < 25) return AppColors.green;
    if (_bmi < 30) return AppColors.orange;
    return AppColors.orange;
  }
  
  Widget _buildMetricBox({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final theme = Provider.of<ThemeManager>(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: theme.secondaryText, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: TextStyle(fontSize: 11, color: theme.tertiaryText)),
        ],
      ),
    );
  }

  Widget _buildWeightBatteryCard() {
  final theme = Provider.of<ThemeManager>(context);
  final pct = _batteryPercent();
  final pctRounded = (pct * 100).round();
  final isWeightGoal = _goalType == 'lose' || _goalType == 'gain';

  return _cardWrapper(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              isWeightGoal ? (_goalType == 'gain' ? 'Gain Goal' : 'Lose Goal') : 'Active Goal',
              style: TextStyle(fontSize: 12, color: theme.secondaryText),
            ),
            const SizedBox(height: 8),
            VerticalBattery(
              percent: pct,
              width: 48,
              height: 160,
              fillColor: isWeightGoal ? AppColors.accentBlue : AppColors.green,
              backgroundColor: theme.borderColor.withOpacity(0.15),
              borderColor: theme.primaryText.withOpacity(0.18),
              showPercentage: false,
            ),
            const SizedBox(height: 8),
            Text('$pctRounded%', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryText)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWeightGoal ? 'Weight Progress' : 'Fitness Progress',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryText),
              ),
              const SizedBox(height: 6),
              Text('Current: ${_currentWeight.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 14, color: theme.primaryText)),
              const SizedBox(height: 4),

              // Goal section (display or editable after completion)
              _buildGoalSection(),

              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct, 
                  minHeight: 10, 
                  backgroundColor: theme.borderColor, 
                  color: isWeightGoal ? AppColors.accentBlue : AppColors.green,
                ),
              ),
              const SizedBox(height: 10),

              // Only show weight update for weight-related goals
              if (isWeightGoal && !_goalCompleted)
                _WeightActionButton(
                  weightController: _weightController,
                  isGain: _goalType == 'gain',
                  currentWeight: _currentWeight,
                  onSave: handleSave,
                  isGoalReached: _hasReachedGoal(),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget _buildGoalSection() {
  final theme = Provider.of<ThemeManager>(context);
  final isWeightGoal = _goalType == 'lose' || _goalType == 'gain';
  
  // For all non-weight goals, show the maintaining UI
  if (!isWeightGoal) {
    String goalTitle;
    String goalDescription;
    IconData goalIcon;
    
    switch (_goalType) {
      case 'muscle building':
        goalTitle = 'Building Muscle';
        goalDescription = 'You are focusing on muscle building and strength training.';
        goalIcon = Icons.fitness_center;
        break;
      case 'endurance & stamina':
        goalTitle = 'Endurance Training';
        goalDescription = 'You are working on improving your cardiovascular endurance and stamina.';
        goalIcon = Icons.directions_run;
        break;
      case 'general fitness':
        goalTitle = 'General Fitness';
        goalDescription = 'You are maintaining overall health and fitness.';
        goalIcon = Icons.self_improvement;
        break;
      case 'maintenance':
      default:
        goalTitle = 'Maintaining Weight';
        goalDescription = 'You are maintaining your weight at ${_currentWeight.toStringAsFixed(1)} kg.';
        goalIcon = Icons.balance;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentBlue.withOpacity(0.15),
            AppColors.accentCyan.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(goalIcon, color: AppColors.accentBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                goalTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goalDescription,
            style: TextStyle(
              color: theme.secondaryText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // UPDATE GOAL BUTTON - This shows the two options
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                debugPrint('Update Goal button pressed!');
                setState(() {
                  // Show the two options (New Goal and Maintain)
                  _showNewGoalInput = false;
                  _showGoalOptions = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Update Goal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // SHOW THE TWO OPTIONS WHEN _showGoalOptions IS TRUE
          if (_showGoalOptions) ...[
            const SizedBox(height: 16),
            _buildGoalOptions(),
          ],
          
          // SHOW GOAL INPUT FORM IF NEW GOAL WAS SELECTED
          if (_showNewGoalInput) ...[
            const SizedBox(height: 20),
            _buildGoalInputForm(),
          ],
        ],
      ),
    );
  }

  // Only show the new goal input if the goal is completed (not just reached, but marked completed)
  if (_goalCompleted) {
    if (_goalType == 'maintain') {
      // If already maintaining, just show info and update option
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentBlue.withOpacity(0.15),
              AppColors.accentCyan.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.balance, color: AppColors.accentBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Maintaining Weight',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You are maintaining your weight at ${_goalWeight.toStringAsFixed(1)} kg.',
              style: TextStyle(
                color: theme.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            // UPDATE GOAL BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('Update Goal button pressed!');
                  setState(() {
                    // Show the two options (New Goal and Maintain)
                    _showNewGoalInput = false;
                    _showGoalOptions = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Update Goal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // SHOW THE TWO OPTIONS WHEN _showGoalOptions IS TRUE
            if (_showGoalOptions) ...[
              const SizedBox(height: 16),
              _buildGoalOptions(),
            ],
            
            // SHOW GOAL INPUT FORM IF NEW GOAL WAS SELECTED
            if (_showNewGoalInput) ...[
              const SizedBox(height: 20),
              _buildGoalInputForm(),
            ],
          ],
        ),
      );
    }
    
    // For completed weight goals, show the two options directly
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.green.withOpacity(0.1),
            AppColors.accentCyan.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green, AppColors.accentCyan],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal Achieved! 🎉',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'What\'s next for you?',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoalOptions(),
          
          // SHOW GOAL INPUT FORM IF NEW GOAL WAS SELECTED
          if (_showNewGoalInput) ...[
            const SizedBox(height: 20),
            _buildGoalInputForm(),
          ],
        ],
      ),
    );
  }

  // Normal display: show the current goal text
  return Text(
    'Goal: ${_goalWeight.toStringAsFixed(1)} kg (${_goalType.toUpperCase()})',
    style: TextStyle(color: theme.secondaryText),
  );
}

// NEW METHOD: Build the two goal options (New Goal and Maintain)
Widget _buildGoalOptions() {
  final theme = Provider.of<ThemeManager>(context);
  
  return Row(
    children: [
      // NEW GOAL BUTTON
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _showGoalOptions = false;
              _showNewGoalInput = true;
              _selectedNewGoalType = 'lose'; // Default to lose weight
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag, size: 24),
              SizedBox(height: 6),
              Text(
                'New Goal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      // MAINTAIN BUTTON
      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            setState(() {
              _goalType = 'maintain';
              _goalWeight = _currentWeight;
              _startWeight = _currentWeight;
              _showNewGoalInput = false;
              _showGoalOptions = false;
              _goalCompleted = false;
            });
            final user = _auth.currentUser;
            if (user != null) {
              await _firestore.collection('user_info').doc(user.uid).set({
                'goalType': 'maintain',
                'goalWeight': _currentWeight,
                'startWeight': _currentWeight,
                'goalCompleted': false,
                'targetWeightLoss': '',
                'targetWeightGain': '',
              }, SetOptions(merge: true));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.cardColor,
            foregroundColor: AppColors.accentBlue,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.accentBlue.withOpacity(0.4),
                width: 2,
              ),
            ),
            elevation: 0,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.balance, size: 24),
              SizedBox(height: 6),
              Text(
                'Maintain',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// NEW METHOD: Build the goal input form
Widget _buildGoalInputForm() {
  final theme = Provider.of<ThemeManager>(context);
  
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.borderColor.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, size: 20, color: theme.primaryText),
            const SizedBox(width: 8),
            Text(
              'Set New Goal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.borderColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.borderColor.withOpacity(0.2)),
          ),
          child: DropdownButton<String>(
            value: _selectedNewGoalType,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: theme.primaryText),
            style: TextStyle(
              color: theme.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            items: const [
              DropdownMenuItem(
                value: 'lose',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16, color: AppColors.orange),
                    SizedBox(width: 8),
                    Text('Lose Weight'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'gain',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 16, color: AppColors.green),
                    SizedBox(width: 8),
                    Text('Gain Weight'),
                  ],
                ),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedNewGoalType = val;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newGoalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryText),
          decoration: InputDecoration(
            hintText: "Enter weight in kg",
            hintStyle: TextStyle(color: theme.tertiaryText.withOpacity(0.6)),
            prefixIcon: Icon(Icons.scale, color: theme.primaryText, size: 20),
            suffixText: 'kg',
            suffixStyle: TextStyle(
              color: theme.tertiaryText,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: theme.borderColor.withOpacity(0.2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final parsed = double.tryParse(_newGoalController.text);
                  if (parsed == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid number'),
                        backgroundColor: AppColors.orange,
                      ),
                    );
                    return;
                  }
                  _updateGoalWeightAndType(parsed, _selectedNewGoalType);
                  _newGoalController.clear();
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _showNewGoalInput = false;
                    _showGoalOptions = false;
                  });
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Save Goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _newGoalController.clear();
                setState(() {
                  _showNewGoalInput = false;
                  _showGoalOptions = false;
                });
              },
              icon: Icon(Icons.close, color: AppColors.orange),
              style: IconButton.styleFrom(
                backgroundColor: theme.borderColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // Keep the old method for backward compatibility
  Future<void> _saveWeightUpdate(double weight, double? height) async {
    await _saveWeightUpdateWithAchievementCheck(weight, height);
  }

  Widget _buildGraphCard() {
    final theme = Provider.of<ThemeManager>(context);
    return _cardWrapper(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _smallIconBox(Icons.show_chart),
          const SizedBox(width: 12),
          Expanded(child: Text('Progress Graph', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryText))),
          Text('${_progressData.length} entries', style: TextStyle(color: theme.secondaryText, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _ProgressGraph(data: _progressData),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('BMR', AppColors.accentCyan),
            const SizedBox(width: 24),
            _buildLegendItem('BMI', AppColors.accentBlue),
          ],
        ),
      ]),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final theme = Provider.of<ThemeManager>(context);
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: theme.secondaryText)),
      ],
    );
  }

  Widget _buildFoodCarousel() {
    final theme = Provider.of<ThemeManager>(context);
    final foods = _timeFoods;
    const itemWidth = 160.0;
    const itemHeight = 220.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.accentBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended for You',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Personalized meal suggestions',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.tertiaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.recommend, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${foods.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: itemHeight,
            child: foods.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.borderColor.withOpacity(0.5),
                            theme.borderColor.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant, color: theme.tertiaryText, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No recommendations yet',
                            style: TextStyle(
                              color: theme.secondaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Update your profile for personalized suggestions',
                            style: TextStyle(
                              color: theme.tertiaryText,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: FoodItemCard(
                                food: foods[index],
                                width: itemWidth,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseButton() {
    final theme = Provider.of<ThemeManager>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        elevation: 8,
        shadowColor: theme.shadowColor,
        child: InkWell(
         onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExercisePage(), 
            ),
          );
        },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
           decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentBlue, AppColors.accentCyan],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Color(0xFFFFFFB3)]).createShader(bounds),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Text('Start Your Workout Now', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, shadows: [const Shadow(color: Colors.black26, blurRadius: 4)])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _smallIconBox(IconData icon) {
    final theme = Provider.of<ThemeManager>(context);
    return Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 22, color: theme.primaryText),
    );
  }

  Widget _cardWrapper({required Widget child, EdgeInsetsGeometry? margin}) {
    final theme = Provider.of<ThemeManager>(context);
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, bool small = true}) {
    final theme = Provider.of<ThemeManager>(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: small ? 18 : 24, color: theme.tertiaryText),
        filled: true,
        fillColor: theme.borderColor.withOpacity(0.2),
        contentPadding: EdgeInsets.symmetric(vertical: small ? 10 : 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      style: TextStyle(fontSize: small ? 13 : 14, color: theme.primaryText),
    );
  }

  @override
  Widget build(BuildContext context) {
    _filterFoodsByTime();

    return SafeArea(
      child: Material(
        color: Provider.of<ThemeManager>(context).surfaceColor.withOpacity(0.03),
        child: Column(
          children: [
            _buildTopGreeting(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _buildBmrBmiCard(),
                  _buildWeightBatteryCard(),
                  _buildGraphCard(),
                  _buildFoodCarousel(),
                  _buildExerciseButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Interactive Progress Graph Widget ---
class _ProgressGraph extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const _ProgressGraph({required this.data});

  @override
  State<_ProgressGraph> createState() => _ProgressGraphState();
}

class _ProgressGraphState extends State<_ProgressGraph> {
  int? _hoveredIndex;
  Offset _hoverPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    if (widget.data.isEmpty) {
      return Center(
        child: Text('No data available', style: TextStyle(color: theme.tertiaryText)),
      );
    }

    return MouseRegion(
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(event.position);
          _updateHoveredPoint(localPosition, box.size);
        }
      },
      onExit: (event) {
        setState(() {
          _hoveredIndex = null;
        });
      },
      child: Stack(
        children: [
          CustomPaint(
            painter: _GraphPainter(
              data: widget.data,
              hoveredIndex: _hoveredIndex,
            ),
            child: Container(),
          ),
          if (_hoveredIndex != null && _hoveredIndex! < widget.data.length)
            _buildHoverTooltip(),
        ],
      ),
    );
  }

  void _updateHoveredPoint(Offset localPosition, Size size) {
    final padding = 50.0;
    final graphWidth = size.width - padding * 2;
    
    double closestDistance = double.infinity;
    int? newHoveredIndex;

    for (int i = 0; i < widget.data.length; i++) {
      final x = padding + (graphWidth * i / (widget.data.length > 1 ? widget.data.length - 1 : 1));
      final pointDistance = (localPosition.dx - x).abs();
      
      if (pointDistance < 20 && pointDistance < closestDistance) {
        closestDistance = pointDistance;
        newHoveredIndex = i;
      }
    }

    if (newHoveredIndex != _hoveredIndex) {
      setState(() {
        _hoveredIndex = newHoveredIndex;
        _hoverPosition = localPosition;
      });
    }
  }

  Widget _buildHoverTooltip() {
    final theme = Provider.of<ThemeManager>(context);
    if (_hoveredIndex == null || _hoveredIndex! >= widget.data.length) {
      return const SizedBox();
    }

    final pointData = widget.data[_hoveredIndex!];
    final bmr = pointData['bmr'] as double;
    final bmi = pointData['bmi'] as double;

    return Positioned(
      left: _hoverPosition.dx - 80,
      top: _hoverPosition.dy - 80,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.borderColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTooltipRow('BMR', '${bmr.round()} kcal', Icons.local_fire_department, color: AppColors.accentCyan),
            const SizedBox(height: 6),
            _buildTooltipRow('BMI', bmi.toStringAsFixed(1), Icons.monitor_weight, color: _getBMIColor(bmi)),
            const SizedBox(height: 4),
            Text(
              'Category: ${HealthCalculator.getBMICategory(bmi)}',
              style: TextStyle(
                fontSize: 10,
                color: _getBMIColor(bmi),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipRow(String label, String value, IconData icon, {Color color = AppColors.accentCyan}) {
    final theme = Provider.of<ThemeManager>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return AppColors.orange;
    if (bmi < 25) return AppColors.green;
    if (bmi < 30) return AppColors.orange;
    return AppColors.orange;
  }
}

// --- Updated Graph Painter ---
class _GraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int? hoveredIndex;

  _GraphPainter({required this.data, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 50.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // Find min/max for BMR (left axis)
    double minBMR = data.map((e) => e['bmr'] as double).reduce((a, b) => a < b ? a : b);
    double maxBMR = data.map((e) => e['bmr'] as double).reduce((a, b) => a > b ? a : b);
    double bmrRange = maxBMR - minBMR;
    if (bmrRange == 0) bmrRange = 100;
    minBMR -= bmrRange * 0.1;
    maxBMR += bmrRange * 0.1;

    // Find min/max for BMI (right axis)
    double minBMI = data.map((e) => e['bmi'] as double).reduce((a, b) => a < b ? a : b);
    double maxBMI = data.map((e) => e['bmi'] as double).reduce((a, b) => a > b ? a : b);
    double bmiRange = maxBMI - minBMI;
    if (bmiRange == 0) bmiRange = 2;
    minBMI -= bmiRange * 0.15;
    maxBMI += bmiRange * 0.15;

    // Draw background grid
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      double y = padding + (graphHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw BMR line with area fill
    final bmrPath = Path();
    final bmrAreaPath = Path();
    
    for (int i = 0; i < data.length; i++) {
      double x = padding + (graphWidth * i / (data.length > 1 ? data.length - 1 : 1));
      double normalizedBMR = (data[i]['bmr'] - minBMR) / (maxBMR - minBMR);
      double y = padding + graphHeight - (normalizedBMR * graphHeight);

      if (i == 0) {
        bmrPath.moveTo(x, y);
        bmrAreaPath.moveTo(x, padding + graphHeight);
        bmrAreaPath.lineTo(x, y);
      } else {
        bmrPath.lineTo(x, y);
        bmrAreaPath.lineTo(x, y);
      }
      
      if (i == data.length - 1) {
        bmrAreaPath.lineTo(x, padding + graphHeight);
        bmrAreaPath.close();
      }
    }

    // Fill area under BMR line
    final bmrAreaPaint = Paint()
      ..color = AppColors.accentCyan.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bmrAreaPath, bmrAreaPaint);

    // Draw BMR line
    final bmrPaint = Paint()
      ..color = AppColors.accentCyan
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bmrPath, bmrPaint);

    // Draw BMI line with area fill
    final bmiPath = Path();
    final bmiAreaPath = Path();
    
    for (int i = 0; i < data.length; i++) {
      double x = padding + (graphWidth * i / (data.length > 1 ? data.length - 1 : 1));
      double normalizedBMI = (data[i]['bmi'] - minBMI) / (maxBMI - minBMI);
      double y = padding + graphHeight - (normalizedBMI * graphHeight);

      if (i == 0) {
        bmiPath.moveTo(x, y);
        bmiAreaPath.moveTo(x, padding + graphHeight);
        bmiAreaPath.lineTo(x, y);
      } else {
        bmiPath.lineTo(x, y);
        bmiAreaPath.lineTo(x, y);
      }
      
      if (i == data.length - 1) {
        bmiAreaPath.lineTo(x, padding + graphHeight);
        bmiAreaPath.close();
      }
    }

    // Fill area under BMI line
    final bmiAreaPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bmiAreaPath, bmiAreaPaint);

    // Draw BMI line
    final bmiPaint = Paint()
      ..color = AppColors.accentBlue
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bmiPath, bmiPaint);

    // Draw points and highlight hovered point
    for (int i = 0; i < data.length; i++) {
      double x = padding + (graphWidth * i / (data.length > 1 ? data.length - 1 : 1));
      
      // BMR point
      double normalizedBMR = (data[i]['bmr'] - minBMR) / (maxBMR - minBMR);
      double bmrY = padding + graphHeight - (normalizedBMR * graphHeight);
      
      // BMI point  
      double normalizedBMI = (data[i]['bmi'] - minBMI) / (maxBMI - minBMI);
      double bmiY = padding + graphHeight - (normalizedBMI * graphHeight);

      // Highlight hovered point
      if (i == hoveredIndex) {
        final highlightPaint = Paint()
          ..color = AppColors.accentBlue.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, bmrY), 12, highlightPaint);
        canvas.drawCircle(Offset(x, bmiY), 12, highlightPaint);
      }

      // BMR point with border
      final bmrPointBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == hoveredIndex ? 3 : 2;
      final bmrPointPaint = Paint()
        ..color = i == hoveredIndex ? AppColors.accentCyan : AppColors.accentCyan.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, bmrY), i == hoveredIndex ? 8 : 5, bmrPointBorderPaint);
      canvas.drawCircle(Offset(x, bmrY), i == hoveredIndex ? 7 : 4, bmrPointPaint);

      // BMI point with border
      final bmiPointBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == hoveredIndex ? 3 : 2;
      final bmiPointPaint = Paint()
        ..color = i == hoveredIndex ? AppColors.accentBlue : AppColors.accentBlue.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, bmiY), i == hoveredIndex ? 8 : 5, bmiPointBorderPaint);
      canvas.drawCircle(Offset(x, bmiY), i == hoveredIndex ? 7 : 4, bmiPointPaint);
    }

    // Draw axes labels with simple text rendering
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    // Left axis (BMR) labels
    for (int i = 0; i <= 4; i++) {
      double y = padding + (graphHeight * i / 4);
      double bmrValue = maxBMR - ((maxBMR - minBMR) * i / 4);
      _drawText(canvas, bmrValue.round().toString(), Offset(5, y - 6), textStyle.copyWith(color: AppColors.accentCyan));
    }

    // Right axis (BMI) labels
    for (int i = 0; i <= 4; i++) {
      double y = padding + (graphHeight * i / 4);
      double bmiValue = maxBMI - ((maxBMI - minBMI) * i / 4);
      _drawText(canvas, bmiValue.toStringAsFixed(1), Offset(size.width - padding + 5, y - 6), textStyle.copyWith(color: AppColors.accentBlue));
    }

    // Draw date labels at bottom
    final maxLabels = data.length > 7 ? 7 : data.length;
    for (int i = 0; i < data.length; i++) {
      if (data.length <= 7 || i % (data.length ~/ maxLabels) == 0 || i == data.length - 1) {
        double x = padding + (graphWidth * i / (data.length > 1 ? data.length - 1 : 1));
        final date = data[i]['date'] as DateTime;
        _drawText(
          canvas, 
          '${date.month}/${date.day}', 
          Offset(x - 10, size.height - padding + 12), 
          textStyle.copyWith(
            color: i == hoveredIndex ? AppColors.accentBlue : Colors.black87,
            fontSize: i == hoveredIndex ? 11 : 9,
            fontWeight: i == hoveredIndex ? FontWeight.bold : FontWeight.normal,
          )
        );
      }
    }
  }

  // Helper method to draw text without using TextPainter
  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return data != oldDelegate.data || hoveredIndex != oldDelegate.hoveredIndex;
  }
}

// PART 2: WEIGHT BATTERY

class _WeightActionButton extends StatefulWidget {
  final TextEditingController weightController;
  final bool isGain;
  final double currentWeight;
  final VoidCallback onSave;
  final bool isGoalReached;

  const _WeightActionButton({
    required this.weightController,
    required this.isGain,
    required this.currentWeight,
    required this.onSave,
    required this.isGoalReached,
  });

  @override
  State<_WeightActionButton> createState() => _WeightActionButtonState();
}

class _WeightActionButtonState extends State<_WeightActionButton> {
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Do not autofill weightController text here to keep it empty on edit start
  }

  _HomeContentState get _parentState => context.findAncestorStateOfType<_HomeContentState>()!;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: _isEditing ? theme.borderColor.withOpacity(0.2) : AppColors.accentBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isEditing ? theme.borderColor.withOpacity(0.5) : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: _isEditing ? Colors.transparent : AppColors.accentBlue.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
            },
            child: _isEditing ? _buildEditState() : _buildIdleState(),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Padding(
      key: const ValueKey<bool>(false),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: InkWell(
        onTap: () {
          widget.weightController.clear();
          setState(() => _isEditing = true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accentBlue, AppColors.accentCyan]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.isGain ? 'Update Weight (Gain)' : 'Update Weight (Lose)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditState() {
    return Padding(
      key: const ValueKey<bool>(true),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _parentState._inputField(controller: widget.weightController, hint: 'Weight (kg)', icon: Icons.scale, small: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onSave();
                    setState(() => _isEditing = false);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(widget.isGain ? 'Save (Gain)' : 'Save (Lose)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => setState(() => _isEditing = false),
                  icon: Icon(Icons.close, size: 18, color: AppColors.orange),
                  label: Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Supporting Widgets ---
class VerticalBattery extends StatelessWidget {
  final double percent;
  final double width;
  final double height;
  final Color fillColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showPercentage;

  const VerticalBattery({
    super.key,
    required this.percent,
    this.width = 36,
    this.height = 140,
    this.fillColor = AppColors.accentBlue,
    this.backgroundColor = Colors.grey,
    this.borderColor = Colors.black54,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final innerHeight = (height - 8);
    final fillHeight = (clamped * innerHeight).clamp(0.0, innerHeight);
    return Column(
      children: [
        Container(width: width * 0.6, height: height * 0.06, decoration: BoxDecoration(color: borderColor.withOpacity(0.6), borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 6),
        Stack(alignment: Alignment.bottomCenter, children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: backgroundColor, border: Border.all(color: borderColor, width: 1.4)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: width - 6,
            height: fillHeight,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: const Radius.circular(6), top: Radius.circular(fillHeight < 8 ? 6 : 0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]),
          ),
          if (showPercentage)
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(child: Text('${(clamped * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 1))]))),
            ),
        ]),
      ],
    );
  }
}

class FoodItemCard extends StatefulWidget {
  final Map<String, dynamic> food;
  final double width;

  const FoodItemCard({
    super.key,
    required this.food,
    required this.width,
  });

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showFoodDetails() {
    final theme = Provider.of<ThemeManager>(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentBlue, AppColors.accentCyan],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.food['icon'] as IconData, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.food['name'] as String,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryText),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: AppColors.accentCyan),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.food['kcal']} calories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.food['desc'] as String,
              style: TextStyle(fontSize: 14, height: 1.5, color: theme.primaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontSize: 16, color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        _showFoodDetails();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isPressed 
                    ? AppColors.accentBlue.withOpacity(0.3)
                    : AppColors.accentBlue.withOpacity(0.15),
                blurRadius: _isPressed ? 12 : 16,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBlue.withOpacity(0.9),
                        AppColors.accentBlue,
                        AppColors.accentCyan,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                
                // Animated pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PatternPainter(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with glow effect
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            widget.food['icon'] as IconData,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Food name
                      Text(
                        widget.food['name'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Calorie badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, 
                              color: Colors.white, 
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.food['kcal']} kcal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Use Spacer() to push the button down, and Flexible to constrain the text.
                      const Spacer(), 
                      
                      // Description
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          widget.food['desc'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // View details button
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 20.0;
    
    // Draw diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}