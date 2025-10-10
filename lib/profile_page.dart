import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onLogout;
  
  
  const ProfilePage({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Profile Picture
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.surface,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    children: [
                      // Profile Picture
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
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "User Name",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "user@fitwise.com",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem("28", "Workouts", Icons.fitness_center),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem("12", "Days Streak", Icons.local_fire_department),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem("2.5kg", "Lost", Icons.trending_down),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuCard(
                    icon: Icons.person_outline,
                    title: "Edit Profile",
                    subtitle: "Update your personal information",
                    color: AppColors.accentBlue,
                    onTap: () {
                      // TODO: Navigate to edit profile
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    subtitle: "Manage your notification preferences",
                    color: AppColors.orange,
                    onTap: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.bar_chart,
                    title: "Statistics",
                    subtitle: "View your fitness progress",
                    color: AppColors.primary,
                    onTap: () {
                      // TODO: Navigate to statistics
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    subtitle: "App preferences and configuration",
                    color: AppColors.darkGray,
                    onTap: () {
                      // TODO: Navigate to settings
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    color: AppColors.secondary,
                    onTap: () {
                      // TODO: Navigate to help
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.info_outline,
                    title: "About",
                    subtitle: "App version and information",
                    color: AppColors.mediumGray,
                    onTap: () {
                      // TODO: Show about dialog
                    },
                  ),

                  const SizedBox(height: 16),

                  // Logout Button
                  Container(
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
                        onTap: () {
                          _showLogoutDialog(context);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
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
                  ),

                  const SizedBox(height: 32),

                  // Version Info
                  Text(
                    "FitWise v1.0.0",
                    style: TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
                    color: color.withOpacity(0.15),
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
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.mediumGray,
                  size: 24,
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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
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
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout from FitWise?",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.mediumGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mediumGray,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                Navigator.of(context).pop();
                onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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