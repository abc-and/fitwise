import 'package:flutter/material.dart';
import 'constants/app_colors.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGray,
      child: Center(
        child: Text(
          'This is the Exercise Tracker page!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
