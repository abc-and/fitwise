import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Assuming these files exist in your project as per your imports
import 'dashboard.dart'; 
import 'route_helper.dart';
import 'constants/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Data Map for Firebase Storage
  final Map<String, String?> _userData = {
    "height": null,
    "weight": null,
    "age": null,
    "sex": null,
    "allergies": null,
    "otherConditions": null,
    "dietType": null,
    "dietaryRestrictions": null,
    "activityLevel": null,
    "reproductiveStatus": null,
    "targetGoal": null,
    "targetDate": null,
    "targetWeightLoss": null,
    "targetWeightGain": null,
    "targetDuration": null,
  };

  // Text Controllers for input fields
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _targetWeightLossController = TextEditingController();
  final TextEditingController _targetWeightGainController = TextEditingController();

  // State Variables for Dropdown Selections
  String? _sex;
  String? _allergies;
  String? _otherConditions;
  String? _dietType;
  String? _dietaryRestrictions;
  String? _activityLevel;
  String? _reproductiveStatus;
  String? _targetGoal;
  String? _targetDuration;

  // --- Constants for Dropdown Options ---
  final List<String> _sexOptions = const ["Male", "Female", "Other"];
  final List<String> _allergyOptions = const [
    "None", "Pollen", "Peanuts", "Seafood", "Dust", "Medication", "Others"
  ];
  final List<String> _conditionOptions = const [
    "None", "Diabetes", "Hypertension", "Asthma", "Heart Disease", "Thyroid Issues", "Others"
  ];
  final List<String> _dietTypeOptions = const [
    "Keto", "Vegan", "Vegetarian", "Low Carb", "Balanced", "High Protein", "Others"
  ];
  final List<String> _dietRestrictionOptions = const [
    "None", "Gluten-free", "Lactose-free", "Halal", "Low Sodium", "Others"
  ];
  final List<String> _activityOptions = const ["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extra Active"];
  
  // Activity level descriptions
  final Map<String, String> _activityDescriptions = const {
    "Sedentary": "Little or no exercise",
    "Lightly Active": "Light exercise/sports 1-3 days per week",
    "Moderately Active": "Moderate exercise/sports 3-5 days per week",
    "Very Active": "Hard exercise/sports 6-7 days a week",
    "Extra Active": "Very hard exercise/sports and a physical job",
  };
  
  final List<String> _reproductiveOptions = const [
    "Not Applicable",
    "On Period",
    "Pregnant",
    "Breastfeeding",
    "Menopausal",
    "Others",
  ];
  final List<String> _goalOptions = const [
    "Weight Loss",
    "Weight Gain",
    "Muscle Building",
    "Endurance & Stamina",
    "General Fitness",
    "Maintenance",
  ];
  final List<String> _durationOptions = const [
    "1 week",
    "2 weeks",
    "1 month",
    "3 months",
    "6 months",
    "1 year",
  ];
  // ----------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _targetWeightLossController.dispose();
    _targetWeightGainController.dispose();
    super.dispose();
  }

  // Load existing data from Firebase if available
  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("user_info")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            // Load text fields
            _heightController.text = data["height"] ?? "";
            _weightController.text = data["weight"] ?? "";
            _ageController.text = data["age"] ?? "";
            _targetWeightLossController.text = data["targetWeightLoss"] ?? "";
            _targetWeightGainController.text = data["targetWeightGain"] ?? "";

            // Load dropdowns
            _sex = data["sex"];
            _allergies = data["allergies"];
            _otherConditions = data["otherConditions"];
            _dietType = data["dietType"];
            _dietaryRestrictions = data["dietaryRestrictions"];
            _activityLevel = data["activityLevel"];
            _reproductiveStatus = data["reproductiveStatus"];
            _targetGoal = data["targetGoal"];
            _targetDuration = data["targetDuration"];

            // Load into userData map
            _userData.addAll({
              "height": data["height"],
              "weight": data["weight"],
              "age": data["age"],
              "sex": data["sex"],
              "allergies": data["allergies"],
              "otherConditions": data["otherConditions"],
              "dietType": data["dietType"],
              "dietaryRestrictions": data["dietaryRestrictions"],
              "activityLevel": data["activityLevel"],
              "reproductiveStatus": data["reproductiveStatus"],
              "targetGoal": data["targetGoal"],
              "targetDate": data["targetDate"],
              "targetWeightLoss": data["targetWeightLoss"],
              "targetWeightGain": data["targetWeightGain"],
              "targetDuration": data["targetDuration"],
            });
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading existing data: $e");
    }
  }

  // Helper function to correctly add months to a DateTime object
  DateTime _addMonths(DateTime date, int monthsToAdd) {
    final int newYear = date.year + ((date.month - 1 + monthsToAdd) ~/ 12);
    final int newMonth = ((date.month - 1 + monthsToAdd) % 12) + 1;
    final int day = date.day;
    final int lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    final int clampedDay = day > lastDayOfNewMonth ? lastDayOfNewMonth : day;
    return DateTime(newYear, newMonth, clampedDay);
  }

  // Helper function to format date as MM/DD/YYYY
  String _formatMMDDYYYY(DateTime d) {
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${two(d.month)}/${two(d.day)}/${d.year}';
  }

  // Logic to calculate target date based on selected duration
  void _updateTargetDateFromDuration(String? durationLabel) {
    if (durationLabel == null) return;
    final now = DateTime.now();
    DateTime target;

    switch (durationLabel) {
      case '1 week':
        target = now.add(const Duration(days: 7));
        break;
      case '2 weeks':
        target = now.add(const Duration(days: 14));
        break;
      case '1 month':
        target = _addMonths(now, 1);
        break;
      case '3 months':
        target = _addMonths(now, 3);
        break;
      case '6 months':
        target = _addMonths(now, 6);
        break;
      case '1 year':
        target = _addMonths(now, 12);
        break;
      default:
        target = now;
    }

    _userData["targetDate"] = _formatMMDDYYYY(target);
  }

  // Syncs all TextEditingController values into the _userData map
  void _syncTextControllersToUserData() {
    _userData["height"] = _heightController.text.trim();
    _userData["weight"] = _weightController.text.trim();
    _userData["age"] = _ageController.text.trim();
    _userData["targetWeightLoss"] = _targetWeightLossController.text.trim();
    _userData["targetWeightGain"] = _targetWeightGainController.text.trim();
  }

  // Validate all required fields
  String? _validateAllFields() {
    _syncTextControllersToUserData();

    // Step 1: Basic Info
    if (_userData["height"] == null || _userData["height"]!.isEmpty) {
      return "Please enter your height in Step 1";
    }
    if (_userData["weight"] == null || _userData["weight"]!.isEmpty) {
      return "Please enter your weight in Step 1";
    }
    if (_userData["age"] == null || _userData["age"]!.isEmpty) {
      return "Please enter your age in Step 1";
    }
    if (_userData["sex"] == null || _userData["sex"]!.isEmpty) {
      return "Please select your sex in Step 1";
    }

    // Step 2: Medical Info
    if (_userData["allergies"] == null || _userData["allergies"]!.isEmpty) {
      return "Please select your allergies status in Step 2";
    }
    if (_userData["otherConditions"] == null || _userData["otherConditions"]!.isEmpty) {
      return "Please select your medical conditions in Step 2";
    }

    // Step 3: Diet Info
    if (_userData["dietType"] == null || _userData["dietType"]!.isEmpty) {
      return "Please select your diet type in Step 3";
    }
    if (_userData["dietaryRestrictions"] == null || _userData["dietaryRestrictions"]!.isEmpty) {
      return "Please select your dietary restrictions in Step 3";
    }

    // Step 4: Lifestyle
    if (_userData["activityLevel"] == null || _userData["activityLevel"]!.isEmpty) {
      return "Please select your activity level in Step 4";
    }
    // Reproductive status is only required for females
    if (_userData["sex"] == "Female") {
      if (_userData["reproductiveStatus"] == null || _userData["reproductiveStatus"]!.isEmpty) {
        return "Please select your reproductive status in Step 4";
      }
    }

    // Step 5: Goals
    if (_userData["targetGoal"] == null || _userData["targetGoal"]!.isEmpty) {
      return "Please select your target goal in Step 5";
    }
    
    // Check weight-specific fields based on goal
    if (_userData["targetGoal"] == "Weight Loss") {
      if (_userData["targetWeightLoss"] == null || _userData["targetWeightLoss"]!.isEmpty) {
        return "Please enter your target weight loss in Step 5";
      }
    } else if (_userData["targetGoal"] == "Weight Gain") {
      if (_userData["targetWeightGain"] == null || _userData["targetWeightGain"]!.isEmpty) {
        return "Please enter your target weight gain in Step 5";
      }
    }
    
    if (_userData["targetDuration"] == null || _userData["targetDuration"]!.isEmpty) {
      return "Please select your target duration in Step 5";
    }

    return null; // All validations passed
  }

  // Final step: Saves data to Firebase and navigates to Dashboard
  Future<void> _finishOnboarding() async {
    // Validate all fields first
    final validationError = _validateAllFields();
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null || user.email!.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Authentication error: User email is missing."),
            backgroundColor: AppColors.red,
          ),
        );
      }
      return;
    }

    // Combine current user data with the onboarding data
    final Map<String, dynamic> dataToSave = Map.from(_userData);
    dataToSave["email"] = user.email!;
    dataToSave["onboardingCompleted"] = true; // Add completion flag
    dataToSave["onboardingCompletedAt"] = FieldValue.serverTimestamp();

    try {
      await FirebaseFirestore.instance
          .collection("user_info")
          .doc(user.uid)
          .set(dataToSave, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // Navigate to the Dashboard screen
      Navigator.pushReplacement(
        context,
        createRouteRight(const DashboardScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving data: ${e.toString()}"),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Widget to build the header for each step
  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build a standardized text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: AppColors.dark1,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.mediumGray.withOpacity(0.6),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  // Widget to build a standardized dropdown field
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toString(),
                    style: TextStyle(
                      color: AppColors.dark1,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.tertiary, size: 24)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        icon: Icon(Icons.arrow_drop_down, color: AppColors.tertiary, size: 28),
      ),
    );
  }

  // Builds all the individual pages/steps of the onboarding
  List<Widget> _buildPages() {
    return [
      // STEP 1: Basic Info
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                "Basic Info",
                "Tell us about yourself",
                Icons.person_outline,
              ),
              const SizedBox(height: 28),
              _buildTextField(
                controller: _heightController,
                label: "Height (cm or m)",
                hint: "e.g., 170 cm or 1.70 m",
                onChanged: (val) => _userData["height"] = val.trim(),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: _weightController,
                label: "Weight (kg or lbs)",
                hint: "e.g., 65 kg or 143 lbs",
                onChanged: (val) => _userData["weight"] = val.trim(),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: _ageController,
                label: "Age (years)",
                hint: "Enter your age",
                onChanged: (val) => _userData["age"] = val.trim(),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              _buildDropdown<String>(
                label: "Sex",
                value: _sex,
                items: _sexOptions,
                icon: Icons.wc,
                onChanged: (val) {
                  setState(() {
                    _sex = val;
                    // Reset reproductive status if not female
                    if (val != "Female") {
                      _reproductiveStatus = null;
                      _userData["reproductiveStatus"] = null;
                    }
                  });
                  _userData["sex"] = val;
                },
              ),
            ],
          ),
        ),
      ),

      // STEP 2: Medical Info
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                "Medical Info",
                "Help us understand your health",
                Icons.medical_services_outlined,
              ),
              const SizedBox(height: 28),
              _buildDropdown<String>(
                label: "Allergies",
                value: _allergies,
                items: _allergyOptions,
                icon: Icons.warning_amber_rounded,
                onChanged: (val) {
                  setState(() => _allergies = val);
                  _userData["allergies"] = val;
                },
              ),
              const SizedBox(height: 18),
              _buildDropdown<String>(
                label: "Other Conditions",
                value: _otherConditions,
                items: _conditionOptions,
                icon: Icons.health_and_safety_outlined,
                onChanged: (val) {
                  setState(() => _otherConditions = val);
                  _userData["otherConditions"] = val;
                },
              ),
            ],
          ),
        ),
      ),

      // STEP 3: Diet Info
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                "Diet Info",
                "Your dietary preferences",
                Icons.restaurant_menu,
              ),
              const SizedBox(height: 28),
              _buildDropdown<String>(
                label: "Type of Diet",
                value: _dietType,
                items: _dietTypeOptions,
                icon: Icons.food_bank_outlined,
                onChanged: (val) {
                  setState(() => _dietType = val);
                  _userData["dietType"] = val;
                },
              ),
              const SizedBox(height: 18),
              _buildDropdown<String>(
                label: "Dietary Restrictions",
                value: _dietaryRestrictions,
                items: _dietRestrictionOptions,
                icon: Icons.no_meals_outlined,
                onChanged: (val) {
                  setState(() => _dietaryRestrictions = val);
                  _userData["dietaryRestrictions"] = val;
                },
              ),
            ],
          ),
        ),
      ),

      // STEP 4: Lifestyle
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                "Lifestyle",
                "Your daily activity",
                Icons.directions_run,
              ),
              const SizedBox(height: 28),
              _buildDropdown<String>(
                label: "Activity Level",
                value: _activityLevel,
                items: _activityOptions,
                icon: Icons.fitness_center,
                onChanged: (val) {
                  setState(() => _activityLevel = val);
                  _userData["activityLevel"] = val;
                },
              ),
              const SizedBox(height: 14),
              // Activity level description
              if (_activityLevel != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent1.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.tertiary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _activityDescriptions[_activityLevel] ?? "",
                          style: TextStyle(
                            color: AppColors.dark1,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              // Conditional: Only show reproductive status for females
              if (_sex == "Female") ...[
                _buildDropdown<String>(
                  label: "Reproductive Status",
                  value: _reproductiveStatus,
                  items: _reproductiveOptions,
                  icon: Icons.pregnant_woman,
                  onChanged: (val) {
                    setState(() => _reproductiveStatus = val);
                    _userData["reproductiveStatus"] = val;
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.lightBlue.withOpacity(0.5),
                        AppColors.lightBlue.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.blue.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppColors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Reproductive status is only applicable for female users.",
                          style: TextStyle(
                            color: AppColors.dark1,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // STEP 5: Goals
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader(
                "Goals",
                "What do you want to achieve?",
                Icons.flag_outlined,
              ),
              const SizedBox(height: 28),
              _buildDropdown<String>(
                label: "Target Goal",
                value: _targetGoal,
                items: _goalOptions,
                icon: Icons.track_changes,
                onChanged: (val) {
                  setState(() {
                    _targetGoal = val;
                    // Clear opposite weight field
                    if (val == "Weight Loss") {
                      _targetWeightGainController.clear();
                      _userData["targetWeightGain"] = null;
                    } else if (val == "Weight Gain") {
                      _targetWeightLossController.clear();
                      _userData["targetWeightLoss"] = null;
                    }
                  });
                  _userData["targetGoal"] = val;
                },
              ),
              const SizedBox(height: 18),

              // Conditional: Show weight loss field only if goal is Weight Loss
              if (_targetGoal == "Weight Loss") ...[
                _buildTextField(
                  controller: _targetWeightLossController,
                  label: "Target Weight Loss (kg or lbs)",
                  hint: "e.g., 5 kg or 10 lbs",
                  onChanged: (val) => _userData["targetWeightLoss"] = val.trim(),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
              ],

              // Conditional: Show weight gain field only if goal is Weight Gain
              if (_targetGoal == "Weight Gain") ...[
                _buildTextField(
                  controller: _targetWeightGainController,
                  label: "Target Weight Gain (kg or lbs)",
                  hint: "e.g., 3 kg or 6 lbs",
                  onChanged: (val) => _userData["targetWeightGain"] = val.trim(),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
              ],

              _buildDropdown<String>(
                label: "Target Duration",
                value: _targetDuration,
                items: _durationOptions,
                icon: Icons.calendar_today,
                onChanged: (val) {
                  setState(() => _targetDuration = val);
                  _userData["targetDuration"] = val;
                  _updateTargetDateFromDuration(val);
                },
              ),
              const SizedBox(height: 18),

              // Read-only field for the computed target date
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent1.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.tertiary.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: TextFormField(
                  readOnly: true,
                  style: TextStyle(
                    color: AppColors.dark1,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: "Target Date (MM/DD/YYYY)",
                    labelStyle: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: "Select a duration to compute date",
                    hintStyle: TextStyle(
                      color: AppColors.mediumGray.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(Icons.event, color: AppColors.tertiary, size: 24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  controller: TextEditingController(
                    text: _userData["targetDate"] ?? "",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: AppColors.lightGray.withOpacity(0.3),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          "Step ${_currentPage + 1} of ${pages.length}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: PageView(
              controller: _pageController,
              // Prevent user from swiping pages manually
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: pages,
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Saving your information...",
                        style: TextStyle(
                          color: AppColors.dark1,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page Indicators (Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _currentPage == index ? 28 : 12,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: _currentPage == index
                          ? LinearGradient(
                              colors: [AppColors.primary, AppColors.tertiary],
                            )
                          : null,
                      color: _currentPage != index ? AppColors.lightGray : null,
                      boxShadow: _currentPage == index
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Navigation Buttons
              Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Back",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          if (_currentPage < pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Last page, so finish onboarding
                            _finishOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentPage < pages.length - 1 ? "Next" : "Finish",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}