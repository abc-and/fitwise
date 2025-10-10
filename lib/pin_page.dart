import 'constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'dashboard.dart'; // Assuming this file exists
import 'route_helper.dart'; // Assuming this file exists
import 'package:crypto/crypto.dart'; // REQUIRED for MPIN Hashing
import 'dart:convert'; // REQUIRED for MPIN Hashing

class PinPage extends StatefulWidget {
  // CORRECTED: No longer requires email or password as it relies on
  // the user already being authenticated by Firebase on the LoginPage.
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String pin = "";
  bool _isLoading = false;

  void _addDigit(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
      });
      
      // Automatically verify when 4 digits are entered
      if (pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_isLoading) return;

    final user = _auth.currentUser;
    if (user == null) {
      _showError('No active user session. Please log in.');
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(context, createRouteRight(const LoginPage()));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get the stored MPIN HASH from Firestore using the current user's UID
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showError('User data not found. Please contact support.');
        await _auth.signOut();
        if (mounted) {
           Navigator.pushReplacement(context, createRouteRight(const LoginPage()));
        }
        return;
      }

      final storedMpinHash = userDoc.data()?['mpin'];

      // 2. HASH the user's input PIN for secure comparison (FIX APPLIED HERE)
      String hashedPinInput = sha256.convert(utf8.encode(pin)).toString();

      // 3. Compare the HASHES
      if (storedMpinHash == hashedPinInput) {
        // Success! Navigate to Dashboard
        _showSuccess('PIN accepted!');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            createRouteRight(const HomeDashboard()),
          );
        }
      } else {
        // Wrong PIN
        _showError('Incorrect PIN. Please try again.');
        setState(() {
          pin = "";
        });
      }
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
      setState(() {
        pin = "";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  Future<void> _handleForgotPin() async {
    // Show dialog to confirm password reset
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'To reset your PIN, you\'ll need to use password login. '
          'You will be logged out and returned to the main login page.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Ensure the Firebase user is signed out before going to LoginPage
              await _auth.signOut(); 
              Navigator.pushReplacement(
                context,
                createRouteRight(const LoginPage()),
              );
            },
            child: const Text(
              'Go to Login',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Sign out when the user presses back from the PIN page
        await _auth.signOut();
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
               // Sign out when pressing the back button
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                createRouteRight(const LoginPage()),
              );
            },
          ),
        ),
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Enter your 4-digit PIN",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // PIN Circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    bool filled = index < pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColors.primary : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 50),

                // Keypad
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return const SizedBox.shrink();
                    } else if (index == 10) {
                      return _buildButton("0");
                    } else if (index == 11) {
                      return _buildButton("⌫", isDelete: true);
                    }
                    return _buildButton("${index + 1}");
                  },
                ),

                const SizedBox(height: 20),

                // Forgot PIN
                TextButton(
                  onPressed: _handleForgotPin,
                  child: const Text(
                    "Forgot PIN?",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black26,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, {bool isDelete = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: isDelete ? Colors.red : Colors.black,
        shadowColor: Colors.grey[200],
        elevation: 2,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
      ),
      onPressed: _isLoading ? null : () {
        if (isDelete) {
          _removeDigit();
        } else {
          _addDigit(text);
        }
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: isDelete ? 20 : 26,
          fontWeight: FontWeight.bold,
          color: isDelete ? Colors.red[400] : Colors.black,
        ),
      ),
    );
  }
}
