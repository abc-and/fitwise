// about_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme.dart';
import '../constants/app_colors.dart';
import 'settings_screen.dart'; // Import to access LegalDocuments and LegalDocumentScreen

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showLegalDocument(BuildContext context, String title, String content, ThemeManager theme) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          content: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentPurple,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.cardColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About",
          style: TextStyle(
            color: theme.cardColor, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accentBlue, AppColors.accentCyan],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 60,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "FitWise",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.cardColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      fontSize: 16, 
                      color: theme.cardColor.withOpacity(0.7)
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "About FitWise",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "FitWise is your ultimate fitness companion, designed to help you achieve your health and wellness goals. Track your workouts, monitor your progress, and stay motivated with personalized insights and achievements.",
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.secondaryText,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    theme: theme,
                    icon: Icons.copyright,
                    title: "Copyright",
                    content: "© 2024 FitWise. All rights reserved.",
                  ),
                  _buildInfoCard(
                    theme: theme,
                    icon: Icons.developer_mode,
                    title: "Developed By",
                    content: "FitWise Development Team",
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Contact Us",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildContactButton(
                              context: context,
                              theme: theme,
                              icon: Icons.phone,
                              label: "Call",
                              contactInfo: "09473405892",
                            ),
                            _buildContactButton(
                              context: context,
                              theme: theme,
                              icon: Icons.mail,
                              label: "Email",
                              contactInfo: "glydel.solis13@gmail.com",
                            ),
                            _buildContactButton(
                              context: context,
                              theme: theme,
                              icon: Icons.facebook,
                              label: "Facebook",
                              contactInfo: "Glydel Solis",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Made with ❤️ for fitness enthusiasts",
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            "Legal Documents",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryText,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(
                                  "Privacy Policy",
                                  style: TextStyle(color: theme.primaryText),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showLegalDocument(
                                    context,
                                    "Privacy Policy",
                                    LegalDocuments.privacyPolicy,
                                    theme,
                                  );
                                },
                              ),
                              ListTile(
                                title: Text(
                                  "Terms of Service",
                                  style: TextStyle(color: theme.primaryText),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showLegalDocument(
                                    context,
                                    "Terms of Service",
                                    LegalDocuments.termsOfService,
                                    theme,
                                  );
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Close",
                                style: TextStyle(color: AppColors.accentBlue),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      "Privacy Policy  •  Terms of Service",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeManager theme,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accentBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required ThemeManager theme,
    required IconData icon,
    required String label,
    required String contactInfo,
  }) {
    return InkWell(
      onTap: () {
        _handleContactTap(context, label, contactInfo);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContactTap(BuildContext context, String type, String info) {
    switch (type) {
      case "Call":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call: $info'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case "Email":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email: $info'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case "Facebook":
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facebook: $info'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
    }
  }
}