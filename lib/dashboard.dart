import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Note: We import LoginPage here to navigate back to it on logout
import 'login_page.dart'; 
import 'route_helper.dart';

// --- Color Palette ---
// These colors are defined here for dashboard elements and UI consistency
class AppColors {
  // Use a slightly darker green for better contrast in the tab bar and header
  static const Color primary = Color(0xFF65A30D); 
  static const Color mediumGray = Color(0xFF9F9F9F);
}

// --- Placeholder Screens ---

class SimplePlaceholder extends StatelessWidget {
  final String title;
  const SimplePlaceholder({super.key, required final this.title});

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

// --- Dashboard Screen (Main Application Container) ---

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Function to handle Firebase logout and navigate
  Future<void> _logout(BuildContext context) async {
    try {
      // 1. Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // 2. Navigate to Login Page and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          createRouteLeft(const LoginPage()),
          (Route<dynamic> route) => false,
        );
        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You have been logged out.'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 2),
            ),
        );
      }
    } catch (e) {
      // Show error if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
    return DefaultTabController(
      length: screens.length,
      child: Scaffold(
        // AppBar with the Logout button
        appBar: AppBar(
          title: const Text(
            'FitWise Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 4, // Add a slight shadow
          actions: [
            // Logout button in the top right
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ],
        ),
        
        // The body displays the currently selected screen from the list
        body: TabBarView(
          // Disable swipe-to-switch for cleaner UX
          physics: const NeverScrollableScrollPhysics(), 
          children: screens,
        ),
        
        // 3. Simple Bottom Navigation Bar
        bottomNavigationBar: TabBar(
          // Styling for the tab bar
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
