import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingCheck {
  /// Checks if the current user has completed onboarding
  /// Returns true if onboarding is complete, false otherwise
  static Future<bool> isOnboardingComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        return false;
      }

      final doc = await FirebaseFirestore.instance
          .collection("user_info")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (data == null) {
        return false;
      }

      // Check if onboardingCompleted flag exists and is true
      if (data.containsKey("onboardingCompleted") && 
          data["onboardingCompleted"] == true) {
        return true;
      }

      // Alternative: Check if all required fields are present and not empty
      // This ensures backward compatibility if the flag doesn't exist
      final requiredFields = [
        "height",
        "weight",
        "age",
        "sex",
        "allergies",
        "otherConditions",
        "dietType",
        "dietaryRestrictions",
        "activityLevel",
        "targetGoal",
        "targetDuration",
      ];

      for (final field in requiredFields) {
        if (!data.containsKey(field) || 
            data[field] == null || 
            data[field].toString().isEmpty) {
          return false;
        }
      }

      // Check weight-specific fields based on goal
      if (data["targetGoal"] == "Weight Loss") {
        if (!data.containsKey("targetWeightLoss") ||
            data["targetWeightLoss"] == null ||
            data["targetWeightLoss"].toString().isEmpty) {
          return false;
        }
      } else if (data["targetGoal"] == "Weight Gain") {
        if (!data.containsKey("targetWeightGain") ||
            data["targetWeightGain"] == null ||
            data["targetWeightGain"].toString().isEmpty) {
          return false;
        }
      }

      // Check reproductive status for females
      if (data["sex"] == "Female") {
        if (!data.containsKey("reproductiveStatus") ||
            data["reproductiveStatus"] == null ||
            data["reproductiveStatus"].toString().isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print("Error checking onboarding status: $e");
      return false;
    }
  }

  /// Marks onboarding as incomplete (useful for testing or resetting)
  static Future<void> resetOnboarding() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("user_info")
          .doc(user.uid)
          .update({"onboardingCompleted": false});
    } catch (e) {
      print("Error resetting onboarding: $e");
    }
  }
}