import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';
import 'forget_pass.dart';
// IMPORTANT: Now we only import DashboardScreen from dashboard.dart
import 'dashboard.dart'; 
import 'route_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Kept for consistency, though not strictly needed here
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  
  bool _obscurePassword = true;
  bool _isLoading = true;
  bool _isForgotPasswordHovered = false;
  bool _isRegisterHovered = false;

  @override
  void initState() {
    super.initState();
    _checkForExistingSession();
  }

  // Check if a Firebase user is already signed in and navigate to Dashboard.
  Future<void> _checkForExistingSession() async {
    try {
      final user = _auth.currentUser;
      
      if (user != null) {
        // User is logged in, redirect straight to the dashboard.
        if (mounted) {
             Navigator.pushReplacement(
                 context,
                 createRouteRight(const DashboardScreen()), 
             );
        }
        return;
      }
      
      // If no active session, show the login form
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // In case of any Firebase error during initial check
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error checking session: ${e.toString()}');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    // NOTE: Hardcoding the color here since AppColors is now in dashboard.dart
    const Color primaryColor = Color(0xFF65A30D); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Login with email and password
  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Sign in with Firebase
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 2. Navigate straight to dashboard upon successful login
      _showSnackBar('Login successful! Welcome to FitWise.', isError: false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          createRouteRight(const DashboardScreen()),
        );
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many failed login attempts. Try again later.';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: Hardcoding the primary color used in the Login UI since AppColors is moved.
    const Color primaryColor = Color(0xFF65A30D);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            
            // Logo/Title
            const Text(
              "FitWise",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Track your fitness journey",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 60),

            // Email input
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _loginWithPassword(),
            ),
            const SizedBox(height: 10),

            // Forgot Password link
            Align(
              alignment: Alignment.centerRight,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isForgotPasswordHovered = true),
                onExit: (_) => setState(() => _isForgotPasswordHovered = false),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      createRouteRight(const ForgetPassPage()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: _isForgotPasswordHovered 
                          ? const Color(0xFF527A0A) 
                          : primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: _isForgotPasswordHovered 
                          ? TextDecoration.underline 
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Continue button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              onPressed: _isLoading ? null : _loginWithPassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isRegisterHovered = true),
                  onExit: (_) => setState(() => _isRegisterHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        createRouteRight(const RegisterPage()),
                      );
                    },
                    child: Text(
                      "Register",
                      style: TextStyle(
                        color: _isRegisterHovered 
                            ? const Color(0xFF527A0A) 
                            : primaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
