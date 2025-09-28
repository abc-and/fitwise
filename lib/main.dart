import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const FitWiseApp());
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
          border: OutlineInputBorder(),
        ),
      ),
      home: const LoginPage(), // app starts with login
    );
  }
}
