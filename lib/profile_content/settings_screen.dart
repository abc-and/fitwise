// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Privacy Policy and Terms of Service Content
class LegalDocuments {
  static const String privacyPolicy = '''
# Privacy Policy

**Last Updated: January 2025**

## Welcome to Fitwise

Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our fitness tracking application.

## Information We Collect

### Personal Information
- **Account Details**: Username, email address, and password (encrypted)
- **Profile Information**: Age, gender, height, weight, fitness goals
- **Health Data**: Workout history, exercise duration, calories burned, BMI, BMR
- **Progress Tracking**: Weight history, streak information, achievements

### Automatically Collected Information
- **Device Information**: Device type, operating system, app version
- **Usage Data**: App features used, workout completion rates, session duration
- **Analytics**: Aggregated data for improving app performance

## How We Use Your Information

We use your information to:
- **Personalize Experience**: Tailor workout recommendations and meal suggestions
- **Track Progress**: Monitor your fitness journey and achievements
- **Send Notifications**: Motivational quotes, streak reminders, achievement alerts
- **Improve Services**: Enhance app features and user experience
- **Ensure Security**: Protect your account and prevent unauthorized access

## Data Storage and Security

### Firebase Integration
Your data is securely stored using Google Firebase:
- **Authentication**: Industry-standard encryption for passwords
- **Cloud Firestore**: Secure database with access controls
- **Backup**: Automatic data backup to prevent loss

### Security Measures
- End-to-end encryption for sensitive data
- Secure HTTPS connections
- Regular security audits
- Two-factor authentication support

## Data Sharing and Disclosure

We **DO NOT**:
- Sell your personal information to third parties
- Share your health data with advertisers
- Use your information for purposes other than stated

We **MAY** share data:
- With your explicit consent
- To comply with legal obligations
- To protect our rights and safety
- With service providers (under strict confidentiality)

## Your Rights and Choices

You have the right to:
- **Access**: View all your stored data
- **Update**: Modify your profile information anytime
- **Delete**: Request complete account deletion
- **Export**: Download your workout history and statistics
- **Opt-out**: Disable notifications and analytics

## Data Retention

- **Active Accounts**: Data retained while account is active
- **Deleted Accounts**: Data permanently deleted within 30 days
- **Backup Copies**: Removed from backups within 90 days

## Children's Privacy

Fitwise is not intended for users under 13 years old. We do not knowingly collect information from children.

## International Users

If you're using our app outside the Philippines, your data may be transferred to and processed in countries where our servers are located.

## Changes to Privacy Policy

We may update this policy periodically. Significant changes will be notified through:
- In-app notifications
- Email alerts
- App update notes

## Contact Us

For privacy concerns or questions:
- **Email**: support@fitwise.com
- **In-App**: Settings > Help & Support
- **Response Time**: Within 48 hours

## Your Consent

By using Fitwise, you consent to this Privacy Policy and agree to its terms.

---

**Fitwise Team**  
Committed to your privacy and fitness journey.
''';

