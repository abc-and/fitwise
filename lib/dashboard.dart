import 'package:flutter/material.dart';

// --- Color Palette ---
// We'll use a slightly standardized primary color here based on previous files for consistency.
class AppColors {
  // Use a slightly darker green for better contrast in the tab bar
  static const Color primary = Color(0xFF65A30D); 
  static const Color mediumGray = Color(0xFF9F9F9F);
}

// --- Placeholder Screens ---

class SimplePlaceholder extends StatelessWidget {
  final String title;
  const SimplePlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// --- Dashboard Screen (Now using DefaultTabController) ---

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Define the list of screens/tabs
    final List<Widget> screens = [
      const SimplePlaceholder(title: 'Home Screen'),
      const SimplePlaceholder(title: 'Exercise Tracker'),
      const SimplePlaceholder(title: 'Calorie Log'),
      const SimplePlaceholder(title: 'Daily Streak'),
      const SimplePlaceholder(title: 'User Profile'),
    ];

    // 2. Wrap the structure in DefaultTabController
    // The length must match the number of tabs/screens
    return DefaultTabController(
      length: screens.length,
      child: Scaffold(
        // The body displays the currently selected screen from the list
        body: TabBarView(
          // Disable swipe-to-switch for cleaner UX
          physics: const NeverScrollableScrollPhysics(), 
          children: screens,
        ),
        
        // 3. Simple Bottom Navigation Bar
        bottomNavigationBar: TabBar(
          // Use indicator for a modern, clean look
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
    );
  }
}
