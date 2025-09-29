import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dashboard.dart'; // Import the dashboard screen

// 3. Change main to async and ensure widgets are initialized
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 4. Initialize Firebase
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FitWiseApp());
}

// New AuthWrapper widget handles routing based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the authentication state changes stream
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a simple spinner while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If the snapshot has data, a user is logged in (User? is not null)
        if (snapshot.hasData && snapshot.data != null) {
          // Logged In: Go to the Dashboard
          return const DashboardScreen();
        } 
        
        // Logged Out: Go to the Login Page
        return const LoginPage();
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
          // Use default look for clean material design
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF65A30D), width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        // Define the overall color scheme
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(0xFF65A30D, {
            50: Color(0xFFEFF3E7),
            100: Color(0xFFD8E4C3),
            200: Color(0xFFC0D59D),
            300: Color(0xFFA8C678),
            400: Color(0xFF98BC5E),
            500: Color(0xFF65A30D), // Primary
            600: Color(0xFF5A930C),
            700: Color(0xFF4C800A),
            800: Color(0xFF3E6D08),
            900: Color(0xFF284C05),
          }),
        ).copyWith(secondary: const Color(0xFF65A30D)),
      ),
      // Use the AuthWrapper as the home widget
      home: const AuthWrapper(),
    );
  }
}
