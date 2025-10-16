import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme.dart';
import 'models/food_recommendation.dart';
import 'constants/app_colors.dart';
// Add this import for the history page
import 'cal_history.dart';

class FoodLogEntry {
  final String name;
  final int kcal;
  final DateTime timestamp;
  final IconData icon;
  final bool isRecommended;

  FoodLogEntry({
    required this.name,
    required this.kcal,
    required this.timestamp,
    required this.icon,
    this.isRecommended = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'kcal': kcal,
      'timestamp': Timestamp.fromDate(timestamp),
      'iconCodePoint': icon.codePoint,
      'isRecommended': isRecommended,
    };
  }

  // Create from Map (for array storage)
  factory FoodLogEntry.fromMap(Map<String, dynamic> data) {
    return FoodLogEntry(
      name: data['name'] ?? 'Unknown Food',
      kcal: (data['kcal'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      icon: IconData(data['iconCodePoint'] ?? Icons.restaurant.codePoint,
          fontFamily: 'MaterialIcons'),
      isRecommended: data['isRecommended'] ?? false,
    );
  }
}

// BMR Calculator Helper Class
class HealthCalculator {
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String sex,
    String? activityLevel,
    String? reproductiveStatus,
  }) {
    double bmr;
    
    // Base BMR calculation
    if (sex.toLowerCase() == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
      
      // Adjust for reproductive status (females only)
      if (reproductiveStatus != null) {
        switch (reproductiveStatus) {
          case 'Pregnant':
            bmr += 300;
            break;
          case 'Breastfeeding':
            bmr += 500;
            break;
          case 'On Period':
            bmr += 50;
            break;
        }
      }
    }
    
    // Apply activity multiplier
    if (activityLevel != null) {
      double multiplier = 1.2; // Default: Sedentary
      switch (activityLevel) {
        case 'Lightly Active':
          multiplier = 1.375;
          break;
        case 'Moderately Active':
          multiplier = 1.55;
          break;
        case 'Very Active':
          multiplier = 1.725;
          break;
        case 'Extra Active':
          multiplier = 1.9;
          break;
      }
      bmr *= multiplier;
    }
    
    return bmr;
  }
}

class CirclePatternPainter extends CustomPainter {
  final double progress;
  final bool isOverGoal;
  final ThemeManager theme;

  CirclePatternPainter({
    required this.progress, 
    required this.isOverGoal,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final color = isOverGoal ? AppColors.orange : AppColors.accentBlue;

    paint.color = color.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.7), 80, paint);
    
    paint.color = color.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.3), 50, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 70, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CalorieLogPage extends StatefulWidget {
  const CalorieLogPage({super.key});

  @override
  State<CalorieLogPage> createState() => _CalorieLogPageState();
}

