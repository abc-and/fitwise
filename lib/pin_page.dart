import 'package:flutter/material.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  String pin = "";

  void _addDigit(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
      });
    }
  }

  void _removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
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
                  color: filled ? const Color(0xFF65A30D) : Colors.grey[300],
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
            onPressed: () {
              // TODO: Handle forgot PIN
            },
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
      onPressed: () {
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
