import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';
import 'forget_pass.dart';
import 'dashboard.dart';
import 'route_helper.dart';
import 'onboarding_page.dart';
import 'constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscurePassword = true;
  bool _isLoading = true;
  bool _isLoggingIn = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _checkForExistingSession();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkForExistingSession() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot = await _firestore
            .collection("user_info")
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (!mounted) return;
        if (querySnapshot.docs.isEmpty) {
          Navigator.pushReplacement(
            context,
            createRouteRight(const OnboardingPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            createRouteRight(const HomeDashboard()),
          );
        }
      } else {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _animationController.forward();
      _showSnackBar('Error checking session: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password.');
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final querySnapshot = await _firestore
          .collection("user_info")
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (!mounted) return;
      _showSnackBar('Welcome to FITWISE!', isError: false);

      if (querySnapshot.docs.isEmpty) {
        Navigator.pushReplacement(
          context,
          createRouteRight(const OnboardingPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          createRouteRight(const HomeDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'Invalid email format.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        _ => 'Login failed. Please try again.',
      };

      _showSnackBar(errorMessage);
      if (mounted) setState(() => _isLoggingIn = false);
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e');
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.accentCyan,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon (optional - you can add an image here)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentCyan,
                            AppColors.accentBlue,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.accentCyan, AppColors.accentBlue],
                      ).createShader(bounds),
                      child: const Text(
                        "FitWise",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Smarter Goals. Safer Gain.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue your fitness journey',
                            style: TextStyle(
                              color: AppColors.mediumGray,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: AppColors.textDark),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: AppColors.mediumGray),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.accentBlue,
                              ),
                              filled: true,
                              fillColor: AppColors.cardLight,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.accentBlue,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.lightGray,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: AppColors.textDark),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: AppColors.mediumGray),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.accentBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.mediumGray,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: AppColors.cardLight,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.accentBlue,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.lightGray,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  createRouteRight(ForgetPasswordPage()),
                                );
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Continue Button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentCyan,
                                  AppColors.accentBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentBlue.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoggingIn ? null : _loginWithPassword,
                              child: _isLoggingIn
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
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Register Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              createRouteRight(const RegisterPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accentCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}