import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';
import 'forget_pass.dart';
import 'dashboard.dart';
import 'route_helper.dart'; // Assuming this provides the createRouteRight function
import 'onboarding_page.dart'; // Ensure this is correctly imported

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  
  bool _obscurePassword = true;
  // Initialize to true to show loading screen while checking session
  bool _isLoading = true; 
  bool _isForgotPasswordHovered = false;
  bool _isRegisterHovered = false;

  // NOTE: Hardcoded primary colors for consistency in this file
  static const Color _primaryColor = Color(0xFF65A30D); 
  static const Color _darkPrimaryColor = Color(0xFF527A0A);

  @override
  void initState() {
    super.initState();
    _checkForExistingSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check if a Firebase user is already signed in and navigate accordingly.
  Future<void> _checkForExistingSession() async {
    try {
      final user = _auth.currentUser;
      
      if (user != null) {
        final userEmail = user.email;
        
        if (userEmail == null || userEmail.isEmpty) {
            if (mounted) {
              setState(() => _isLoading = false);
              _showSnackBar('User email is missing, please sign out and sign in again.', isError: true);
            }
            return;
        }

        // Check if this user already has profile data in Firestore using email
        final querySnapshot = await _firestore
            .collection("user_info")
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();
        
        if (mounted) {
          if (querySnapshot.docs.isEmpty) {
            // New user (no profile doc) → go to onboarding wizard
            Navigator.pushReplacement(
              context,
              createRouteRight(const OnboardingPage()),
            );
          } else {
            // Existing user (has profile doc) → go to dashboard
            Navigator.pushReplacement(
              context,
              createRouteRight(const HomeDashboard()),
            );
          }
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
    // Only show snackbar if the widget is still in the tree
    if (!mounted) return; 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Login with email and password (with FIX)
  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.');
      return;
    }

    // Set loading state at the start
    setState(() => _isLoading = true);

    try {
      // 1. Sign in with Firebase (Authentication)
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 2. Query the 'user_info' collection
      final querySnapshot = await _firestore
          .collection("user_info")
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // 3. Conditional Navigation based on whether a profile was found
      if (mounted) {
        _showSnackBar('Login successful! Welcome to FitWise.', isError: false);
        
        if (querySnapshot.docs.isEmpty) {
          // No document found -> Onboarding
          Navigator.pushReplacement(
            context,
            createRouteRight(const OnboardingPage()),
          );
        } else {
          // Document found -> Dashboard
          Navigator.pushReplacement(
            context,
            createRouteRight(const HomeDashboard()),
          );
        }
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many failed login attempts. Try again later.';
      }

      // Show the specific error message to the user
      _showSnackBar(errorMessage);

      // **FIX: Reset loading state on error**
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
    } catch (e) {
      _showSnackBar('An unexpected error occurred: ${e.toString()}');

      // **FIX: Reset loading state on other errors**
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } 
  }

  @override
  Widget build(BuildContext context) {

    // Show a full-screen loading spinner while checking for an existing session
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
          ),
        ),
      );
    }

    // Main Login UI
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
                color: _primaryColor,
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
                          ? _darkPrimaryColor 
                          : _primaryColor,
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
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              // Disable the button if loading is true
              onPressed: _isLoading ? null : _loginWithPassword,
              child: _isLoading
                  // Show small loader inside button if _isLoading is true
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  // Show text if _isLoading is false
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
                            ? _darkPrimaryColor 
                            : _primaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}