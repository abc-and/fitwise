import 'package:flutter/material.dart';
import 'pin_page.dart';
import 'register_page.dart';
import 'forget_pass.dart';
import 'route_helper.dart'; // <-- add this import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const Text(
            'FitWise',
             style: TextStyle(
              fontSize: 46,                         // slightly bigger
               fontWeight: FontWeight.w900,          // extra bold
              color: Color(0xFF65A30D),
             letterSpacing: 1.5,                   // spacing for emphasis
               ),
              ),
            const SizedBox(height: 10),
            const Text(
            'Smarter Goals. Safer Gain.',
            style: TextStyle(
              fontSize: 18,                         // a little larger
              fontStyle: FontStyle.italic,          // italic for slogan
              color: Colors.black87,
              letterSpacing: 0.5,
          ),
            textAlign: TextAlign.center,
           ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      createRoute(const ForgetPassPage()),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF65A30D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // TODO: Handle login
                },
                child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 30),
              const Divider(thickness: 1),
              const SizedBox(height: 20),
              // Login with PIN
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    createRoute(const PinPage()),
                  );
                },
                child: const Text(
                  'Login with 4-digit PIN',
                  style: TextStyle(
                    color: Color(0xFF65A30D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Register link
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    createRoute(const RegisterPage()),
                  );
                },
                child: const Text(
                  'No account? Register',
                  style: TextStyle(
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
