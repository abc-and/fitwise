import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'login_page.dart';
import 'route_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill out all fields.');
      setState(() => _isLoading = false);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long.');
      setState(() => _isLoading = false);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(username);
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();

      _showSnackBar('Registration successful! Please log in.', isError: false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          createRouteRight(const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('An unknown error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // App Logo/Icon
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
                      "Start Your Fitness Journey",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),

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
                            'Create Account',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fill in your details to get started',
                            style: TextStyle(
                              color: AppColors.mediumGray,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Username Field
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(color: AppColors.textDark),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(color: AppColors.mediumGray),
                              prefixIcon: Icon(
                                Icons.person_outline,
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
                          const SizedBox(height: 16),

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
                          const SizedBox(height: 16),

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
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
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
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(color: AppColors.textDark),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(color: AppColors.mediumGray),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.accentBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.mediumGray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
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
                          const SizedBox(height: 28),

                          // Register Button
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
                              onPressed: _isLoading ? null : _register,
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
                                      'Create Account',
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

                    // Login Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              createRouteRight(const LoginPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Login",
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