import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';
import 'route_helper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data bag: everything stored as String
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

  // Controllers for numeric text input (stored as String)
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _targetWeightLossController = TextEditingController();
  final TextEditingController _targetWeightGainController = TextEditingController();

  // Dropdown selections
  String? _sex;
  String? _allergies;
  String? _otherConditions;
  String? _dietType;
  String? _dietaryRestrictions;
  String? _activityLevel;
  String? _reproductiveStatus;
  String? _targetGoal;
  String? _targetDuration;

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

  // ---------- Duration → Date helpers ----------
  DateTime _addMonths(DateTime date, int monthsToAdd) {
    final int newYear = date.year + ((date.month - 1 + monthsToAdd) ~/ 12);
    final int newMonth = ((date.month - 1 + monthsToAdd) % 12) + 1;
    final int day = date.day;
    final int lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    final int clampedDay = day > lastDayOfNewMonth ? lastDayOfNewMonth : day;
    return DateTime(newYear, newMonth, clampedDay);
  }

  String _formatMMDDYYYY(DateTime d) {
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${two(d.month)}/${two(d.day)}/${d.year}';
  }

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

    _userData["targetDate"] = _formatMMDDYYYY(target); // MM/DD/YYYY
  }

  // Ensure latest text controllers are synced before saving
  void _syncTextControllersToUserData() {
    _userData["height"] = _heightController.text.trim();
    _userData["weight"] = _weightController.text.trim();
    _userData["age"] = _ageController.text.trim();
    _userData["targetWeightLoss"] = _targetWeightLossController.text.trim();
    _userData["targetWeightGain"] = _targetWeightGainController.text.trim();
  }

  Future<void> _finishOnboarding() async {
    _syncTextControllersToUserData();

    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.email == null || user.email!.isEmpty) {
        // Handle case where user isn't logged in or email is missing
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Authentication error: User email is missing.")),
          );
        }
        return;
    }

    // 🌟 CORRECTED FIX: Create a new map with the email field explicitly added.
    final Map<String, dynamic> dataToSave = Map.from(_userData);
    dataToSave["email"] = user.email!; // Force the email to be saved

    // Save to user_info / {uid}
    await FirebaseFirestore.instance
        .collection("user_info")
        .doc(user.uid) // Document ID is the UID
        .set(
          dataToSave, // Use the new Map<String, dynamic>
          SetOptions(merge: true),
        );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      createRouteRight(const DashboardScreen()),
    );
  }

  // ---------- Dropdown option sets ----------
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
  final List<String> _activityOptions = const ["Low", "Moderate", "High"];
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


  List<Widget> _buildPages() {
    return [
      // STEP 1: Basic Info
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Basic Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            TextField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: "Height (cm or m)",
                hintText: "e.g., 170 cm or 1.70 m",
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _userData["height"] = val.trim(),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: "Weight (kg or lbs)",
                hintText: "e.g., 65 kg or 143 lbs",
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _userData["weight"] = val.trim(),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: "Age (years)"),
              keyboardType: TextInputType.number,
              onChanged: (val) => _userData["age"] = val.trim(),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _sex,
              items: _sexOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _sex = val);
                _userData["sex"] = val;
              },
              decoration: const InputDecoration(labelText: "Sex"),
            ),
          ],
        ),
      ),
       // STEP 2: Medical Info
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Medical Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _allergies,
              items: _allergyOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _allergies = val);
                _userData["allergies"] = val;
              },
              decoration: const InputDecoration(labelText: "Allergies"),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _otherConditions,
              items: _conditionOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _otherConditions = val);
                _userData["otherConditions"] = val;
              },
              decoration: const InputDecoration(labelText: "Other Conditions"),
            ),
          ],
        ),
      ),

      // STEP 3: Diet Info
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Diet Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _dietType,
              items: _dietTypeOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _dietType = val);
                _userData["dietType"] = val;
              },
              decoration: const InputDecoration(labelText: "Type of Diet"),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _dietaryRestrictions,
              items: _dietRestrictionOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _dietaryRestrictions = val);
                _userData["dietaryRestrictions"] = val;
              },
              decoration: const InputDecoration(labelText: "Dietary Restrictions"),
            ),
          ],
        ),
      ),

      // STEP 4: Lifestyle
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lifestyle", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _activityLevel,
              items: _activityOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _activityLevel = val);
                _userData["activityLevel"] = val;
              },
              decoration: const InputDecoration(labelText: "Activity Level"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _reproductiveStatus,
              items: _reproductiveOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _reproductiveStatus = val);
                _userData["reproductiveStatus"] = val;
              },
              decoration: const InputDecoration(labelText: "Reproductive Status"),
            ),
          ],
        ),
      ),

      // STEP 5: Goals (includes targetWeightLoss/Gain and Duration -> Date)
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Goals", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _targetGoal,
              items: _goalOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _targetGoal = val);
                _userData["targetGoal"] = val;
              },
              decoration: const InputDecoration(labelText: "Target Goal"),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _targetWeightLossController,
              decoration: const InputDecoration(
                labelText: "Target Weight Loss (kg or lbs)",
                hintText: "e.g., 5 kg or 10 lbs",
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _userData["targetWeightLoss"] = val.trim(),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _targetWeightGainController,
              decoration: const InputDecoration(
                labelText: "Target Weight Gain (kg or lbs)",
                hintText: "e.g., 3 kg or 6 lbs",
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => _userData["targetWeightGain"] = val.trim(),
            ),
            const SizedBox(height: 8),

            // Target Duration dropdown → computes targetDate (MM/DD/YYYY)
            DropdownButtonFormField<String>(
              value: _targetDuration,
              items: _durationOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() => _targetDuration = val);
                _userData["targetDuration"] = val;
                _updateTargetDateFromDuration(val);
              },
              decoration: const InputDecoration(labelText: "Target Duration"),
            ),
            const SizedBox(height: 12),

            // Read-only view of computed target date
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Computed Target Date (MM/DD/YYYY)",
                hintText: "Select a duration to compute date",
                suffixIcon: const Icon(Icons.event),
              ),
              controller: TextEditingController(
                text: _userData["targetDate"] ?? "",
              ),
            ),
          ],
        ),
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      appBar: AppBar(
        title: Text("Step ${_currentPage + 1} of ${pages.length}"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // disable swipe
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: pages,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Prev / Next / Finish
            Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text("Back"),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    child: Text(_currentPage < pages.length - 1 ? "Next" : "Finish"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}