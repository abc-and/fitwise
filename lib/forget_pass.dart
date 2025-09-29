import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'login_page.dart';
import 'route_helper.dart'; // 👈 make sure this import exists

class ForgetPassPage extends StatefulWidget {
  const ForgetPassPage({super.key});

  @override
  State<ForgetPassPage> createState() => _ForgetPassPageState();
}

class _ForgetPassPageState extends State<ForgetPassPage> {
  final TextEditingController _emailController = TextEditingController();
  
  // State to manage loading indicator and prevent multiple submissions
  bool _isLoading = false;

  // Utility function to display messages
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF65A30D),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // --- Firebase Password Reset Function ---
  Future<void> _resetPassword() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email address.", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      // 2. Success message
      _showSnackBar(
        "Password reset link sent to $email. Check your inbox!",
        isError: false,
      );

      // 3. Optional: Navigate back to login after a delay
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            createRouteRight(const LoginPage()),
          );
        }
      });

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'Failed to send reset link: ${e.message}';
      }
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      _showSnackBar("An unexpected error occurred. Please try again.", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- End of Firebase Function ---

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF65A30D), // FitWise green
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Reset Password",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              createRouteRight(const LoginPage()), // 👈 slide back to LoginPage
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.lock_reset, size: 90, color: Color(0xFF65A30D)),
              const SizedBox(height: 20),
              const Text(
                "Forgot your password?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF65A30D),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter your registered email address and we’ll send you a link to reset your password.",
                style: TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Color(0xFF65A30D)),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF65A30D)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF65A30D), width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Reset Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF65A30D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Call the Firebase reset function
                onPressed: _isLoading ? null : _resetPassword,
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
                        "Send Reset Link",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
