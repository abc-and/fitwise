// dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'route_helper.dart';
import 'constants/app_colors.dart'; 

Route createRouteLeft(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

// --- Main Dashboard Implementation ---

/// Top-level HomeDashboard widget (contains tabs and Home content)
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  // Major Part: Logout functionality
  Future<void> _logout(BuildContext context) async {
    try {
      // NOTE: FirebaseAuth and FirebaseFirestore require proper setup in main.dart
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          createRouteLeft(const LoginPage()),
          (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have been logged out.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeContent(), // the updated Home content (below)
      const SimplePlaceholder(title: 'Exercise Tracker'),
      const SimplePlaceholder(title: 'Calorie Log'),
      const SimplePlaceholder(title: 'Daily Streak'),
      const SimplePlaceholder(title: 'User Profile'),
    ];

    return DefaultTabController(
      length: screens.length,
      child: Scaffold(
        // Major Part: App Bar with Title and Logout button
        appBar: AppBar(
          title: const Text(
            'FitWise Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          elevation: 4,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ],
        ),
        // Major Part: Tab content area
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: screens,
        ),
        // Major Part: Bottom navigation bar (Tabs)
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Exercise'),
              Tab(icon: Icon(Icons.restaurant), text: 'Calories'),
              Tab(icon: Icon(Icons.local_fire_department), text: 'Streak'),
              Tab(icon: Icon(Icons.person), text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

/// SimplePlaceholder - used for other tabs
class SimplePlaceholder extends StatelessWidget {
  final String title;
  const SimplePlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }
}

/// HomeContent - actual Home tab content
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Firestore & Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // user data
  String _username = 'User';
  bool _loadingUser = true;

  // placeholder weights and goal (can be overridden from Firestore if present)
  double _currentWeight = 70.0;
  double _goalWeight = 65.0;
  String _goalType = 'lose'; // 'lose' or 'gain'
  double _startWeight = 80.0;

  // BMR + weekly placeholder
  double _bmr = 1650;
  Map<String, double> _weekly = {'Mon': 300, 'Tue': 420, 'Wed': 380, 'Thu': 450, 'Fri': 310, 'Sat': 500, 'Sun': 290};

  // Food carousel (placeholder entries)
  late List<Map<String, dynamic>> _allFoods; // full list
  late List<Map<String, dynamic>> _timeFoods; // filtered by time

  // Controllers - moved here to be accessible by _WeightActionButton
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prepareFoods();
    _fetchUser();
  }

  void _prepareFoods() {
    _allFoods = [
      {'name': 'Oatmeal', 'kcal': 280, 'desc': 'Filling breakfast', 'icon': Icons.egg, 'type': 'morning'},
      {'name': 'Greek Yogurt', 'kcal': 150, 'desc': 'Protein rich', 'icon': Icons.local_cafe, 'type': 'morning'},
      {'name': 'Grilled Chicken Wrap', 'kcal': 420, 'desc': 'Lean protein lunch', 'icon': Icons.lunch_dining, 'type': 'afternoon'},
      {'name': 'Quinoa Salad', 'kcal': 350, 'desc': 'High fiber', 'icon': Icons.grass, 'type': 'afternoon'},
      {'name': 'Steamed Fish', 'kcal': 360, 'desc': 'Light dinner', 'icon': Icons.set_meal, 'type': 'evening'},
      {'name': 'Veg Stir Fry', 'kcal': 300, 'desc': 'Low-cal veg meal', 'icon': Icons.soup_kitchen, 'type': 'evening'},
      {'name': 'Fruit Smoothie', 'kcal': 180, 'desc': 'Quick Refuel', 'icon': Icons.blender, 'type': 'any'},
    ];
    _filterFoodsByTime();
  }

  void _filterFoodsByTime() {
    final h = DateTime.now().hour;
    String type = (h >= 5 && h < 12) ? 'morning' : (h >= 12 && h < 18) ? 'afternoon' : 'evening';
    _timeFoods = _allFoods.where((f) => f['type'] == type || f['type'] == 'any').toList();
  }

  // Major Part: Fetch user data from Firebase/Firestore
  Future<void> _fetchUser() async {
    setState(() => _loadingUser = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _username = 'User';
          _loadingUser = false;
        });
        return;
      }
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          if (data.containsKey('username')) _username = (data['username'] ?? 'User').toString();
          if (data.containsKey('currentWeight')) {
            final v = data['currentWeight'];
            if (v is num) _currentWeight = v.toDouble();
          }
          if (data.containsKey('goalWeight')) {
            final v = data['goalWeight'];
            if (v is num) _goalWeight = v.toDouble();
          }
          if (data.containsKey('goalType')) {
            final v = data['goalType'];
            if (v is String) _goalType = v;
          }
          if (data.containsKey('startWeight')) {
            final v = data['startWeight'];
            if (v is num) _startWeight = v.toDouble();
          }
        }
      }
    } catch (e) {
      // ignore, keep placeholders
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Greeting text helper
  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Battery percent logic helper
  double _batteryPercent() {
    double pct = 0.0;
    final isGain = _goalType == 'gain';

    if (_startWeight == _goalWeight) {
      return 0.0; // Avoid division by zero
    }

    if (isGain) {
      if (_currentWeight >= _goalWeight) return 1.0;
      if (_currentWeight <= _startWeight) return 0.0;
      pct = (_currentWeight - _startWeight) / (_goalWeight - _startWeight);
    } else { // lose
      if (_currentWeight <= _goalWeight) return 1.0;
      if (_currentWeight >= _startWeight) return 0.0;
      pct = (_startWeight - _currentWeight) / (_startWeight - _goalWeight);
    }

    if (pct.isNaN) pct = 0.0;
    return pct.clamp(0.0, 1.0);
  }

  // Major Part: Top greeting and calorie summary
  Widget _buildTopGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.accent1, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.dark1.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.self_improvement, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(), style: const TextStyle(fontSize: 14, color: AppColors.darkGray)),
              const SizedBox(height: 4),
              _loadingUser ? const Text('Loading...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)) : Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(12)),
            child: Row(children: const [Icon(Icons.local_fire_department, color: AppColors.blue), SizedBox(width: 6), Text('420 kcal', style: TextStyle(fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  // BMR + weekly graph placeholder
  Widget _buildBmrWeeklyCard() {
    final maxVal = _weekly.values.fold<double>(0, (p, n) => n > p ? n : p);
    return _cardWrapper(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _smallIconBox(Icons.insights),
          const SizedBox(width: 12),
          const Expanded(child: Text('BMR & Weekly Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          const Text('Overview', style: TextStyle(color: AppColors.darkGray)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          // BMR summary left
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('BMR', style: TextStyle(color: AppColors.darkGray)),
              const SizedBox(height: 6),
              Text('${_bmr.round()} kcal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(height: 8, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)), child: FractionallySizedBox(widthFactor: 0.6, child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8))))),
            ]),
          ),
          const SizedBox(width: 12),
          // Weekly mini bars right
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 90,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: _weekly.entries.map((e) {
                final factor = (e.value / (maxVal == 0 ? 1 : maxVal)).clamp(0.12, 1.0);
                return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(width: 18, height: factor * 60, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.95), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 6),
                  Text(e.key, style: const TextStyle(fontSize: 11)),
                ]);
              }).toList()),
            ),
          ),
        ]),
      ]),
    );
  }

  // Major Part: Weight battery and goal info card
  Widget _buildWeightBatteryCard() {
    final pct = _batteryPercent();
    final pctRounded = (pct * 100).round();
    final isGain = _goalType == 'gain';

    // Helper function to handle the update logic
    void handleSave() {
      final wt = double.tryParse(_weightController.text);
      
      // Only require weight to update the progress card
      if (wt == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid weight to save.')));
        return;
      }
      // Update state for visual refresh
      setState(() {
        _currentWeight = wt;
      });
      // Height is optional, clear after use
      _weightController.clear();
      _heightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Weight saved: ${wt.toStringAsFixed(1)} kg')));
      // Optionally: write to Firestore here
    }

    return _cardWrapper(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Battery on the left
        Column(children: [
          Text(isGain ? 'Gain Goal' : 'Lose Goal', style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          VerticalBattery(
            percent: pct,
            width: 48,
            height: 160,
            fillColor: AppColors.primary,
            backgroundColor: AppColors.lightGray.withOpacity(0.15),
            borderColor: AppColors.charcoal.withOpacity(0.18),
            showPercentage: false,
          ),
          const SizedBox(height: 8),
          Text('$pctRounded%', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(width: 14),
        // Central Info and Vertical Action Button
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Weight Progress', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Current: ${_currentWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Goal: ${_goalWeight.toStringAsFixed(1)} kg (${_goalType.toUpperCase()})', style: const TextStyle(color: AppColors.darkGray)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: AppColors.lightGray, color: AppColors.primary)),
            const SizedBox(height: 10),
            // NEW: Vertical action area, now flexible
            _WeightActionButton(
              weightController: _weightController,
              heightController: _heightController,
              isGain: isGain,
              currentWeight: _currentWeight,
              onSave: handleSave,
              onToggleGoal: () {
                setState(() => _goalType = isGain ? 'lose' : 'gain');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goal set to ${_goalType.toUpperCase()}')));
              },
            ),
          ]),
        ),
      ]),
    );
  }

  // Major Part: Graph placeholder card (now full width, below battery)
  Widget _buildGraphCard() {
    return _cardWrapper(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _smallIconBox(Icons.show_chart),
          const SizedBox(width: 12),
          const Expanded(child: Text('Progress Graph', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          const Text('Week', style: TextStyle(color: AppColors.darkGray)),
        ]),
        const SizedBox(height: 12),
        // Constrain the graph to a fixed safe height
        SizedBox(
          height: 150,
          child: Center(
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(color: AppColors.lightBlue.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.show_chart, size: 36, color: AppColors.blue),
                  SizedBox(height: 8),
                  Text('Graph placeholder', style: TextStyle(fontSize: 14)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // Major Part: Food carousel (aesthetic ListView)
  Widget _buildFoodCarousel() {
    final foods = _timeFoods;
    const itemWidth = 120.0;
    const itemHeight = 160.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Row(children: [
            _smallIconBox(Icons.restaurant),
            const SizedBox(width: 12),
            Expanded(child: Text('Recommended for ${_greeting().split(' ').last}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const Icon(Icons.chevron_right, color: AppColors.darkGray),
          ]),
        ),
        SizedBox(
          height: itemHeight,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: foods.length,
            itemBuilder: (context, index) {
              return FoodItemCard(
                food: foods[index],
                width: itemWidth,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${foods[index]['name']} selected'))),
              );
            },
          ),
        ),
      ]),
    );
  }

  // Major Part: Exercise Now Button (Aesthetic CTA)
  Widget _buildExerciseButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        elevation: 8,
        shadowColor: AppColors.primary.withOpacity(0.4),
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start Exercise - placeholder'))),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.accent1, AppColors.primary], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Aesthetic Icon with Shimmer effect
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Color(0xFFFFFFB3)]).createShader(bounds), // Using a lighter color for shimmer
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Start Your Workout Now', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
            ]),
          ),
        ),
      ),
    );
  }

  // ----------------- UI helpers -----------------
  Widget _smallIconBox(IconData icon) {
    return Container(
      decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 22, color: AppColors.blue),
    );
  }

  Widget _cardWrapper({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.dark1.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))]),
      child: child,
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, bool small = true}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: small ? 18 : 24, color: AppColors.mediumDark),
        filled: true,
        fillColor: AppColors.lightBlue.withOpacity(0.08),
        contentPadding: EdgeInsets.symmetric(vertical: small ? 10 : 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      style: TextStyle(fontSize: small ? 13 : 14, color: AppColors.mediumDark),
    );
  }

  // Major Part: Main build method for the Home screen
  @override
  Widget build(BuildContext context) {
    // refresh time-filtered foods in case time changed
    _filterFoodsByTime();

    return SafeArea(
      child: Material(
        color: AppColors.tertiary.withOpacity(0.03),
        child: Column(
          children: [
            _buildTopGreeting(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _buildBmrWeeklyCard(),
                  // Now stacked vertically (full width)
                  _buildWeightBatteryCard(),
                  _buildGraphCard(), // Graph card is here
                  _buildFoodCarousel(),
                  _buildExerciseButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Dynamic Action Button Widget (Flexible and Overflow-Safe) ---

/// NEW WIDGET: Vertical action area for weight/height update and goal toggle
class _WeightActionButton extends StatefulWidget {
  final TextEditingController weightController;
  final TextEditingController heightController;
  final bool isGain;
  final double currentWeight;
  final VoidCallback onSave;
  final VoidCallback onToggleGoal;

  const _WeightActionButton({
    super.key,
    required this.weightController,
    required this.heightController,
    required this.isGain,
    required this.currentWeight,
    required this.onSave,
    required this.onToggleGoal,
  });

  @override
  State<_WeightActionButton> createState() => _WeightActionButtonState();
}

class _WeightActionButtonState extends State<_WeightActionButton> {
  // Local state to manage the view: true for inputs, false for main button/actions
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill weight on initialization/rebuild of the parent widget
    widget.weightController.text = widget.currentWeight.toStringAsFixed(1);
  }

  // Helper to access parent state methods like _inputField
  _HomeContentState get _parentState => context.findAncestorStateOfType<_HomeContentState>()!;

  @override
  Widget build(BuildContext context) {
    // Use AnimatedSize to allow the container to grow/shrink based on its content (flexible)
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: _isEditing ? AppColors.lightGray.withOpacity(0.2) : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isEditing ? AppColors.mediumGray.withOpacity(0.5) : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: _isEditing ? Colors.transparent : AppColors.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // Use AnimatedSwitcher for content transition
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
            },
            child: _isEditing ? _buildEditState() : _buildIdleState(),
          ),
        ),
      ),
    );
  }

  // The state when the user is not actively inputting data (main action buttons view)
  Widget _buildIdleState() {
    return Padding(
      key: const ValueKey<bool>(false), // Key for AnimatedSwitcher
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), // Padding is now part of the content, defining size
      child: Column(
        mainAxisSize: MainAxisSize.min, // Essential for AnimatedSize
        children: [
          // Main button to trigger the edit state
          InkWell(
            onTap: () {
              // Pre-fill current weight and clear height on tap to edit
              widget.weightController.text = widget.currentWeight.toStringAsFixed(1);
              widget.heightController.clear();
              setState(() => _isEditing = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.accent1, AppColors.primary]),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Update Weight/Height', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
          // Simple toggle button below the main update action
          Container(
            height: 30, // Fixed height for a consistent button area
            margin: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: widget.onToggleGoal,
              icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.charcoal),
              label: Text('Toggle Goal (${widget.isGain ? 'Gain' : 'Lose'})', style: const TextStyle(fontSize: 12, color: AppColors.charcoal, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          )
        ],
      ),
    );
  }
  
  // The state when the user is inputting data (expanded view)
  Widget _buildEditState() {
    return Padding(
      key: const ValueKey<bool>(true), // Key for AnimatedSwitcher
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Essential for AnimatedSize
        children: [
          // Weight and Height Input Row (using parent's _inputField helper)
          Row(
            children: [
              // Using small input field for compact design
              Expanded(child: _parentState._inputField(controller: widget.weightController, hint: 'Weight (kg)', icon: Icons.scale, small: true)),
              const SizedBox(width: 8),
              Expanded(child: _parentState._inputField(controller: widget.heightController, hint: 'Height (cm)', icon: Icons.height, small: true)),
            ],
          ),
          const SizedBox(height: 8),
          // Save and Cancel Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Call parent's save logic, then switch back to idle state
                    widget.onSave();
                    setState(() => _isEditing = false);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => setState(() => _isEditing = false), // Switch back to idle state
                  icon: const Icon(Icons.close, size: 18, color: AppColors.charcoal),
                  label: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Supporting Widgets (Kept for completeness) ---

/// VerticalBattery - vertical battery widget used in the weight card
class VerticalBattery extends StatelessWidget {
  final double percent; // 0..1
  final double width;
  final double height;
  final Color fillColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showPercentage;

  const VerticalBattery({
    super.key,
    required this.percent,
    this.width = 36,
    this.height = 140,
    this.fillColor = AppColors.primary,
    this.backgroundColor = AppColors.lightGray,
    this.borderColor = AppColors.charcoal,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final innerHeight = (height - 8);
    final fillHeight = (clamped * innerHeight).clamp(0.0, innerHeight);
    return Column(
      children: [
        // cap
        Container(width: width * 0.6, height: height * 0.06, decoration: BoxDecoration(color: borderColor.withOpacity(0.6), borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 6),
        Stack(alignment: Alignment.bottomCenter, children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: backgroundColor, border: Border.all(color: borderColor, width: 1.4)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: width - 6,
            height: fillHeight,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.vertical(bottom: const Radius.circular(6), top: Radius.circular(fillHeight < 8 ? 6 : 0)), boxShadow: [BoxShadow(color: AppColors.dark1.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]),
          ),
          if (showPercentage)
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(child: Text('${(clamped * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 1))]))),
            ),
        ]),
      ],
    );
  }
}

/// FoodItemCard - Aesthetic card for horizontal food list
class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final double width;
  final VoidCallback onTap;

  const FoodItemCard({
    super.key,
    required this.food,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        elevation: 6,
        shadowColor: AppColors.primary.withOpacity(0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // Using a subtle secondary gradient overlay for flavor
              gradient: LinearGradient(
                colors: [AppColors.accent1.withOpacity(0.8), AppColors.primary.withOpacity(0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(food['icon'] as IconData, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  food['name'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${food['kcal']} kcal',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                ),
                const Spacer(),
                Text(
                  food['desc'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}