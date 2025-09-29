import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dashboard.dart';
import 'onboarding_page.dart'; // Import the onboarding page

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FitWiseApp());
}

// AuthWrapper now handles both authentication AND onboarding status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  /// Check if the current user has completed onboarding
  Future<bool> _isOnboardingComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        return false;
      }

      final doc = await FirebaseFirestore.instance
          .collection("user_info")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (data == null) {
        return false;
      }

      // Check if onboardingCompleted flag exists and is true
      if (data.containsKey("onboardingCompleted") && 
          data["onboardingCompleted"] == true) {
        return true;
      }

      // Alternative: Check if all required fields are present
      final requiredFields = [
        "height",
        "weight",
        "age",
        "sex",
        "allergies",
        "otherConditions",
        "dietType",
        "dietaryRestrictions",
        "activityLevel",
        "targetGoal",
        "targetDuration",
      ];

      for (final field in requiredFields) {
        if (!data.containsKey(field) || 
            data[field] == null || 
            data[field].toString().isEmpty) {
          return false;
        }
      }

      // Check weight-specific fields based on goal
      if (data["targetGoal"] == "Weight Loss") {
        if (!data.containsKey("targetWeightLoss") ||
            data["targetWeightLoss"] == null ||
            data["targetWeightLoss"].toString().isEmpty) {
          return false;
        }
      } else if (data["targetGoal"] == "Weight Gain") {
        if (!data.containsKey("targetWeightGain") ||
            data["targetWeightGain"] == null ||
            data["targetWeightGain"].toString().isEmpty) {
          return false;
        }
      }

      // Check reproductive status for females
      if (data["sex"] == "Female") {
        if (!data.containsKey("reproductiveStatus") ||
            data["reproductiveStatus"] == null ||
            data["reproductiveStatus"].toString().isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error checking onboarding status: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65A30D)),
              ),
            ),
          );
        }

        // If user is not logged in, show login page
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // User is logged in, check onboarding status
        return FutureBuilder<bool>(
          future: _isOnboardingComplete(),
          builder: (context, onboardingSnapshot) {
            // Show loading while checking onboarding status
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65A30D)),
                  ),
                ),
              );
            }

            // If onboarding is not complete, show onboarding page
            if (onboardingSnapshot.data == false) {
              return const OnboardingPage();
            }

            // Onboarding is complete, show dashboard
            return const DashboardScreen();
          },
        );
      },
    );
  }
}

class FitWiseApp extends StatelessWidget {
  const FitWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitWise',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF65A30D),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF65A30D), width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(0xFF65A30D, {
            50: Color(0xFFEFF3E7),
            100: Color(0xFFD8E4C3),
            200: Color(0xFFC0D59D),
            300: Color(0xFFA8C678),
            400: Color(0xFF98BC5E),
            500: Color(0xFF65A30D),
            600: Color(0xFF5A930C),
            700: Color(0xFF4C800A),
            800: Color(0xFF3E6D08),
            900: Color(0xFF284C05),
          }),
        ).copyWith(secondary: const Color(0xFF65A30D)),
      ),
      home: const AuthWrapper(),
    );
  }
}