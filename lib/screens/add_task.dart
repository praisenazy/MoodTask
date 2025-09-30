import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class AddTask extends StatefulWidget {
  const AddTask({super.key});

  @override
  _AddTaskState createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String selectedCategory = 'general';
  String currentMood = 'happy';
  Map<String, dynamic> currentMoodData = {};
  bool isDarkMode = false; // ADD DARK MODE SUPPORT
  bool isLoading = false;

  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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

  // Categories with icons and descriptions
  final Map<String, Map<String, String>> categories = {
    'general': {
      'icon': '📋',
      'name': 'General',
      'description': 'Everyday tasks and reminders',
    },
    'work': {
      'icon': '💼',
      'name': 'Work',
      'description': 'Professional and career tasks',
    },
    'personal': {
      'icon': '👤',
      'name': 'Personal',
      'description': 'Personal life and relationships',
    },
    'health': {
      'icon': '🏃',
      'name': 'Health',
      'description': 'Fitness, wellness, and health',
    },
    'learning': {
      'icon': '📚',
      'name': 'Learning',
      'description': 'Education and skill development',
    },
    'creative': {
      'icon': '🎨',
      'name': 'Creative',
      'description': 'Art, design, and creative projects',
    },
  };

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _loadCurrentMood();
    _loadDarkModePreference(); // ADD THIS

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  // ADD DARK MODE LOADING
  Future<void> _loadDarkModePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
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

  // Save new task
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    // Create new task
    Task newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: selectedCategory,
      createdAt: DateTime.now(),
      mood: currentMood,
    );

    // Load existing tasks
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskStrings = prefs.getStringList('tasks') ?? [];

    // Add new task
    taskStrings.add(json.encode(newTask.toMap()));

    // Save updated tasks
    await prefs.setStringList('tasks', taskStrings);

    // Show success animation and navigate back
    _showSuccessDialog();
  }

  // Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white, // DARK MODE SUPPORT
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? currentMoodData['darkColor'].withOpacity(0.2)
                      : currentMoodData['color'], // DARK MODE SUPPORT
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: currentMoodData['darkColor'].withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle,
                  color: currentMoodData['darkColor'],
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Task Added!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? Colors.white
                      : currentMoodData['darkColor'], // DARK MODE SUPPORT
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your task has been saved successfully',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? Colors.white70
                      : Colors.grey[600], // DARK MODE SUPPORT
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to todo list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentMoodData['darkColor'],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'View Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Generate task suggestions based on mood
  List<String> _getMoodBasedSuggestions() {
    switch (currentMood) {
      case 'happy':
        return [
          'Call a friend',
          'Plan a fun activity',
          'Write in gratitude journal',
          'Share good news with someone',
        ];
      case 'tired':
        return [
          'Take a power nap',
          'Drink more water',
          'Do gentle stretching',
          'Prepare for early bedtime',
        ];
      case 'focused':
        return [
          'Complete important project',
          'Tackle challenging task',
          'Organize workspace',
          'Review goals and priorities',
        ];
      case 'productive':
        return [
          'Finish pending assignments',
          'Clean and organize',
          'Plan tomorrow\'s schedule',
          'Learn something new',
        ];
      case 'calm':
        return [
          'Practice meditation',
          'Read a book',
          'Take a peaceful walk',
          'Do some deep breathing',
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [
                    currentMoodData['color'] ?? Colors.blue[50]!,
                    Colors.white,
                  ], // DARK MODE SUPPORT
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.white, // DARK MODE SUPPORT
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
                        'Add New Task',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : currentMoodData['darkColor'], // DARK MODE SUPPORT
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : Colors.white, // DARK MODE SUPPORT
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentMoodData['emoji'] ?? '😊',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title
                            Text(
                              'Task Title',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : currentMoodData['darkColor'], // DARK MODE SUPPORT
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ), // DARK MODE SUPPORT
                              decoration: InputDecoration(
                                hintText: 'What do you want to accomplish?',
                                hintStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ), // DARK MODE SUPPORT
                                filled: true,
                                fillColor: isDarkMode
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white, // DARK MODE SUPPORT
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: currentMoodData['darkColor'],
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.task_alt,
                                  color: currentMoodData['darkColor'],
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a task title';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Task Description
                            Text(
                              'Description (Optional)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : currentMoodData['darkColor'], // DARK MODE SUPPORT
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ), // DARK MODE SUPPORT
                              decoration: InputDecoration(
                                hintText: 'Add more details about this task...',
                                hintStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ), // DARK MODE SUPPORT
                                filled: true,
                                fillColor: isDarkMode
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white, // DARK MODE SUPPORT
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: currentMoodData['darkColor'],
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 60),
                                  child: Icon(
                                    Icons.description,
                                    color: currentMoodData['darkColor'],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Category Selection
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : currentMoodData['darkColor'], // DARK MODE SUPPORT
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  String categoryKey = categories.keys
                                      .elementAt(index);
                                  Map<String, String> category =
                                      categories[categoryKey]!;
                                  bool isSelected =
                                      selectedCategory == categoryKey;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategory = categoryKey;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(16),
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? currentMoodData['darkColor']
                                            : (isDarkMode
                                                  ? const Color(0xFF1E1E1E)
                                                  : Colors
                                                        .white), // DARK MODE SUPPORT
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: isSelected
                                              ? currentMoodData['darkColor']
                                              : (isDarkMode
                                                    ? Colors.grey[700]!
                                                    : Colors
                                                          .grey[300]!), // DARK MODE SUPPORT
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            category['icon']!,
                                            style: const TextStyle(
                                              fontSize: 30,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            category['name']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDarkMode
                                                        ? Colors.white
                                                        : currentMoodData['darkColor']), // DARK MODE SUPPORT
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Mood-based suggestions
                            Text(
                              'Suggestions for your ${currentMoodData['name']} mood',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : currentMoodData['darkColor'], // DARK MODE SUPPORT
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _getMoodBasedSuggestions().map((
                                suggestion,
                              ) {
                                return GestureDetector(
                                  onTap: () {
                                    _titleController.text = suggestion;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? currentMoodData['darkColor']
                                                .withOpacity(0.2)
                                          : currentMoodData['color'], // DARK MODE SUPPORT
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: currentMoodData['darkColor']
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      suggestion,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? Colors.white
                                            : currentMoodData['darkColor'], // DARK MODE SUPPORT
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentMoodData['darkColor'],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                    ),
                    child: isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Saving Task...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_task, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Add Task',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
}
