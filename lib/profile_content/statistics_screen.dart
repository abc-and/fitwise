import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme.dart';
import '../constants/app_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Statistics data
  int _totalWorkouts = 0;
  int _activeDays = 0;
  int _currentStreak = 0;
  double _weightLoss = 0.0;
  int _averageDuration = 0;
  bool _loading = true;

  // Additional analytics
  int _thisMonthWorkouts = 0;
  int _lastMonthWorkouts = 0;
  double _progressPercentage = 0.0;
  int _longestStreak = 0;
  
  // Calorie statistics
  int _totalCaloriesLogged = 0;
  int _averageDailyCalories = 0;
  int _daysWithCalorieLog = 0;

  List<Map<String, String>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    setState(() => _loading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      await Future.wait([
        _fetchWorkoutStats(user.uid),
        _fetchStreakStats(user.uid),
        _fetchWeightProgress(user.uid),
        _fetchCalorieStats(user.uid),
      ]);

      _generateAchievements();
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Fetch workout statistics from workouts collection
  Future<void> _fetchWorkoutStats(String userId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // Fetch all workouts
      final allWorkoutsQuery = await _firestore
          .collection('user_workouts')
          .doc(userId)
          .collection('workouts')
          .orderBy('timestamp', descending: true)
          .get();

      // Calculate this month's workouts
      final thisMonthWorkouts = allWorkoutsQuery.docs.where((doc) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        return timestamp != null && timestamp.isAfter(monthStart);
      }).toList();

      _thisMonthWorkouts = thisMonthWorkouts.length;

      // Calculate statistics from this month's workouts
      Set<String> uniqueDays = {};

      for (var doc in thisMonthWorkouts) {
        final data = doc.data();
        
        // Count unique days
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          uniqueDays.add(dateKey);
        }
      }

      _activeDays = uniqueDays.length;

      debugPrint('✅ Workout stats: This Month: $_thisMonthWorkouts, Active Days: $_activeDays');
    } catch (e) {
      debugPrint('❌ Error fetching workout stats: $e');
    }
  }

  // Fetch streak statistics from streaks collection
  Future<void> _fetchStreakStats(String userId) async {
    try {
      final doc = await _firestore.collection('streaks').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _currentStreak = data['currentStreak'] ?? 0;
        _longestStreak = data['bestStreak'] ?? 0;
        
        debugPrint('✅ Streak stats: Current: $_currentStreak, Best: $_longestStreak');
      }
    } catch (e) {
      debugPrint('❌ Error fetching streak stats: $e');
    }
  }

  // Fetch weight progress from user_info collection
  Future<void> _fetchWeightProgress(String userId) async {
    try {
      final infoDoc = await _firestore.collection('user_info').doc(userId).get();
      
      if (!infoDoc.exists) {
        debugPrint('⚠️ No user info found');
        return;
      }

      final data = infoDoc.data()!;
      
      // Parse current weight
      final currentWeight = _parseWeight(data['weight']);
      
      // Get start weight
      final startWeight = data.containsKey('startWeight')
          ? double.tryParse(data['startWeight'].toString()) ?? currentWeight
          : currentWeight;
      
      // Calculate weight change
      final weightChange = (startWeight - currentWeight).abs();
      _weightLoss = weightChange;

      // Get goal weight to calculate progress percentage
      final goalType = data['goalType']?.toString().toLowerCase() ?? 'lose';
      double goalWeight = currentWeight;
      
      if (data.containsKey('targetWeightLoss') && data['targetWeightLoss'] != null) {
        final loss = double.tryParse(data['targetWeightLoss'].toString());
        if (loss != null) {
          goalWeight = startWeight - loss;
        }
      } else if (data.containsKey('targetWeightGain') && data['targetWeightGain'] != null) {
        final gain = double.tryParse(data['targetWeightGain'].toString());
        if (gain != null) {
          goalWeight = startWeight + gain;
        }
      }

      // Calculate progress percentage
      if (goalWeight != startWeight) {
        final totalProgress = (startWeight - goalWeight).abs();
        final currentProgress = (startWeight - currentWeight).abs();
        _progressPercentage = ((currentProgress / totalProgress) * 100).clamp(0.0, 100.0);
      }

      debugPrint('✅ Weight progress: Loss: ${_weightLoss.toStringAsFixed(1)} kg, Progress: ${_progressPercentage.toStringAsFixed(1)}%');
    } catch (e) {
      debugPrint('❌ Error fetching weight progress: $e');
    }
  }

  // Fetch calorie statistics from calorieLogs collection
  Future<void> _fetchCalorieStats(String userId) async {
    try {
      final calorieDoc = await _firestore.collection('calorieLogs').doc(userId).get();
      
      if (!calorieDoc.exists) {
        debugPrint('⚠️ No calorie logs found');
        return;
      }

      final data = calorieDoc.data()!;
      final foods = data['foods'] as List<dynamic>? ?? [];
      
      if (foods.isEmpty) {
        return;
      }

      // Calculate total calories and unique days
      int totalCalories = 0;
      Set<String> uniqueDates = {};

      for (var foodData in foods) {
        try {
          final food = foodData as Map<String, dynamic>;
          final kcal = (food['kcal'] as num?)?.toInt() ?? 0;
          totalCalories += kcal;
          
          final timestamp = (food['timestamp'] as Timestamp?)?.toDate();
          if (timestamp != null) {
            final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
            uniqueDates.add(dateKey);
          }
        } catch (e) {
          debugPrint('Error parsing food entry: $e');
        }
      }

      _totalCaloriesLogged = totalCalories;
      _daysWithCalorieLog = uniqueDates.length;
      _averageDailyCalories = _daysWithCalorieLog > 0 
          ? (totalCalories / _daysWithCalorieLog).round()
          : 0;

      debugPrint('✅ Calorie stats: Total: $_totalCaloriesLogged, Days logged: $_daysWithCalorieLog, Avg daily: $_averageDailyCalories');
    } catch (e) {
      debugPrint('❌ Error fetching calorie stats: $e');
    }
  }

  double _parseWeight(dynamic weightStr) {
    String str = weightStr.toString().toLowerCase();
    double value = double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 70.0;
    if (str.contains('lb')) {
      value = value * 0.453592; // Convert lbs to kg
    }
    return value;
  }

  void _generateAchievements() {
    _achievements.clear();

    // Streak achievements
    if (_currentStreak >= 30) {
      _achievements.add({
        'emoji': '🏆',
        'title': 'Monthly Champion',
        'status': '30 Day Streak',
      });
    } else if (_currentStreak >= 7) {
      _achievements.add({
        'emoji': '🔥',
        'title': '7 Day Streak',
        'status': 'Keep it burning!',
      });
    }

    // Workout count achievements
    if (_totalWorkouts >= 100) {
      _achievements.add({
        'emoji': '💯',
        'title': 'Century Club',
        'status': '100+ Workouts',
      });
    } else if (_totalWorkouts >= 50) {
      _achievements.add({
        'emoji': '⭐',
        'title': 'Half Century',
        'status': '50+ Workouts',
      });
    } else if (_totalWorkouts >= 20) {
      _achievements.add({
        'emoji': '💪',
        'title': '20 Workouts',
        'status': 'Getting stronger!',
      });
    }

    // Weight loss achievements
    if (_weightLoss >= 10) {
      _achievements.add({
        'emoji': '🎯',
        'title': 'Double Digits',
        'status': '10kg+ Progress',
      });
    } else if (_weightLoss >= 5) {
      _achievements.add({
        'emoji': '🌟',
        'title': 'Halfway Hero',
        'status': '5kg+ Progress',
      });
    }

    // Consistency achievements
    if (_activeDays >= 20) {
      _achievements.add({
        'emoji': '📅',
        'title': 'Consistency King',
        'status': '20+ Active Days',
      });
    } else if (_activeDays >= 10) {
      _achievements.add({
        'emoji': '⚡',
        'title': 'Regular Routine',
        'status': '10+ Active Days',
      });
    }

    // Calorie tracking achievements
    if (_daysWithCalorieLog >= 30) {
      _achievements.add({
        'emoji': '🍎',
        'title': 'Nutrition Tracker',
        'status': '30+ Days Logged',
      });
    } else if (_daysWithCalorieLog >= 15) {
      _achievements.add({
        'emoji': '🥗',
        'title': 'Food Awareness',
        'status': '15+ Days Logged',
      });
    }

    debugPrint('✅ Generated ${_achievements.length} achievements');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentCyan,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.cardColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Statistics",
          style: TextStyle(
            color: theme.cardColor, 
            fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.cardColor),
            onPressed: _fetchStatistics,
            tooltip: 'Refresh Statistics',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accentBlue),
                  const SizedBox(height: 20),
                  Text(
                    'Loading your progress...',
                    style: TextStyle(
                      color: theme.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchStatistics,
              color: AppColors.accentBlue,
              backgroundColor: theme.secondaryBackground,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Main statistics
                  _buildStatCard(
                    theme,
                    "Current Streak",
                    "$_currentStreak Days",
                    Icons.trending_up,
                    AppColors.green,
                    "Keep it up!",
                  ),
                  _buildStatCard(
                    theme,
                    "Weight Progress",
                    "${_weightLoss.toStringAsFixed(1)} kg",
                    Icons.monitor_weight_outlined,
                    AppColors.accentPurple,
                    "${_progressPercentage.toStringAsFixed(0)}% to goal",
                  ),
                  _buildStatCard(
                    theme,
                    "Calorie Log Days",
                    "$_daysWithCalorieLog days",
                    Icons.restaurant,
                    AppColors.accentBlue,
                    "Avg: $_averageDailyCalories kcal/day",
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Achievements section
                  if (_achievements.isNotEmpty) _buildAchievementsCard(theme),
                  
                  const SizedBox(height: 16),
                  
                  // Additional insights
                  _buildInsightsCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    ThemeManager theme,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                "Achievements",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._achievements.map((achievement) => _buildAchievementItem(
                theme,
                achievement['emoji']!,
                achievement['title']!,
                achievement['status']!,
              )),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(ThemeManager theme, String emoji, String title, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: AppColors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                "Insights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            theme,
            "Best Streak",
            "$_longestStreak days",
            Icons.emoji_events,
          ),
          _buildInsightRow(
            theme,
            "Avg. Calories/Day",
            "$_averageDailyCalories kcal",
            Icons.restaurant,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    ThemeManager theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accentBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
}