class _CalorieLogPageState extends State<CalorieLogPage>
    with TickerProviderStateMixin {
  final List<FoodLogEntry> _loggedFoods = [];
  final DateTime _selectedDate = DateTime.now();
  late AnimationController _fabController;
  late AnimationController _headerController;

  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  DocumentReference get _calorieDoc =>
      _firestore.collection('calorieLogs').doc(_user?.uid);
  
  DocumentReference get _userInfoDoc =>
      _firestore.collection('user_info').doc(_user?.uid);

  int get totalCalories =>
      _loggedFoods.fold(0, (sum, entry) => sum + entry.kcal);

  // Daily goal will be fetched from BMR calculation
  int _dailyGoal = 2000;
  bool _loadingGoal = true;

  // User data for BMR calculation
  double _currentWeight = 70.0;
  double _heightCm = 170.0;
  int _age = 25;
  String _sex = 'Male';
  String? _activityLevel;
  String? _reproductiveStatus;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerController.forward();
    
    // Load user data and calculate BMR
    _loadUserDataAndCalculateBMR();
    // Load existing calorie data from Firestore
    _loadCalorieData();
  }

  // Load user data and calculate BMR for daily goal
  Future<void> _loadUserDataAndCalculateBMR() async {
    setState(() => _loadingGoal = true);
    
    try {
      final userInfoSnapshot = await _userInfoDoc.get();
      
      if (userInfoSnapshot.exists) {
        final data = userInfoSnapshot.data() as Map<String, dynamic>?;
        
        if (data != null) {
          // Parse user data
          _currentWeight = _parseWeight(data['weight']);
          _heightCm = _parseHeight(data['height']);
          _age = int.tryParse(data['age'].toString()) ?? 25;
          _sex = data['sex']?.toString() ?? 'Male';
          _activityLevel = data['activityLevel']?.toString() ?? 'Sedentary';
          _reproductiveStatus = data['reproductiveStatus']?.toString();
          
          // Calculate BMR
          final bmr = HealthCalculator.calculateBMR(
            weightKg: _currentWeight,
            heightCm: _heightCm,
            age: _age,
            sex: _sex,
            activityLevel: _activityLevel,
            reproductiveStatus: _reproductiveStatus,
          );
          
          setState(() {
            _dailyGoal = bmr.round();
            _loadingGoal = false;
          });
          
          debugPrint('BMR calculated: $bmr kcal/day');
        }
      } else {
        // Use default if no user info
        setState(() => _loadingGoal = false);
        debugPrint('No user info found, using default calorie goal');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _loadingGoal = false);
    }
  }

  // Parse weight from string (handles kg and lbs)
  double _parseWeight(dynamic weightStr) {
    String str = weightStr.toString().toLowerCase();
    double value = double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 70.0;
    
    if (str.contains('lb')) {
      value = value * 0.453592; // lbs to kg
    }
    return value;
  }
  
  // Parse height from string (handles cm and m)
  double _parseHeight(dynamic heightStr) {
    String str = heightStr.toString().toLowerCase();
    double value = double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 170.0;
    
    if (str.contains('m') && !str.contains('cm') && value < 3) {
      value = value * 100; // m to cm
    }
    return value;
  }

  // Load calorie data from Firestore
  void _loadCalorieData() {
    _calorieDoc.snapshots().listen((snapshot) {
      if (mounted && snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>? ?? {};
        final foods = data['foods'] as List<dynamic>? ?? [];
        
        setState(() {
          _loggedFoods.clear();
          _loggedFoods.addAll(
            foods.map((foodData) {
              try {
                return FoodLogEntry.fromMap(foodData as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing food data: $e');
                return FoodLogEntry(
                  name: 'Unknown Food',
                  kcal: 0,
                  timestamp: DateTime.now(),
                  icon: Icons.error,
                  isRecommended: false,
                );
              }
            }),
          );
        });
      } else if (mounted) {
        setState(() {
          _loggedFoods.clear();
        });
      }
    });
  }

  // Save food to Firestore
  Future<void> _saveFoodToFirestore(FoodLogEntry entry) async {
    try {
      final doc = await _calorieDoc.get();
      Map<String, dynamic> currentData = {};
      
      if (doc.exists) {
        final docData = doc.data();
        if (docData != null) {
          currentData = Map<String, dynamic>.from(docData as Map);
        }
      }
      
      final currentFoods = List<dynamic>.from(currentData['foods'] ?? []);
      
      await _calorieDoc.set({
        ...currentData,
        'foods': [...currentFoods, entry.toMap()],
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
      
      debugPrint('Food saved successfully: ${entry.name}');
    } catch (e) {
      debugPrint('Error saving food: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save food: $e'),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    }
  }

  // Remove food from Firestore
  Future<void> _removeFoodFromFirestore(int index) async {
    try {
      final doc = await _calorieDoc.get();
      if (doc.exists) {
        final docData = doc.data();
        if (docData != null) {
          final data = Map<String, dynamic>.from(docData as Map);
          final foods = List<dynamic>.from(data['foods'] ?? []);
          
          if (index < foods.length) {
            final newFoods = List<dynamic>.from(foods);
            newFoods.removeAt(index);
            await _calorieDoc.set({
              'foods': newFoods,
              'lastUpdated': Timestamp.now(),
            }, SetOptions(merge: true));
            
            debugPrint('Food removed successfully at index: $index');
          }
        }
      }
    } catch (e) {
      debugPrint('Error removing food: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove food: $e'),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _addFoodFromRecommendation(FoodRecommendation food) async {
    final entry = FoodLogEntry(
      name: food.name,
      kcal: food.kcal,
      timestamp: DateTime.now(),
      icon: food.icon,
      isRecommended: true,
    );
    
    await _saveFoodToFirestore(entry);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _addCustomFood(String name, int kcal) async {
    final entry = FoodLogEntry(
      name: name,
      kcal: kcal,
      timestamp: DateTime.now(),
      icon: Icons.restaurant,
      isRecommended: false,
    );
    
    await _saveFoodToFirestore(entry);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _removeFood(int index) async {
    await _removeFoodFromFirestore(index);
  }

  void _showAddFoodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddFoodBottomSheet(
        onAddRecommended: _addFoodFromRecommendation,
        onAddCustom: _addCustomFood,
      ),
    );
  }

 // Navigate to Calories History Page
void _navigateToCaloriesHistory() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CalorieHistoryPage(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCalorieHeader(theme),
                const SizedBox(height: 20),
                // Add Calories History Section here
                _buildCaloriesHistorySection(theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildFoodList(theme),
        ],
      ),
      floatingActionButton: _buildFAB(theme),
    );
  }

  // New method for Calories History Section
  Widget _buildCaloriesHistorySection(ThemeManager theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _navigateToCaloriesHistory,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accentPurple,
                        AppColors.accentBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calories History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View your past calorie intake and trends',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.tertiaryText,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeManager theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: theme.primaryBackground,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Calorie Log',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryText, 
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentBlue,
                AppColors.accentCyan,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryText.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryText.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieHeader(ThemeManager theme) {
    final progress = (totalCalories / _dailyGoal).clamp(0.0, 1.0);
    final isOverGoal = totalCalories > _dailyGoal;
    final remaining = _dailyGoal - totalCalories;

    return FadeTransition(
      opacity: _headerController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _headerController,
          curve: Curves.easeOut,
        )),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor,
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(
                    painter: CirclePatternPainter(
                      progress: progress,
                      isOverGoal: isOverGoal,
                      theme: theme,
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: theme.secondaryText, 
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('EEEE, MMM d').format(_selectedDate),
                                    style: TextStyle(
                                      color: theme.secondaryText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  TweenAnimationBuilder<int>(
                                    tween: IntTween(begin: 0, end: totalCalories),
                                    duration: const Duration(milliseconds: 800),
                                    builder: (context, value, child) {
                                      return Text(
                                        '$value',
                                        style: TextStyle(
                                          color: isOverGoal ? AppColors.orange : AppColors.accentBlue,
                                          fontSize: 56,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                          letterSpacing: -2,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'kcal',
                                        style: TextStyle(
                                          color: theme.tertiaryText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'consumed',
                                        style: TextStyle(
                                          color: theme.tertiaryText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: progress),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return SizedBox(
                              width: 90,
                              height: 90,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isOverGoal
                                            ? [
                                                AppColors.orange.withOpacity(0.1),
                                                AppColors.orange.withOpacity(0.1),
                                              ]
                                            : [
                                                theme.borderColor,
                                                theme.borderColor.withOpacity(0.7),
                                              ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isOverGoal ? AppColors.orange : AppColors.accentBlue,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOverGoal
                                            ? Icons.warning_amber_rounded
                                            : Icons.local_fire_department_rounded,
                                        color: isOverGoal ? AppColors.orange : AppColors.accentBlue,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${(value * 100).toInt()}%',
                                        style: TextStyle(
                                          color: isOverGoal ? AppColors.orange : AppColors.accentBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.track_changes,
                            label: _loadingGoal ? 'Loading...' : 'BMR Goal',
                            value: _loadingGoal ? '...' : '$_dailyGoal',
                            unit: 'kcal',
                            color: theme.tertiaryText,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: isOverGoal ? Icons.trending_up : Icons.restaurant_menu,
                            label: isOverGoal ? 'Over' : 'Remaining',
                            value: '${remaining.abs()}',
                            unit: 'kcal',
                            color: isOverGoal ? AppColors.orange : AppColors.accentBlue,
                            theme: theme,
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
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required ThemeManager theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.tertiaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: theme.tertiaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(ThemeManager theme) {
    if (_loggedFoods.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: theme.borderColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No food logged yet',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first meal',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.tertiaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildFoodCard(_loggedFoods[index], index, theme);
          },
          childCount: _loggedFoods.length,
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodLogEntry entry, int index, ThemeManager theme) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 300 + (index * 100)),
    curve: Curves.easeOutBack,
    builder: (context, value, child) {
      return Transform.scale(
        scale: value.clamp(0.0, 1.0),
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: child,
        ),
      );
    },
    child: Dismissible(
      key: Key(entry.timestamp.millisecondsSinceEpoch.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeFood(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: theme.primaryText,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: entry.isRecommended
                            ? [AppColors.accentCyan, AppColors.accentBlue]
                            : [AppColors.accentPurple, AppColors.accentBlue.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      entry.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryText,
                                ),
                              ),
                            ),
                            if (entry.isRecommended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Recommended',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentCyan,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // TIME DISPLAY REMOVED - This is where the time was previously shown
                        // const SizedBox(height: 4),
                        // Text(
                        //   DateFormat('h:mm a').format(entry.timestamp),
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: theme.secondaryText,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.kcal}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildFAB(ThemeManager theme) {
    return FloatingActionButton.extended(
      onPressed: _showAddFoodDialog,
      backgroundColor: AppColors.accentBlue,
      elevation: 8,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Add Food',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _AddFoodBottomSheet extends StatefulWidget {
  final Function(FoodRecommendation) onAddRecommended;
  final Function(String, int) onAddCustom;

  const _AddFoodBottomSheet({
    required this.onAddRecommended,
    required this.onAddCustom,
  });

  @override
  State<_AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<_AddFoodBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _calorieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.accentBlue,
            unselectedLabelColor: theme.tertiaryText,
            indicatorColor: AppColors.accentBlue,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.restaurant_menu),
                text: 'Recommended',
              ),
              Tab(
                icon: Icon(Icons.edit),
                text: 'Custom Entry',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendedTab(theme),
                _buildCustomTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedTab(ThemeManager theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: allFoods.length,
      itemBuilder: (context, index) {
        final food = allFoods[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => widget.onAddRecommended(food),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accentCyan, AppColors.accentPurple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        food.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            food.desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${food.kcal} kcal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTab(ThemeManager theme) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., Chicken Salad',
            hintStyle: TextStyle(color: theme.tertiaryText),
            filled: true,
            fillColor: theme.borderColor.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.restaurant, color: AppColors.accentPurple),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Calories (kcal)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _calorieController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g., 350',
            hintStyle: TextStyle(color: theme.tertiaryText),
            filled: true,
            fillColor: theme.borderColor.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.local_fire_department, color: AppColors.orange),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final calStr = _calorieController.text.trim();
              if (name.isNotEmpty && calStr.isNotEmpty) {
                final cal = int.tryParse(calStr);
                if (cal != null && cal > 0) {
                  widget.onAddCustom(name, cal);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Add Food',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}