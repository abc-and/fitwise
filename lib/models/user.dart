class User {
  String? id;
  String? name;
  String? email;
  double? height;
  double? weight;
  int? age;
  String? sex;
  List<String>? allergies;
  List<String>? otherConditions;
  String? dietType;
  List<String>? dietaryRestrictions;
  String? activityLevel;
  String? reproductiveStatus;
  String? targetGoal;
  DateTime? targetDate;
  double? targetWeightLoss;
  double? targetWeightGain;

  User({
    this.id,
    this.name,
    this.email,
    this.height,
    this.weight,
    this.age,
    this.sex,
    this.allergies,
    this.otherConditions,
    this.dietType,
    this.dietaryRestrictions,
    this.activityLevel,
    this.reproductiveStatus,
    this.targetGoal,
    this.targetDate,
    this.targetWeightLoss,
    this.targetWeightGain,
  });
}