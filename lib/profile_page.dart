import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../helpers/profile_connector.dart'; 

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  String _username = 'User Name';
  String _email = 'user@fitwise.com';
  String _character = '🧑'; // Default character
  int _totalWorkouts = 0;
  int _daysStreak = 0;
  double _weightLost = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _loading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // Fetch user email
      _email = user.email ?? 'user@fitwise.com';

      // Fetch username and character from users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          _username = userData['username'] ?? 'User Name';
          _character = userData['character'] ?? '🧑';
        }
      }

      // Fetch user info for statistics
      final infoDoc = await _firestore.collection('user_info').doc(user.uid).get();
      if (infoDoc.exists) {
        final data = infoDoc.data();
        if (data != null) {
          // Calculate weight lost
          final currentWeight = _parseWeight(data['weight']);
          final startWeight = data.containsKey('startWeight') 
              ? double.tryParse(data['startWeight'].toString()) ?? currentWeight
              : currentWeight;
          _weightLost = (startWeight - currentWeight).abs();
        }
      }

      // Fetch workout statistics
      final workoutsQuery = await _firestore
          .collection('user_workouts')
          .doc(user.uid)
          .collection('workouts')
          .get();
      _totalWorkouts = workoutsQuery.docs.length;

      // Calculate streak (simplified - count consecutive days with workouts)
      _daysStreak = await _calculateStreak(user.uid);

    } catch (e) {
      debugPrint('Error fetching profile data: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMenuItems(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentBlue,
            AppColors.accentCyan,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            children: [
              // Profile Picture with Character
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      _character,
                      style: const TextStyle(fontSize: 70),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _username,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    _totalWorkouts.toString(),
                    "Workouts",
                    Icons.fitness_center,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatItem(
                    _daysStreak.toString(),
                    "Days Streak",
                    Icons.local_fire_department,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatItem(
                    "${_weightLost.toStringAsFixed(1)}kg",
                    "Progress",
                    Icons.trending_down,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuCard(
            icon: Icons.person_outline,
            title: "Edit Profile",
            subtitle: "Update your personal information",
            color: AppColors.accentBlue,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              if (result == true) {
                _fetchUserProfile();
              }
            },
          ),
          _buildMenuCard(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Manage your notification preferences",
            color: AppColors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            icon: Icons.bar_chart,
            title: "Statistics",
            subtitle: "View your fitness progress",
            color: AppColors.accentCyan,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            icon: Icons.settings_outlined,
            title: "Settings",
            subtitle: "App preferences and configuration",
            color: AppColors.mediumGray,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "Get help and contact support",
            color: AppColors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            icon: Icons.info_outline,
            title: "About",
            subtitle: "App version and information",
            color: AppColors.accentPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildLogoutButton(),
          const SizedBox(height: 32),
          Text(
            "FitWise v1.0.0",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.red,
            AppColors.red.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Logout",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout from FitWise?",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}