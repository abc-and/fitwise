import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // ✅ Provider package
import 'firebase_options.dart';

// Screens
import 'login_page.dart';
import 'dashboard.dart';
import 'onboarding_page.dart';

// Providers
import 'providers/fitness_provider.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FitnessProvider()),
      ],
      child: const FitWiseApp(),
    ),
  );
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
        primaryColor: AppColors.primary,
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent1,
          onSecondary: Colors.white,
          error: AppColors.red,
          onError: Colors.white,
          background: AppColors.lightGray,
          onBackground: AppColors.charcoal,
          surface: Colors.white,
          onSurface: AppColors.charcoal,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

/// AuthWrapper handles login, onboarding, and dashboard navigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  /// Check if onboarding is complete for the logged-in user
  Future<bool> _isOnboardingComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection("user_info")
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;

      // Explicit onboardingCompleted flag
      if (data["onboardingCompleted"] == true) return true;

      // Required fields check
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
        if (!data.containsKey(field) || data[field].toString().isEmpty) {
          return false;
        }
      }

      // Weight goal specifics
      if (data["targetGoal"] == "Weight Loss" &&
          (data["targetWeightLoss"] == null ||
              data["targetWeightLoss"].toString().isEmpty)) {
        return false;
      }

      if (data["targetGoal"] == "Weight Gain" &&
          (data["targetWeightGain"] == null ||
              data["targetWeightGain"].toString().isEmpty)) {
        return false;
      }

      // Female reproductive status
      if (data["sex"] == "Female" &&
          (data["reproductiveStatus"] == null ||
              data["reproductiveStatus"].toString().isEmpty)) {
        return false;
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
        // 🔄 Checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // 🚪 Not logged in → LoginPage
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // ✅ Logged in → check onboarding
        return FutureBuilder<bool>(
          future: _isOnboardingComplete(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (onboardingSnapshot.data == false) {
              return const OnboardingPage();
            }

            return const HomeDashboard();
          },
        );
      },
    );
  }
}

/// Simple loading screen widget
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF65A30D)),
        ),
      ),
    );
  }
}
