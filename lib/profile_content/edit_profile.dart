import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme.dart';
import '../constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedCharacter = '🧑'; // Default character
  bool _loading = true;
  bool _saving = false;

  // Available character avatars
  final List<String> _characters = [
    '🧑', '👨', '👩', '🧔', '👱‍♂️', '👱‍♀️',
    '🧑‍🦱', '👨‍🦱', '👩‍🦱', '🧑‍🦰', '👨‍🦰', '👩‍🦰',
    '🧑‍🦳', '👨‍🦳', '👩‍🦳', '🧑‍🦲', '👨‍🦲', '👩‍🦲',
    '🤵', '👰', '🧙‍♂️', '🧙‍♀️', '🧝‍♂️', '🧝‍♀️',
    '🧛‍♂️', '🧛‍♀️', '🧚‍♂️', '🧚‍♀️', '👼', '🎅',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // Load email from auth
      _emailController.text = user.email ?? '';

      // Load username from users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          _nameController.text = userData['username'] ?? '';
          _selectedCharacter = userData['character'] ?? '🧑';
        }
      }

      // Load user info
      final infoDoc = await _firestore.collection('user_info').doc(user.uid).get();
      if (infoDoc.exists) {
        final data = infoDoc.data();
        if (data != null) {
          _phoneController.text = data['phone'] ?? '';
          _heightController.text = _parseNumber(data['height']);
          _weightController.text = _parseNumber(data['weight']);
          _selectedGender = data['sex'] ?? 'Male';
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _parseNumber(dynamic value) {
    if (value == null) return '';
    String str = value.toString();
    return str.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  void _showCharacterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final theme = Provider.of<ThemeManager>(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.secondaryText.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Choose Your Character",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _characters.length,
                    itemBuilder: (context, index) {
                      final character = _characters[index];
                      final isSelected = character == _selectedCharacter;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCharacter = character);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentBlue.withOpacity(0.2)
                                : theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentBlue
                                  : theme.borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              character,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update username and character in users collection
      await _firestore.collection('users').doc(user.uid).update({
        'username': _nameController.text.trim(),
        'character': _selectedCharacter,
      });

      // Update user info
      final Map<String, dynamic> updates = {
        'sex': _selectedGender,
      };

      if (_phoneController.text.isNotEmpty) {
        updates['phone'] = _phoneController.text.trim();
      }

      if (_heightController.text.isNotEmpty) {
        final height = double.tryParse(_heightController.text);
        if (height != null && height > 0) {
          updates['height'] = '${height.toStringAsFixed(1)} cm';
        }
      }

      if (_weightController.text.isNotEmpty) {
        final weight = double.tryParse(_weightController.text);
        if (weight != null && weight > 0) {
          updates['weight'] = '${weight.toStringAsFixed(1)} kg';
          updates['lastWeightUpdate'] = Timestamp.now();
        }
      }

      await _firestore.collection('user_info').doc(user.uid).update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.cardColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: theme.cardColor, 
            fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          if (_saving)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: theme.cardColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                "Save",
                style: TextStyle(
                  color: theme.cardColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.accentBlue,
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showCharacterPicker,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.cardColor,
                                    width: 4,
                                  ),
                                ),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.cardColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _selectedCharacter,
                                      style: const TextStyle(fontSize: 70),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.cardColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: theme.cardColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Change Character",
                          style: TextStyle(
                            color: theme.cardColor, 
                            fontSize: 14
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          theme,
                          "Full Name",
                          _nameController,
                          Icons.person_outline,
                        ),
                        _buildInputField(
                          theme,
                          "Email",
                          _emailController,
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          enabled: false,
                        ),
                        _buildInputField(
                          theme,
                          "Phone",
                          _phoneController,
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Gender",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderOption(theme, "Male", Icons.male),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderOption(theme, "Female", Icons.female),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                theme,
                                "Height (cm)",
                                _heightController,
                                Icons.height,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                theme,
                                "Weight (kg)",
                                _weightController,
                                Icons.monitor_weight_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField(
    ThemeManager theme,
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? theme.primaryText : theme.secondaryText,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.accentBlue),
              filled: true,
              fillColor: theme.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(ThemeManager theme, String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBlue.withOpacity(0.2)
              : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : theme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accentBlue : theme.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? AppColors.accentBlue : theme.secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}