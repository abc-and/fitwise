// dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'exercise_page.dart';
import 'constants/app_colors.dart';
import '../models/food_recommendation.dart';
import '../providers/food_recommendation_service.dart';
import 'package:fitwise/providers/fitness_provider.dart';

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
          const SnackBar(
            content: Text('You have been logged out.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeContent(),
      const ExercisePage(), 
      const SimplePlaceholder(title: 'Calorie Log'),
      const SimplePlaceholder(title: 'Daily Streak'),
      const SimplePlaceholder(title: 'User Profile'),
    ];

    return DefaultTabController(
      length: screens.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'FitWise Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          elevation: 4,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Exercise'),
              Tab(icon: Icon(Icons.restaurant), text: 'Calories'),
              Tab(icon: Icon(Icons.local_fire_department), text: 'Streak'),
              Tab(icon: Icon(Icons.person), text: 'Profile'),
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
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
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
  String? _targetDuration;
  
  // Calculated values
  double _bmr = 0;
  double _bmi = 0;
  String _bmiCategory = '';
  
  //battery
// NEW state variable: mark if goal was completed (persisted in firestore)
bool _goalCompleted = false;

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
                                  Colors.orange.shade600,
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
                            child: const Icon(
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
                          Colors.purple.shade600,
                          Colors.blue.shade600,
                        ],
                      ).createShader(bounds),
                      child: const Text(
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
                        color: Colors.grey.shade700,
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
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Button
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
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
  // After congratulatory message, allow user to set a new goal
  // UI already supports this in _buildGoalSection
}
// Call this to set a brand-new goal (user inputs weight + optional type)
Future<void> _updateGoalWeightAndType(double newGoalWeight, String newType) async {
  final user = _auth.currentUser;
    setState(() {
      _goalWeight = newGoalWeight;
      _goalType = newType;
      _startWeight = _currentWeight; // Always reset start weight to current
      _goalCompleted = false;
    });

  if (user != null) {
    try {
      await _firestore.collection('user_info').doc(user.uid).update({
        'goalWeight': newGoalWeight,
        'goalType': newType,
        'goalCompleted': false,
      });
    } catch (e) {
      debugPrint('Error saving new goal to firestore: $e');
    }
  }
}


  // Historical data for graph (simulated)
  List<Map<String, dynamic>> _progressData = [];
  
// Food carousel
late List<Map<String, dynamic>> _timeFoods = []; // Initialized

// NEW: User Info Data Model
UserInfoData? _userInfo; // To store all user info for recommendations

// Services
final FoodRecommendationService _recommendationService = FoodRecommendationService(); // <--- NEW SERVICE INSTANCE

// Controllers
final TextEditingController _weightController = TextEditingController();
final TextEditingController _heightController = TextEditingController();

@override
void initState() {
  super.initState();
  // We remove _prepareFoods and call _fetchUserData first
  _fetchUserData(); 
}


