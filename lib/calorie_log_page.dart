import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your existing files
import 'models/food_recommendation.dart';
import 'constants/app_colors.dart';

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
      'timestamp': Timestamp.fromDate(timestamp), // Convert to Firestore Timestamp
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

class CirclePatternPainter extends CustomPainter {
  final double progress;
  final bool isOverGoal;

  CirclePatternPainter({required this.progress, required this.isOverGoal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final color = isOverGoal ? AppColors.orange : AppColors.blue;

    // Draw decorative circles
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

  int get totalCalories =>
      _loggedFoods.fold(0, (sum, entry) => sum + entry.kcal);

  final int dailyGoal = 2000;

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
    
    // Load existing data from Firestore
    _loadCalorieData();
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
                print('Error parsing food data: $e');
                // Return a default entry if parsing fails
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
        // If document doesn't exist, clear the list
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
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving food: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save food: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            }, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      print('Error removing food: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove food: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    Navigator.pop(context);
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
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCalorieHeader(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildFoodList(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.blue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Calorie Log',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.blue,
                AppColors.secondary,
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
                    color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieHeader() {
    final progress = (totalCalories / dailyGoal).clamp(0.0, 1.0);
    final isOverGoal = totalCalories > dailyGoal;
    final remaining = dailyGoal - totalCalories;

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated background pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(
                    painter: CirclePatternPainter(
                      progress: progress,
                      isOverGoal: isOverGoal,
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Top stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main calorie display
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppColors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('EEEE, MMM d').format(_selectedDate),
                                    style: TextStyle(
                                      color: AppColors.darkGray,
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
                                          color: isOverGoal ? AppColors.orange : AppColors.blue,
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
                                          color: AppColors.mediumGray,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'consumed',
                                        style: TextStyle(
                                          color: AppColors.mediumGray,
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
                        
                        // Circular progress indicator
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
                                  // Background circle
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isOverGoal
                                            ? [
                                                AppColors.orange.withOpacity(0.1),
                                                AppColors.red.withOpacity(0.1),
                                              ]
                                            : [
                                                AppColors.blue.withOpacity(0.1),
                                                AppColors.lightBlue,
                                              ],
                                      ),
                                    ),
                                  ),
                                  // Progress circle
                                  SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isOverGoal ? AppColors.orange : AppColors.blue,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  // Center content
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOverGoal
                                            ? Icons.warning_amber_rounded
                                            : Icons.local_fire_department_rounded,
                                        color: isOverGoal ? AppColors.orange : AppColors.blue,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${(value * 100).toInt()}%',
                                        style: TextStyle(
                                          color: isOverGoal ? AppColors.orange : AppColors.blue,
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
                    
                    // Stats cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.track_changes,
                            label: 'Goal',
                            value: '$dailyGoal',
                            unit: 'kcal',
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: isOverGoal ? Icons.trending_up : Icons.restaurant_menu,
                            label: isOverGoal ? 'Over' : 'Remaining',
                            value: '${remaining.abs()}',
                            unit: 'kcal',
                            color: isOverGoal ? AppColors.orange : AppColors.blue,
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
              Text(
                label,
                style: TextStyle(
                  color: AppColors.mediumGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
                  color: AppColors.mediumGray,
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

  Widget _buildFoodList() {
    if (_loggedFoods.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: AppColors.lightGray,
              ),
              const SizedBox(height: 16),
              Text(
                'No food logged yet',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.mediumGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first meal',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.lightGray,
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
            return _buildFoodCard(_loggedFoods[index], index);
          },
          childCount: _loggedFoods.length,
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodLogEntry entry, int index) {
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
            color: AppColors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                              ? [AppColors.accent1, AppColors.primary]
                              : [AppColors.blue.withOpacity(0.7), AppColors.blue],
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.dark1,
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
                                    color: AppColors.accent1.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('h:mm a').format(entry.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.kcal}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mediumGray,
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

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddFoodDialog,
      backgroundColor: AppColors.primary,
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorColor: AppColors.primary,
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
                _buildRecommendedTab(),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: allFoods.length,
      itemBuilder: (context, index) {
        final food = allFoods[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGray.withOpacity(0.5)),
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
                          colors: [AppColors.accent1, AppColors.primary],
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            food.desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${food.kcal} kcal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Food Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g., Chicken Salad',
              filled: true,
              fillColor: AppColors.lightGray.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.restaurant, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Calories (kcal)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _calorieController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g., 350',
              filled: true,
              fillColor: AppColors.lightGray.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.local_fire_department,
                  color: AppColors.orange),
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
                backgroundColor: AppColors.primary,
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