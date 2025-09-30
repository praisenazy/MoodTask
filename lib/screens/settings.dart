import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class Settings extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const Settings({super.key, this.onThemeChanged});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with TickerProviderStateMixin {
  String currentMood = 'happy';
  Map<String, dynamic> currentMoodData = {};
  bool isDarkMode = false;
  bool notificationsEnabled = true;
  List<Task> allTasks = [];
  Map<String, int> moodHistory = {};

  late AnimationController _slideController;
  late AnimationController _statsController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _statsAnimation;

  // Mood definitions
  final Map<String, Map<String, dynamic>> moods = {
    'happy': {
      'emoji': '😊',
      'name': 'Happy',
      'color': const Color(0xFFE3F2FD),
      'darkColor': const Color(0xFF1976D2),
    },
    'tired': {
      'emoji': '😴',
      'name': 'Tired',
      'color': const Color(0xFFF3E5F5),
      'darkColor': const Color(0xFF7B1FA2),
    },
    'focused': {
      'emoji': '😤',
      'name': 'Focused',
      'color': const Color(0xFFFFF3E0),
      'darkColor': const Color(0xFFE65100),
    },
    'productive': {
      'emoji': '🎯',
      'name': 'Productive',
      'color': const Color(0xFFE8F5E8),
      'darkColor': const Color(0xFF388E3C),
    },
    'calm': {
      'emoji': '😌',
      'name': 'Calm',
      'color': const Color(0xFFFCE4EC),
      'darkColor': const Color(0xFFC2185B),
    },
  };

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutBack),
    );

    _loadData();

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      _statsController.forward();
    });
  }

  // Load all data
  Future<void> _loadData() async {
    await _loadCurrentMood();
    await _loadTasks();
    await _loadSettings();
    _calculateMoodHistory();
  }

  // Load current mood
  Future<void> _loadCurrentMood() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedMood = prefs.getString('current_mood');

    setState(() {
      currentMood = savedMood ?? 'happy';
      currentMoodData = moods[currentMood] ?? moods['happy']!;
    });
  }

  // Load all tasks
  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskStrings = prefs.getStringList('tasks');

    if (taskStrings != null) {
      setState(() {
        allTasks = taskStrings.map((taskString) {
          Map<String, dynamic> taskMap = json.decode(taskString);
          return Task.fromMap(taskMap);
        }).toList();
      });
    }
  }

  // Load settings
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
      notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  // Calculate mood history
  void _calculateMoodHistory() {
    moodHistory.clear();
    for (Task task in allTasks) {
      moodHistory[task.mood] = (moodHistory[task.mood] ?? 0) + 1;
    }
    setState(() {});
  }

  // Toggle dark mode - NOW ACTUALLY APPLIES THE THEME
  Future<void> _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);

    setState(() {
      isDarkMode = value;
    });

    // Call the callback to update the main app theme
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(value);
    }

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
        backgroundColor: currentMoodData['darkColor'],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Toggle notifications
  Future<void> _toggleNotifications(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() {
      notificationsEnabled = value;
    });
  }

  // Clear all data
  Future<void> _clearAllData() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 30),
              SizedBox(width: 12),
              Text(
                'Clear All Data?',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'This will permanently delete all your tasks and mood history. This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/mood-selector');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Get completion percentage
  double _getCompletionPercentage() {
    if (allTasks.isEmpty) return 0.0;
    int completedTasks = allTasks.where((task) => task.isCompleted).length;
    return completedTasks / allTasks.length;
  }

  // Get most used mood
  String _getMostUsedMood() {
    if (moodHistory.isEmpty) return 'No data yet';

    String mostUsedMood = moodHistory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return '${moods[mostUsedMood]?['emoji']} ${moods[mostUsedMood]?['name']}';
  }

  // Get theme-aware colors
  Color getBackgroundColor() {
    return isDarkMode
        ? const Color(0xFF121212)
        : currentMoodData['color'] ?? Colors.blue[50]!;
  }

  Color _getCardColor() {
    return isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color getTextColor() {
    return isDarkMode ? Colors.white : Colors.black87;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Task> completedTasks = allTasks
        .where((task) => task.isCompleted)
        .toList();
    List<Task> pendingTasks = allTasks
        .where((task) => !task.isCompleted)
        .toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [currentMoodData['color'] ?? Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCardColor(),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: currentMoodData['darkColor'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : currentMoodData['darkColor'],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCardColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: currentMoodData['darkColor'],
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Main content with dark mode support
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Section
                        AnimatedBuilder(
                          animation: _statsAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _statsAnimation.value,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _getCardColor(),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDarkMode ? 0.3 : 0.1,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.analytics,
                                          color: currentMoodData['darkColor'],
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Your Statistics',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.white
                                                : currentMoodData['darkColor'],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Stats Grid
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            icon: Icons.task_alt,
                                            title: 'Total Tasks',
                                            value: '${allTasks.length}',
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            icon: Icons.check_circle,
                                            title: 'Completed',
                                            value: '${completedTasks.length}',
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            icon: Icons.pending,
                                            title: 'Pending',
                                            value: '${pendingTasks.length}',
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            icon: Icons.percent,
                                            title: 'Success Rate',
                                            value:
                                                '${(_getCompletionPercentage() * 100).toInt()}%',
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // Most used mood
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? currentMoodData['darkColor']
                                                  ?.withOpacity(0.2)
                                            : currentMoodData['color'],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Most Used Mood',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : currentMoodData['darkColor'],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getMostUsedMood(),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : currentMoodData['darkColor'],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // App Settings
                        Text(
                          'App Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : currentMoodData['darkColor'],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Settings options
                        Container(
                          decoration: BoxDecoration(
                            color: _getCardColor(),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDarkMode ? 0.3 : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingsItem(
                                icon: isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                title: isDarkMode ? 'Light Mode' : 'Dark Mode',
                                subtitle: isDarkMode
                                    ? 'Switch to light theme'
                                    : 'Switch to dark theme',
                                trailing: Switch(
                                  value: isDarkMode,
                                  onChanged: _toggleDarkMode,
                                  activeColor: currentMoodData['darkColor'],
                                ),
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildSettingsItem(
                                icon: Icons.notifications,
                                title: 'Notifications',
                                subtitle: 'Get task reminders',
                                trailing: Switch(
                                  value: notificationsEnabled,
                                  onChanged: _toggleNotifications,
                                  activeColor: currentMoodData['darkColor'],
                                ),
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildSettingsItem(
                                icon: Icons.mood,
                                title: 'Change Mood',
                                subtitle: 'Update your current mood',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                                onTap: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/mood-selector',
                                ),
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildSettingsItem(
                                icon: Icons.delete_forever,
                                title: 'Clear All Data',
                                subtitle: 'Delete all tasks and history',
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.red[400],
                                  size: 16,
                                ),
                                onTap: _clearAllData,
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build stat card - WITH DARK MODE SUPPORT
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(isDarkMode ? 0.4 : 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build settings item - WITH DARK MODE SUPPORT
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red[50]
              : isDarkMode
              ? currentMoodData['darkColor']?.withOpacity(0.2)
              : currentMoodData['color']?.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : currentMoodData['darkColor'],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDestructive
              ? Colors.red
              : isDarkMode
              ? Colors.white
              : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.white60 : Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
