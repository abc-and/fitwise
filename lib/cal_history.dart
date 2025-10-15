import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme.dart';
import 'constants/app_colors.dart';

class CalorieHistoryPage extends StatefulWidget {
  const CalorieHistoryPage({Key? key}) : super(key: key);

  @override
  State<CalorieHistoryPage> createState() => _CalorieHistoryPageState();
}

class _CalorieHistoryPageState extends State<CalorieHistoryPage> {
  // For demo purposes - in a real app, you'd get this from a provider or database
  final List<FoodLogEntry> _demoFoods = [
    FoodLogEntry(
      name: 'Oatmeal with Fruits',
      kcal: 350,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)), // Different times
      icon: Icons.breakfast_dining,
      isRecommended: true,
    ),
    FoodLogEntry(
      name: 'Chicken Salad',
      kcal: 420,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 7)),
      icon: Icons.lunch_dining,
    ),
    FoodLogEntry(
      name: 'Protein Shake',
      kcal: 180,
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      icon: Icons.local_cafe,
      isRecommended: true,
    ),
    FoodLogEntry(
      name: 'Grilled Salmon',
      kcal: 520,
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      icon: Icons.dinner_dining,
    ),
    FoodLogEntry(
      name: 'Greek Yogurt',
      kcal: 150,
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 3)),
      icon: Icons.icecream,
    ),
  ];

  Map<String, List<FoodLogEntry>> get _groupedFoods {
    final Map<String, List<FoodLogEntry>> grouped = {};
    
    for (final food in _demoFoods) {
      final dateKey = DateFormat('yyyy-MM-dd').format(food.timestamp);
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(food);
    }
    
    // Sort dates in descending order (newest first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    final sortedGrouped = <String, List<FoodLogEntry>>{};
    for (final key in sortedKeys) {
      // Sort foods by timestamp within each day (most recent first)
      grouped[key]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      sortedGrouped[key] = grouped[key]!;
    }
    
    return sortedGrouped;
  }

  int _getTotalCaloriesForDate(List<FoodLogEntry> foods) {
    return foods.fold(0, (sum, entry) => sum + entry.kcal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: theme.primaryBackground,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Calorie History',
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
                      AppColors.accentPurple,
                      AppColors.accentBlue,
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
          ),
          _buildHistoryContent(theme),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(ThemeManager theme) {
    if (_groupedFoods.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 80,
                color: theme.borderColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No calorie history yet',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start logging your meals to see history here',
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
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final dateKey = _groupedFoods.keys.elementAt(index);
            final foods = _groupedFoods[dateKey]!;
            final totalCalories = _getTotalCaloriesForDate(foods);
            final date = DateTime.parse(dateKey);
            final isToday = DateFormat('yyyy-MM-dd').format(date) == 
                           DateFormat('yyyy-MM-dd').format(DateTime.now());
            
            return _buildDateSection(
              date: date,
              foods: foods,
              totalCalories: totalCalories,
              isToday: isToday,
              theme: theme,
            );
          },
          childCount: _groupedFoods.length,
        ),
      ),
    );
  }

  Widget _buildDateSection({
    required DateTime date,
    required List<FoodLogEntry> foods,
    required int totalCalories,
    required bool isToday,
    required ThemeManager theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.accentBlue.withOpacity(0.1),
                  AppColors.accentPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, MMMM d').format(date),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy').format(date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.accentBlue : AppColors.accentPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$totalCalories',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'kcal',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Daily total summary
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.borderColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 16,
                              color: theme.secondaryText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${foods.length} food${foods.length == 1 ? '' : 's'} logged • $totalCalories total kcal',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Food Items
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: foods.asMap().entries.map((entry) {
                final index = entry.key;
                final food = entry.value;
                return _buildHistoryFoodItem(food, index, theme);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryFoodItem(FoodLogEntry food, int index, ThemeManager theme) {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.borderColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: food.isRecommended
                          ? [AppColors.accentCyan, AppColors.accentBlue]
                          : [AppColors.accentPurple, AppColors.accentBlue.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    food.icon,
                    color: Colors.white,
                    size: 24,
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
                              food.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryText,
                              ),
                            ),
                          ),
                          if (food.isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentCyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentCyan,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // ADDED TIME DISPLAY HERE
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('h:mm a').format(food.timestamp),
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${food.kcal}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 11,
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
    );
  }
}

// FoodLogEntry class (same as in calorie_log_page.dart)
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
}