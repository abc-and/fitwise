// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _units = "Metric";
  String _language = "English";
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

      final doc = await _firestore
          .collection('user_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _units = data['units'] ?? "Metric";
            _language = data['language'] ?? "English";
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_settings').doc(user.uid).set({
        'units': _units,
        'language': _language,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
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
                _buildSectionHeader("Units & Language", Icons.language, themeManager),
                _buildOptionTile(
                  "Units",
                  _units,
                  Icons.straighten,
                  () => _showUnitsDialog(themeManager),
                  themeManager,
                ),
                _buildOptionTile(
                  "Language",
                  _language,
                  Icons.translate,
                  () => _showLanguageDialog(themeManager),
                  themeManager,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("Privacy & Security", Icons.security, themeManager),
                _buildActionTile("Change Password", Icons.lock_outline, () {
                  _showChangePasswordDialog(themeManager);
                }, themeManager),
                _buildActionTile("Privacy Policy", Icons.policy_outlined, () {}, themeManager),
                _buildActionTile("Terms of Service", Icons.description_outlined, () {}, themeManager),
                const SizedBox(height: 24),
                _buildSectionHeader("Data", Icons.storage, themeManager),
                _buildActionTile("Clear Cache", Icons.cleaning_services_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cache cleared successfully!"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }, themeManager),
                _buildActionTile("Export Data", Icons.download_outlined, () {}, themeManager),
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

  Widget _buildOptionTile(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
    ThemeManager theme,
  ) {
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
            color: AppColors.accentBlue.withOpacity(0.2),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.secondaryText),
          ],
        ),
        onTap: onTap,
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
            color: theme.secondaryText.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.secondaryText, size: 20),
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

  void _showUnitsDialog(ThemeManager theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Select Units",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(
                "Metric (kg, cm)",
                style: TextStyle(color: theme.primaryText),
              ),
              value: "Metric",
              groupValue: _units,
              onChanged: (val) {
                setState(() => _units = val!);
                _saveSettings();
                Navigator.pop(context);
              },
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<String>(
              title: Text(
                "Imperial (lb, in)",
                style: TextStyle(color: theme.primaryText),
              ),
              value: "Imperial",
              groupValue: _units,
              onChanged: (val) {
                setState(() => _units = val!);
                _saveSettings();
                Navigator.pop(context);
              },
              activeColor: AppColors.accentBlue,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(ThemeManager theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Select Language",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryText,
          ),
        ),
        content: Column( // ✅ FIXED: Added "content:" here
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text("English", style: TextStyle(color: theme.primaryText)),
              value: "English",
              groupValue: _language,
              onChanged: (val) {
                setState(() => _language = val!);
                _saveSettings();
                Navigator.pop(context);
              },
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<String>(
              title: Text("Filipino", style: TextStyle(color: theme.primaryText)),
              value: "Filipino",
              groupValue: _language,
              onChanged: (val) {
                setState(() => _language = val!);
                _saveSettings();
                Navigator.pop(context);
              },
              activeColor: AppColors.accentBlue,
            ),
            RadioListTile<String>(
              title: Text("Spanish", style: TextStyle(color: theme.primaryText)),
              value: "Spanish",
              groupValue: _language,
              onChanged: (val) {
                setState(() => _language = val!);
                _saveSettings();
                Navigator.pop(context);
              },
              activeColor: AppColors.accentBlue,
            ),
          ],
        ),
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
                  const SnackBar(
                    content: Text("Passwords don't match"),
                    backgroundColor: AppColors.error,
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
                      const SnackBar(
                        content: Text("Password changed successfully!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }
}