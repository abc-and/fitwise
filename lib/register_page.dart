import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Not needed since we removed digits-only input
import 'login_page.dart';
import 'route_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart'; // Still needed for the type reference, even if not directly navigated to

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // MPIN controllers removed

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF65A30D),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Registration Function
  Future<void> _register() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Username, email, and passwords must be filled out.');
      setState(() => _isLoading = false);
      return;
    }

    // Password validation
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long.');
      setState(() => _isLoading = false);
      return;
    }

    // Confirm password match
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Create the user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update the display name
      await userCredential.user?.updateDisplayName(username);

      // 3. Store user data in Firestore (WITHOUT MPIN)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Sign out the newly created user
      await _auth.signOut();
      
      // 5. Show success message and navigate back to Login Page
      _showSnackBar('Registration successful! Please log in with your new credentials.', isError: false);
      
      if (mounted) {
          // Navigate back to the Login Page (replacing the current registration screen)
          Navigator.pushReplacement(
              context,
              createRouteRight(const LoginPage()),
          );
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('An unknown error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          createRouteRight(const LoginPage()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Create an account',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                createRouteRight(const LoginPage()),
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "FitWise",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF65A30D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join us and achieve smarter goals!",
                style: TextStyle(color: Colors.black54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder( // Visible border applied
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder( // Visible border applied
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password
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
                  border: OutlineInputBorder( // Visible border applied
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder( // Visible border applied
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Register button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: const Color(0xFF65A30D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
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
                        'Register',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),

              // Already have an account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          createRouteRight(const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF65A30D),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
