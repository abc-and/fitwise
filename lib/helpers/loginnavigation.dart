import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your pages
import 'package:fitwise/onboarding_page.dart';
import 'package:fitwise/dashboard.dart';
import 'onboarding_check.dart';
import 'package:fitwise/route_helper.dart'; // Your existing route helper

/// Helper class for navigation after login/signup
class LoginNavigation {
  /// Navigate to the appropriate screen after successful login
  /// Checks onboarding status and routes accordingly
  static Future<void> navigateAfterLogin(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // This shouldn't happen, but handle it gracefully
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication error. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if onboarding is complete
    final isComplete = await OnboardingCheck.isOnboardingComplete();

    if (!context.mounted) return;

    if (isComplete) {
      // Onboarding complete, go to dashboard
      Navigator.pushReplacement(
        context,
        createRouteRight(const DashboardScreen()),
      );
    } else {
      // Onboarding not complete, go to onboarding page
      Navigator.pushReplacement(
        context,
        createRouteRight(const OnboardingPage()),
      );
    }
  }
}

/// Example usage in your login page:
/// 
/// ```dart
/// Future<void> _handleLogin() async {
///   try {
///     // Your login logic
///     await FirebaseAuth.instance.signInWithEmailAndPassword(
///       email: emailController.text,
///       password: passwordController.text,
///     );
///     
///     if (!mounted) return;
///     
///     // Navigate based on onboarding status
///     await LoginNavigation.navigateAfterLogin(context);
///     
///   } catch (e) {
///     if (!mounted) return;
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text("Login failed: ${e.toString()}")),
///     );
///   }
/// }
/// 
/// // For signup:
/// Future<void> _handleSignup() async {
///   try {
///     // Your signup logic
///     await FirebaseAuth.instance.createUserWithEmailAndPassword(
///       email: emailController.text,
///       password: passwordController.text,
///     );
///     
///     if (!mounted) return;
///     
///     // New users always go to onboarding
///     Navigator.pushReplacement(
///       context,
///       createRouteRight(const OnboardingPage()),
///     );
///     
///   } catch (e) {
///     if (!mounted) return;
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text("Signup failed: ${e.toString()}")),
///     );
///   }
/// }
/// ```