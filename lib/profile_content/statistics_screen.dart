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

  int _totalWorkouts = 0;
  int _caloriesBurned = 0;
  int _activeDays = 0;
  int _currentStreak = 0;
  double _weightLoss = 0.0;
  int _averageDuration = 0;
  bool _loading = true;

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

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // Fetch workouts for this month
      final workoutsQuery = await _firestore
          .collection('user_workouts')
          .doc(user.uid)
          .collection('workouts')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();

      _totalWorkouts = workoutsQuery.docs.length;

      // Calculate calories and duration
      int totalCalories = 0;
      int totalDuration = 0;
      Set<String> uniqueDays = {};

      for (var doc in workoutsQuery.docs) {
        final data = doc.data();
        
        // Add calories
        final calories = data['caloriesBurned'] ?? data['calories'] ?? 0;
        totalCalories += (calories is int ? calories : int.tryParse(calories.toString()) ?? 0);
        
        // Add duration
        final duration = data['duration'] ?? 0;
        totalDuration += (duration is int ? duration : int.tryParse(duration.toString()) ?? 0);
        
        // Count unique days
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
          uniqueDays.add(dateKey);
        }
      }

      _caloriesBurned = totalCalories;
      _activeDays = uniqueDays.length;
      _averageDuration = _totalWorkouts > 0 ? (totalDuration / _totalWorkouts).round() : 0;

      // Calculate streak
      _currentStreak = await _calculateStreak(user.uid);

      // Calculate weight loss
      final infoDoc = await _firestore.collection('user_info').doc(user.uid).get();
      if (infoDoc.exists) {
        final data = infoDoc.data();
        if (data != null) {
          final currentWeight = _parseWeight(data['weight']);
          final startWeight = data.containsKey('startWeight')
              ? double.tryParse(data['startWeight'].toString()) ?? currentWeight
              : currentWeight;
          _weightLoss = (startWeight - currentWeight).abs();
        }
      }

      // Generate achievements
      _generateAchievements();

    } catch (e) {
      debugPrint('Error fetching statistics: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double _parseWeight(dynamic weightStr) {
    String str = weightStr.toString().toLowerCase();
    double value = double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 70.0;
    if (str.contains('lb')) {
      value = value * 0.453592;
    }
    return value;
  }

  Future<int> _calculateStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 365; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final startOfDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final workoutsOnDay = await _firestore
            .collection('user_workouts')
            .doc(userId)
            .collection('workouts')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .limit(1)
            .get();

        if (workoutsOnDay.docs.isEmpty) {
          break;
        }
        streak++;
      }

      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  void _generateAchievements() {
    _achievements.clear();

    if (_currentStreak >= 7) {
      _achievements.add({
        'emoji': '🔥',
        'title': '7 Day Streak',
        'status': 'Completed',
      });
    }

    if (_totalWorkouts >= 20) {
      _achievements.add({
        'emoji': '💪',
        'title': '20 Workouts',
        'status': 'Completed',
      });
    }

    if (_totalWorkouts >= 5) {
      _achievements.add({
        'emoji': '⚡',
        'title': 'Early Bird',
        'status': '5 Morning Workouts',
      });
    }

    if (_currentStreak >= 30) {
      _achievements.add({
        'emoji': '🏆',
        'title': 'Monthly Champion',
        'status': 'Completed',
      });
    }

    if (_caloriesBurned >= 5000) {
      _achievements.add({
        'emoji': '🔥',
        'title': 'Calorie Crusher',
        'status': '5000+ Calories Burned',
      });
    }
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
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            )
          : RefreshIndicator(
              onRefresh: _fetchStatistics,
              color: AppColors.accentBlue,
              backgroundColor: theme.secondaryBackground,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatCard(
                    theme,
                    "Total Workouts",
                    _totalWorkouts.toString(),
                    Icons.fitness_center,
                    AppColors.accentBlue,
                    "This Month",
                  ),
                  _buildStatCard(
                    theme,
                    "Calories Burned",
                    _caloriesBurned.toStringAsFixed(0),
                    Icons.local_fire_department,
                    AppColors.orange,
                    "This Month",
                  ),
                  _buildStatCard(
                    theme,
                    "Active Days",
                    _activeDays.toString(),
                    Icons.calendar_today,
                    AppColors.accentCyan,
                    "This Month",
                  ),
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
                    "Total",
                  ),
                  _buildStatCard(
                    theme,
                    "Average Duration",
                    "$_averageDuration min",
                    Icons.timer,
                    AppColors.orange,
                    "Per Workout",
                  ),
                  const SizedBox(height: 16),
                  if (_achievements.isNotEmpty) _buildAchievementsCard(theme),
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
                "Recent Achievements",
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
}