  static const String termsOfService = '''
# Terms of Service

**Effective Date: January 2025**

## Agreement to Terms

Welcome to Fitwise! By accessing or using our fitness application, you agree to be bound by these Terms of Service. Please read carefully.

## Acceptance of Terms

By creating an account or using Fitwise, you acknowledge that you have read, understood, and agree to these terms and our Privacy Policy.

## Eligibility

To use Fitwise, you must:
- Be at least 13 years old
- Provide accurate registration information
- Maintain the security of your account
- Comply with all applicable laws

## User Account

### Account Creation
- You are responsible for maintaining account confidentiality
- You must provide accurate, current information
- One account per person
- You must notify us of any unauthorized access

### Account Termination
We reserve the right to suspend or terminate accounts that:
- Violate these terms
- Engage in fraudulent activity
- Misuse the app or harm other users
- Remain inactive for over 2 years

## Acceptable Use

### You MAY:
- Use the app for personal fitness tracking
- Share your achievements on social media
- Provide feedback and suggestions
- Export your personal data

### You MAY NOT:
- Share your account credentials
- Reverse engineer or modify the app
- Upload malicious code or viruses
- Harass or harm other users
- Use the app for commercial purposes without permission
- Attempt to access restricted areas
- Create false accounts or impersonate others

## Health and Fitness Disclaimer

### Medical Advice Disclaimer
- Fitwise is **NOT** a substitute for professional medical advice
- Consult healthcare providers before starting any fitness program
- We are not responsible for health outcomes from app use
- Exercise recommendations are general guidelines

### User Responsibility
You acknowledge that:
- You will exercise at your own risk
- You will modify exercises if you have health conditions
- You will stop exercising if you experience pain or discomfort
- You understand your physical limitations

### Health Warnings
The app provides warnings for:
- Extreme weight goals (BMI < 16 or > 35)
- Rapid weight changes (> 20%)
- Pregnancy-related exercise restrictions
- Medical condition-based limitations

**Always prioritize your health and safety.**

## Content and Intellectual Property

### Our Content
All app content, including:
- Exercise videos and demonstrations
- Meal recommendations and nutrition data
- UI/UX design and graphics
- Algorithms and code

...is owned by Fitwise and protected by intellectual property laws.

### User-Generated Content
By using the app, you grant us:
- Right to store your workout data
- Right to use aggregated (anonymized) data for improvements
- Right to display your achievements within the app

We do **NOT** own your personal data and you can delete it anytime.

## Food and Nutrition Information

### Disclaimer
- Calorie counts are estimates based on general data
- Meal recommendations are suggestions, not prescriptions
- We are not responsible for allergic reactions
- Always check ingredient labels and consult nutritionists
- Dietary restrictions should be discussed with healthcare providers

### User Responsibility
You must:
- Verify food safety for your specific needs
- Inform us of allergies during onboarding
- Use common sense with recommendations
- Seek professional advice for medical diets

## Workout and Exercise Videos

### Usage Rights
- Videos are for personal, non-commercial use only
- Do not redistribute or republish exercise content
- Proper form guidelines are recommendations
- Modify exercises based on your fitness level

### Injury Disclaimer
We are **NOT LIABLE** for:
- Injuries sustained during workouts
- Equipment-related accidents
- Improper exercise form
- Overexertion or health complications

**Exercise at your own risk and know your limits.**

## Notifications and Communications

By using Fitwise, you consent to receive:
- Motivational quotes and reminders
- Streak warnings and achievement alerts
- App update notifications
- Important account information

You can disable notifications in Settings > Notifications.

## Data and Privacy

### Your Data Rights
- You own your personal fitness data
- You can export data in standard formats
- You can request account deletion anytime
- Deletion is permanent and irreversible

### Our Data Use
We use your data to:
- Provide personalized recommendations
- Calculate BMI, BMR, and progress metrics
- Generate achievement badges
- Improve app algorithms

See our Privacy Policy for complete details.

## Payment and Subscriptions

### Current Status
Fitwise is currently **FREE** to use.

### Future Premium Features
If we introduce paid features:
- Clear pricing will be displayed
- Free features will remain free
- No automatic charges without consent
- Refund policy will be clearly stated

## Service Availability

### Uptime
We strive for 99.9% uptime but cannot guarantee:
- Uninterrupted service
- Error-free operation
- Compatibility with all devices

### Maintenance
Scheduled maintenance will be announced in advance when possible.

### Changes to Service
We reserve the right to:
- Modify features and functionality
- Add or remove content
- Change app structure
- Discontinue the service (with 90 days notice)

## Limitation of Liability

**TO THE MAXIMUM EXTENT PERMITTED BY LAW:**

Fitwise and its developers are **NOT LIABLE** for:
- Indirect, incidental, or consequential damages
- Loss of data or profits
- Health complications from app use
- Third-party actions or content
- Service interruptions or errors

**Maximum liability is limited to the amount paid (currently ₱0 for free users).**

## Indemnification

You agree to defend, indemnify, and hold harmless Fitwise from any claims, damages, or expenses arising from:
- Your violation of these terms
- Your misuse of the app
- Your violation of others' rights
- Your negligence or misconduct

## Dispute Resolution

### Governing Law
These terms are governed by the laws of the Philippines.

### Resolution Process
1. **Contact Us First**: Email support@fitwise.com
2. **Good Faith Negotiation**: 30-day resolution attempt
3. **Mediation**: If negotiation fails
4. **Arbitration**: Binding arbitration in Manila, Philippines

### Class Action Waiver
You agree to resolve disputes individually, not as class actions.

## Third-Party Services

### Integrations
Fitwise uses:
- **Firebase**: Authentication and database (Google)
- **Cloud Storage**: For app data and backups

By using our app, you also agree to these services' terms.

### External Links
We may link to third-party websites. We are not responsible for their content or privacy practices.

## Children's Terms

If you are between 13-17 years old:
- You must have parental consent to use Fitwise
- Parents/guardians are responsible for your app use
- Parental supervision is recommended for workouts

## Modifications to Terms

We may update these Terms of Service at any time. Changes will be effective:
- Immediately for minor changes
- 30 days after notice for major changes

Continued use after changes constitutes acceptance.

## Termination Rights

### Your Rights
You may terminate your account at any time through:
- Settings > Account > Delete Account
- Email request to support@fitwise.com

### Our Rights
We may terminate accounts that violate these terms with or without notice.

### Effect of Termination
Upon termination:
- Your data will be deleted per Privacy Policy
- You lose access to all features
- Outstanding obligations survive termination

## Severability

If any provision of these terms is found invalid, the remaining provisions remain in full effect.

## Entire Agreement

These Terms of Service and our Privacy Policy constitute the entire agreement between you and Fitwise.

## Contact Information

For questions about these terms:

**Fitwise Support**
- **Email**: support@fitwise.com
- **In-App Support**: Settings > Help & Support
- **Response Time**: Within 48 hours
- **Business Hours**: Monday-Friday, 9 AM - 6 PM PHT

## Acknowledgment

By clicking "I Agree" or using Fitwise, you acknowledge:
- You have read these Terms of Service
- You understand your rights and obligations
- You agree to be bound by these terms
- You are legally able to enter this agreement

---

**Thank you for choosing Fitwise!**

We're committed to supporting your fitness journey while protecting your rights and privacy.

**Stay Strong. Stay Healthy. Stay Motivated.**

*Fitwise Team*  
*Your Partner in Fitness*
''';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showLegalDocument(String title, String content, ThemeManager theme) {
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
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: themeManager.primaryBackground,
      appBar: AppBar(
        backgroundColor: themeManager.isDarkMode ? AppColors.mediumGray : AppColors.accentBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader("Appearance", Icons.palette, themeManager),
                _buildSwitchTile(
                  "Dark Mode",
                  "Switch to ${themeManager.isDarkMode ? 'light' : 'dark'} theme",
                  themeManager.isDarkMode,
                  (val) {
                    themeManager.toggleTheme(val);
                  },
                  themeManager,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("Privacy & Security", Icons.security, themeManager),
                _buildActionTile("Change Password", Icons.lock_outline, () {
                  _showChangePasswordDialog(themeManager);
                }, themeManager),
                _buildActionTile("Privacy Policy", Icons.policy_outlined, () {
                  _showLegalDocument("Privacy Policy", LegalDocuments.privacyPolicy, themeManager);
                }, themeManager),
                _buildActionTile("Terms of Service", Icons.description_outlined, () {
                  _showLegalDocument("Terms of Service", LegalDocuments.termsOfService, themeManager);
                }, themeManager),
                const SizedBox(height: 24),
                _buildSectionHeader("Data", Icons.storage, themeManager),
                _buildActionTile("Clear Cache", Icons.cleaning_services_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Cache cleared successfully!"),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }, themeManager),
                const SizedBox(height: 24),
                _buildSectionHeader("About", Icons.info_outline, themeManager),
                _buildInfoTile("App Version", "1.0.0", themeManager),
                _buildInfoTile("Developer", "Fitwise Team", themeManager),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeManager theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    ThemeManager theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.cardShadow],
      ),
      child: SwitchListTile(
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
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accentBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap, ThemeManager theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.cardShadow],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentBlue, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.secondaryText),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, ThemeManager theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [theme.cardShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(ThemeManager theme) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Change Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: TextStyle(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: "Current Password",
                labelStyle: TextStyle(color: theme.secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: TextStyle(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: "New Password",
                labelStyle: TextStyle(color: theme.secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: TextStyle(color: theme.primaryText),
              decoration: InputDecoration(
                labelText: "Confirm Password",
                labelStyle: TextStyle(color: theme.secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: theme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Passwords don't match"),
                    backgroundColor: AppColors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              try {
                final user = _auth.currentUser;
                if (user != null && user.email != null) {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Password changed successfully!"),
                        backgroundColor: AppColors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: ${e.toString().contains('wrong-password') ? 'Wrong password' : 'Failed to change password'}"),
                      backgroundColor: AppColors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }
}

// Legal Document Viewer Screen
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.isDarkMode ? AppColors.mediumGray : AppColors.accentBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Share feature coming soon!"),
                  backgroundColor: AppColors.accentBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryBackground,
              theme.secondaryBackground,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentBlue, AppColors.accentCyan],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      title.contains("Privacy") ? Icons.privacy_tip : Icons.gavel,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Last updated: January 2025",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: content,
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBlue,
                        height: 1.5,
                      ),
                      h2: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText,
                        height: 1.4,
                      ),
                      h3: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                        height: 1.3,
                      ),
                      p: TextStyle(
                        fontSize: 14,
                        color: theme.primaryText,
                        height: 1.6,
                      ),
                      listBullet: TextStyle(
                        fontSize: 14,
                        color: AppColors.accentBlue,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBlue,
                      ),
                      em: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: theme.secondaryText,
                      ),
                      blockquote: TextStyle(
                        fontSize: 14,
                        color: theme.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.accentBlue,
                            width: 4,
                          ),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.all(12),
                      code: TextStyle(
                        fontSize: 13,
                        color: AppColors.accentCyan,
                        backgroundColor: theme.borderColor.withOpacity(0.2),
                      ),
                      horizontalRuleDecoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.borderColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Footer with accept button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            title.contains("Privacy") ? "I Understand" : "I Agree",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
}