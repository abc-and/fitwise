// help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme.dart';
import '../constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.cardColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Help & Support",
          style: TextStyle(
            color: theme.cardColor, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentBlue, AppColors.accentCyan],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent, color: theme.cardColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  "How can we help you?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.cardColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We're here to assist you with any questions",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.cardColor.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Contact Us",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            theme: theme,
            icon: Icons.email_outlined,
            title: "Email Support",
            subtitle: "glydel.solis13@gmail.com",
            color: AppColors.accentBlue,
            onTap: () {},
          ),
          _buildContactCard(
            theme: theme,
            icon: Icons.phone_outlined,
            title: "Phone Support",
            subtitle: "09473405892",
            color: AppColors.green,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            "Frequently Asked Questions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          _buildFAQCard(
            theme: theme,
            question: "How do I track my workouts?",
            answer: "Navigate to the Workout section and tap 'Start Workout' to begin tracking your exercise session.",
          ),
          _buildFAQCard(
            theme: theme,
            question: "Can I customize my workout plan?",
            answer: "Yes! Go to the Plans section where you can create and customize your own workout routines according to your preferences.",
          ),
          _buildFAQCard(
            theme: theme,
            question: "How do I see my progress?",
            answer: "Visit your Home Dashboard to view your BMI and BMR statistics displayed in an easy-to-read line graph that tracks your fitness journey over time.",
          ),
          _buildFAQCard(
            theme: theme,
            question: "How do I log my foods?",
            answer: "In the Calorie Log tab, press the 'Add Food' button to select from recommended foods or create your own custom food entries to track your nutrition.",
          ),
          _buildFAQCard(
            theme: theme,
            question: "What if I forget my password?",
            answer: "Use the 'Forgot Password' option on the login screen to reset your password securely via email.",
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required ThemeManager theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: theme.secondaryText,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFAQCard({
    required ThemeManager theme,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        iconColor: AppColors.accentBlue,
        collapsedIconColor: theme.secondaryText,
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}