void _filterFoodsByTime() {
  if (_userInfo == null) return; // Wait for user data

  final h = DateTime.now().hour;
  String type = (h >= 5 && h < 12) ? 'morning' : (h >= 12 && h < 18) ? 'afternoon' : 'evening';

  // New Declaration (Add this to your state class, e.g., in Part 1)
final FoodRecommendationService _recommendationService = FoodRecommendationService();
  _timeFoods = _recommendationService.getRecommendations(
    userInfo: _userInfo!,
    timeOfDay: type,
  );
  
  // Trigger UI update
  if (mounted) {
      setState(() {});
  }
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
    final targetGoal = data['targetGoal']?.toString() ?? 'Maintenance';
    final dietType = data['dietType']?.toString() ?? 'Balanced';
    final dietaryRestrictions = data['dietaryRestrictions']?.toString() ?? 'None';
    final allergies = data['allergies']?.toString() ?? 'Others';
    final otherConditions = data['otherConditions']?.toString() ?? 'Others';

    _userInfo = UserInfoData(
      currentWeight: currentWeight,
      heightCm: heightCm,
      age: age,
      sex: sex,
      activityLevel: activityLevel,
      reproductiveStatus: reproductiveStatus,
      targetGoal: targetGoal,
      dietType: dietType,
      dietaryRestrictions: dietaryRestrictions,
      allergies: allergies, 
      otherConditions: otherConditions, 
    );

    // Update state variables and call food filtering/recommendation
    _currentWeight = currentWeight;
    if (_startWeight == 0.0) {
      _startWeight = _currentWeight;
      _markGoalCompleted();
    }
 // Set start weight as current if not set
    _heightCm = heightCm;
    _age = age;
    _sex = sex;
    _activityLevel = activityLevel;
    _reproductiveStatus = reproductiveStatus;
    
          // Get target goal and determine goal type
// Prefer an absolute stored goalWeight if present
    if (data.containsKey('goalWeight')) {
      _goalWeight = double.tryParse(data['goalWeight'].toString()) ?? _goalWeight;
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

          
          // Get target date and duration
          if (data.containsKey('targetDate')) {
            _targetDate = data['targetDate'].toString();
          }
          if (data.containsKey('targetDuration')) {
            _targetDuration = data['targetDuration'].toString();
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
  
  // Generate simulated weekly progress data
  // Fetch progress data from Firebase
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
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  double _batteryPercent() {
    final isGain = _goalType == 'gain';
    if (_startWeight == _goalWeight) return 0.0;
    double progress;
    if (isGain) {
      progress = (_currentWeight - _startWeight) / (_goalWeight - _startWeight);
    } else {
      progress = (_startWeight - _currentWeight) / (_startWeight - _goalWeight);
    }
    // Clamp between 0 and 1 for UI, but allow proportional progress
    if (progress.isNaN || progress.isInfinite) return 0.0;
    return progress.clamp(0.0, 1.0);
  }

  Widget _buildTopGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.accent1, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.dark1.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.self_improvement, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(), style: const TextStyle(fontSize: 14, color: AppColors.darkGray)),
              const SizedBox(height: 4),
              _loadingUser ? const Text('Loading...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)) : Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [Icon(Icons.local_fire_department, color: AppColors.blue), SizedBox(width: 6), Text('${_bmr.round()} kcal', style: TextStyle(fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  Widget _buildBmrBmiCard() {
    return _cardWrapper(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _smallIconBox(Icons.insights),
          const SizedBox(width: 12),
          const Expanded(child: Text('Health Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
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
                color: AppColors.blue,
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
              color: AppColors.lightBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppColors.blue),
                const SizedBox(width: 8),
                Text('Target Date: $_targetDate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ]),
    );
  }
  
  Color _getBMIColor() {
    if (_bmi < 18.5) return Colors.orange;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildMetricBox({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
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
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.darkGray, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: TextStyle(fontSize: 11, color: AppColors.mediumGray)),
        ],
      ),
    );
  }

//BATTERY PART 1

Widget _buildWeightBatteryCard() {
  final pct = _batteryPercent();
  final pctRounded = (pct * 100).round();
  final isGain = _goalType == 'gain';
  final isGoalReached = _hasReachedGoal();

  // handleSave will update weight + height, then check for goal completion
  void handleSave() async {
    final wt = double.tryParse(_weightController.text);
    if (wt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    final ht = double.tryParse(_heightController.text);
    if (ht != null && ht > 0) _heightCm = ht;

    setState(() {
      _currentWeight = wt;
      _calculateHealthMetrics();
    });

    await _saveWeightUpdate(wt, ht);

    // refresh progress data
    await Future.delayed(const Duration(milliseconds: 300));
    await _fetchProgressData();

    _weightController.clear();
    _heightController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weight updated: ${wt.toStringAsFixed(1)} kg'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Auto-check completion — will mark firestore and show dialog once
    _markGoalCompleted();
  }


  // Build the goal display / editor area
  Widget _buildGoalSection() {
    // Only show the new goal input if the goal is completed (not just reached, but marked completed)
    if (_goalCompleted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set a New Goal', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedNewGoalType,
                items: const [
                  DropdownMenuItem(value: 'lose', child: Text('Lose')),
                  DropdownMenuItem(value: 'gain', child: Text('Gain')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedNewGoalType = val;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _newGoalController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: "kg",
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final parsed = double.tryParse(_newGoalController.text);
                  if (parsed == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid number for the goal weight')),
                    );
                    return;
                  }
                  _updateGoalWeightAndType(parsed, _selectedNewGoalType);
                  _newGoalController.clear();
                  FocusScope.of(context).unfocus();
                },
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Current goal: ${_goalWeight.toStringAsFixed(1)} kg (${_goalType.toUpperCase()})', style: const TextStyle(color: AppColors.darkGray)),
        ],
      );
    }

    // Normal display: show the current goal text
    return Text(
      'Goal: ${_goalWeight.toStringAsFixed(1)} kg (${_goalType.toUpperCase()})',
      style: const TextStyle(color: AppColors.darkGray),
    );
  }

  return _cardWrapper(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              isGain ? 'Gain Goal' : 'Lose Goal',
              style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
            ),
            const SizedBox(height: 8),
            VerticalBattery(
              percent: pct,
              width: 48,
              height: 160,
              fillColor: AppColors.primary,
              backgroundColor: AppColors.lightGray.withOpacity(0.15),
              borderColor: AppColors.charcoal.withOpacity(0.18),
              showPercentage: false,
            ),
            const SizedBox(height: 8),
            Text('$pctRounded%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Weight Progress', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Current: ${_currentWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),

              // Goal section (display or editable after completion)
              _buildGoalSection(),

              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: AppColors.lightGray, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              // Show the weight/height update UI and toggle only if goal is not yet completed.
              if (!_goalCompleted)
                _WeightActionButton(
                  weightController: _weightController,
                  heightController: _heightController,
                  isGain: isGain,
                  currentWeight: _currentWeight,
                  onSave: handleSave,
                  onToggleGoal: () {
                    // toggle UI & persist toggle type
                    final newType = isGain ? 'lose' : 'gain';
                    setState(() => _goalType = newType);
                    final user = _auth.currentUser;
                    if (user != null) {
                      _firestore.collection('user_info').doc(user.uid).update({'goalType': newType}).catchError((e) {
                        debugPrint('Failed to persist goalType toggle: $e');
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Goal set to ${_goalType.toUpperCase()}')),
                    );
                  },
                  isGoalReached: isGoalReached,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}


Future<void> _saveWeightUpdate(double weight, double? height) async {
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
  } catch (e) {
    debugPrint('Error saving weight update: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Widget _buildGraphCard() {
    return _cardWrapper(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _smallIconBox(Icons.show_chart),
          const SizedBox(width: 12),
          const Expanded(child: Text('Progress Graph', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Text('${_progressData.length} entries', style: TextStyle(color: AppColors.darkGray, fontSize: 12)),
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
            _buildLegendItem('BMR', AppColors.blue),
            const SizedBox(width: 24),
            _buildLegendItem('BMI', Colors.green),
          ],
        ),
      ]),
    );
  }


  Widget _buildLegendItem(String label, Color color) {
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
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.darkGray)),
      ],
    );
  }

  Widget _buildFoodCarousel() {
    final foods = _timeFoods;
    const itemWidth = 120.0;
    const itemHeight = 160.0;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: Row(children: [
          _smallIconBox(Icons.restaurant),
          const SizedBox(width: 12),
          Expanded(child: Text('Recommended for ${_greeting().split(' ').last}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          // You might want to navigate to a full recommendations screen here
          const Icon(Icons.chevron_right, color: AppColors.darkGray), 
        ]),
      ),
      SizedBox(
        height: itemHeight,
        child: _userInfo == null && foods.isEmpty // Show loading only if user info hasn't loaded and foods is empty
            ? const Center(child: CircularProgressIndicator())
            : foods.isEmpty // Show message if data is loaded but foods list is empty
                ? const Center(child: Text('No custom recommendations yet. Try updating your profile!'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      return FoodItemCard(
                        food: foods[index],
                        width: itemWidth,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${foods[index]['name']} selected'))),
                      );
                    },
                  ),
      ),
    ]),
  );
}

  Widget _buildExerciseButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        elevation: 8,
        shadowColor: AppColors.primary.withOpacity(0.4),
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start Exercise - placeholder'))),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.accent1, AppColors.primary], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Color(0xFFFFFFB3)]).createShader(bounds),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Start Your Workout Now', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _smallIconBox(IconData icon) {
    return Container(
      decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 22, color: AppColors.blue),
    );
  }

  Widget _cardWrapper({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.dark1.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))]),
      child: child,
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, bool small = true}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: small ? 18 : 24, color: AppColors.mediumDark),
        filled: true,
        fillColor: AppColors.lightBlue.withOpacity(0.08),
        contentPadding: EdgeInsets.symmetric(vertical: small ? 10 : 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      style: TextStyle(fontSize: small ? 13 : 14, color: AppColors.mediumDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    _filterFoodsByTime();

    return SafeArea(
      child: Material(
        color: AppColors.tertiary.withOpacity(0.03),
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
    if (widget.data.isEmpty) {
      return Center(
        child: Text('No data available', style: TextStyle(color: AppColors.mediumGray)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.mediumGray.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTooltipRow('BMR', '${bmr.round()} kcal', Icons.local_fire_department, color: AppColors.blue),
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

  Widget _buildTooltipRow(String label, String value, IconData icon, {Color color = AppColors.darkGray}) {
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
              color: AppColors.darkGray,
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
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
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
      ..color = AppColors.lightGray.withOpacity(0.2)
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
      ..color = AppColors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bmrAreaPath, bmrAreaPaint);

    // Draw BMR line
    final bmrPaint = Paint()
      ..color = AppColors.blue
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
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bmiAreaPath, bmiAreaPaint);

    // Draw BMI line
    final bmiPaint = Paint()
      ..color = Colors.green
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
          ..color = AppColors.primary.withOpacity(0.3)
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
        ..color = i == hoveredIndex ? AppColors.blue : AppColors.blue.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, bmrY), i == hoveredIndex ? 8 : 5, bmrPointBorderPaint);
      canvas.drawCircle(Offset(x, bmrY), i == hoveredIndex ? 7 : 4, bmrPointPaint);

      // BMI point with border
      final bmiPointBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == hoveredIndex ? 3 : 2;
      final bmiPointPaint = Paint()
        ..color = i == hoveredIndex ? Colors.green : Colors.green.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, bmiY), i == hoveredIndex ? 8 : 5, bmiPointBorderPaint);
      canvas.drawCircle(Offset(x, bmiY), i == hoveredIndex ? 7 : 4, bmiPointPaint);
    }

    // Draw axes labels with simple text rendering
    final textStyle = TextStyle(
      color: AppColors.darkGray,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    // Left axis (BMR) labels
    for (int i = 0; i <= 4; i++) {
      double y = padding + (graphHeight * i / 4);
      double bmrValue = maxBMR - ((maxBMR - minBMR) * i / 4);
      _drawText(canvas, bmrValue.round().toString(), Offset(5, y - 6), textStyle.copyWith(color: AppColors.blue));
    }

    // Right axis (BMI) labels
    for (int i = 0; i <= 4; i++) {
      double y = padding + (graphHeight * i / 4);
      double bmiValue = maxBMI - ((maxBMI - minBMI) * i / 4);
      _drawText(canvas, bmiValue.toStringAsFixed(1), Offset(size.width - padding + 5, y - 6), textStyle.copyWith(color: Colors.green));
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
            color: i == hoveredIndex ? AppColors.primary : AppColors.darkGray,
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
  final TextEditingController heightController;
  final bool isGain;
  final double currentWeight;
  final VoidCallback onSave;
  final VoidCallback onToggleGoal;
  final bool isGoalReached;

  const _WeightActionButton({
    required this.weightController,
    required this.heightController,
    required this.isGain,
    required this.currentWeight,
    required this.onSave,
    required this.onToggleGoal,
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
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: _isEditing ? AppColors.lightGray.withOpacity(0.2) : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isEditing ? AppColors.mediumGray.withOpacity(0.5) : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: _isEditing ? Colors.transparent : AppColors.primary.withOpacity(0.4),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              widget.weightController.clear();
              widget.heightController.clear();
              setState(() => _isEditing = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.accent1, AppColors.primary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Update Weight/Height', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
          Container(
            height: 30,
            margin: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: widget.onToggleGoal,
              icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.charcoal),
              label: Text('Toggle Goal (${widget.isGain ? 'Gain' : 'Lose'})', style: const TextStyle(fontSize: 12, color: AppColors.charcoal, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ),
        ],
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
          Row(
            children: [
              Expanded(child: _parentState._inputField(controller: widget.weightController, hint: 'Weight (kg)', icon: Icons.scale, small: true)),
              const SizedBox(width: 8),
              Expanded(child: _parentState._inputField(controller: widget.heightController, hint: 'Height (cm)', icon: Icons.height, small: true)),
            ],
          ),
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
                  label: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                  icon: const Icon(Icons.close, size: 18, color: AppColors.charcoal),
                  label: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
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
    this.fillColor = AppColors.primary,
    this.backgroundColor = AppColors.lightGray,
    this.borderColor = AppColors.charcoal,
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
            decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.vertical(bottom: const Radius.circular(6), top: Radius.circular(fillHeight < 8 ? 6 : 0)), boxShadow: [BoxShadow(color: AppColors.dark1.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]),
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

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final double width;
  final VoidCallback onTap;

  const FoodItemCard({
    super.key,
    required this.food,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        elevation: 6,
        shadowColor: AppColors.primary.withOpacity(0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent1.withOpacity(0.8), AppColors.primary.withOpacity(0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(food['icon'] as IconData, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  food['name'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${food['kcal']} kcal',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                ),
                const Spacer(),
                Text(
                  food['desc'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}