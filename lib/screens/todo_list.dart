import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../utils/smart_suggestions.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Task> tasks = [];
  String currentMood = 'happy';
  Map<String, dynamic> currentMoodData = {};
  bool isDarkMode = false;
  late AnimationController _listController;
  late AnimationController _fabController;

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
    WidgetsBinding.instance.addObserver(this);

    _listController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadCurrentMood();
    _loadDarkModePreference();
    _loadTasks();

    Future.delayed(const Duration(milliseconds: 500), () {
      _listController.forward();
      _fabController.forward();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDarkModePreference();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTasks();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool newDarkMode = prefs.getBool('dark_mode') ?? false;

    // Only setState if the value actually changed
    if (newDarkMode != isDarkMode) {
      setState(() {
        isDarkMode = newDarkMode;
      });
    }
  }

  Future<void> _loadCurrentMood() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedMood = prefs.getString('current_mood');

    setState(() {
      currentMood = savedMood ?? 'happy';
      currentMoodData = moods[currentMood] ?? moods['happy']!;
    });
  }

  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? taskStrings = prefs.getStringList('tasks');

    if (taskStrings != null) {
      setState(() {
        tasks = taskStrings.map((taskString) {
          Map<String, dynamic> taskMap = json.decode(taskString);
          return Task.fromMap(taskMap);
        }).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings = tasks.map((task) {
      return json.encode(task.toMap());
    }).toList();

    await prefs.setStringList('tasks', taskStrings);
  }

  void _toggleTask(String taskId) {
    setState(() {
      int index = tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        tasks[index].isCompleted = !tasks[index].isCompleted;
      }
    });

    _saveTasks();
  }

  void _deleteTask(String taskId) {
    setState(() {
      tasks.removeWhere((task) => task.id == taskId);
    });

    _saveTasks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        backgroundColor: currentMoodData['darkColor'],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToAddTask() async {
    await Navigator.pushNamed(context, '/add-task');
    _loadTasks();
    _loadDarkModePreference();
  }

  void _navigateToSettings() async {
    await Navigator.pushNamed(context, '/settings');
    _loadDarkModePreference();
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'work':
        return '💼';
      case 'personal':
        return '👤';
      case 'health':
        return '🏃';
      case 'learning':
        return '📚';
      case 'creative':
        return '🎨';
      default:
        return '📋';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ADD THIS - Remove observer
    _listController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      currentMood = arguments['mood'];
      currentMoodData = arguments['moodData'];
    }

    List<Task> moodTasks = tasks
        .where((task) => task.mood == currentMood)
        .toList();
    List<Task> completedTasks = moodTasks
        .where((task) => task.isCompleted)
        .toList();
    List<Task> pendingTasks = moodTasks
        .where((task) => !task.isCompleted)
        .toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF121212)]
                : [currentMoodData['color'] ?? Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        '/mood-selector',
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  currentMoodData['darkColor']?.withOpacity(
                                    0.2,
                                  ) ??
                                  Colors.blue.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          currentMoodData['emoji'] ?? '😊',
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Feeling ${currentMoodData['name'] ?? 'Happy'}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : (currentMoodData['darkColor'] ??
                                        Colors.blue),
                            ),
                          ),
                          Text(
                            '${pendingTasks.length} tasks pending',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToSettings,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentMoodData['darkColor'] ?? Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.settings, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              if (tasks.isNotEmpty)
                Container(
                  height: 110,
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: currentMoodData['darkColor'],
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Smart Suggestions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : currentMoodData['darkColor'],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              SmartSuggestions.generateSuggestions(
                                tasks,
                                currentMood,
                                DateTime.now(),
                              ).map((suggestion) {
                                return Container(
                                  margin: EdgeInsets.only(right: 10),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(maxWidth: 280),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDarkMode
                                          ? [
                                              currentMoodData['darkColor']
                                                      ?.withValues(
                                                        alpha: 0.3,
                                                      ) ??
                                                  Colors.blue.withValues(
                                                    alpha: 0.3,
                                                  ),
                                              currentMoodData['darkColor']
                                                      ?.withValues(
                                                        alpha: 0.1,
                                                      ) ??
                                                  Colors.blue.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            ]
                                          : [
                                              currentMoodData['color']
                                                      ?.withValues(
                                                        alpha: 0.8,
                                                      ) ??
                                                  Colors.blue[100]!,
                                              currentMoodData['color']
                                                      ?.withValues(
                                                        alpha: 0.5,
                                                      ) ??
                                                  Colors.blue[50]!,
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          currentMoodData['darkColor']
                                              ?.withValues(alpha: 0.4) ??
                                          Colors.blue,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lightbulb,
                                        size: 16,
                                        color: currentMoodData['darkColor'],
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          suggestion,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDarkMode
                                                ? Colors.white
                                                : currentMoodData['darkColor'],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: moodTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentMoodData['emoji'] ?? '📝',
                              style: TextStyle(fontSize: 80),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No ${currentMoodData['name']} tasks yet!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : currentMoodData['darkColor'],
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Add tasks for your ${currentMoodData['name']} mood',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          return ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (pendingTasks.isNotEmpty) ...[
                                Text(
                                  'To Do (${pendingTasks.length})',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : currentMoodData['darkColor'],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...pendingTasks.map((task) {
                                  return SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(1, 0),
                                          end: const Offset(0, 0),
                                        ).animate(
                                          CurvedAnimation(
                                            parent: _listController,
                                            curve: Curves.easeOut,
                                          ),
                                        ),
                                    child: _buildTaskCard(task),
                                  );
                                }),
                                const SizedBox(height: 30),
                              ],

                              if (completedTasks.isNotEmpty) ...[
                                Text(
                                  'Completed (${completedTasks.length})',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...completedTasks.map((task) {
                                  return FadeTransition(
                                    opacity: Tween<double>(
                                      begin: 0.0,
                                      end: 0.6,
                                    ).animate(_listController),
                                    child: _buildTaskCard(task),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddTask,
          backgroundColor: currentMoodData['darkColor'] ?? Colors.blue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Task',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        onDismissed: (direction) {
          _deleteTask(task.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? (isDarkMode ? Colors.grey[800] : Colors.grey[100])
                : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: task.isCompleted
                  ? (isDarkMode ? Colors.grey[600]! : Colors.grey[300]!)
                  : (isDarkMode
                        ? currentMoodData['darkColor']?.withValues(
                                alpha: 0.3,
                              ) ??
                              Colors.blue.withValues(alpha: 0.3)
                        : currentMoodData['color'] ?? Colors.blue[100]!),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (currentMoodData['darkColor'] ?? Colors.blue).withValues(
                  alpha: isDarkMode ? 0.2 : 0.1,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleTask(task.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? currentMoodData['darkColor'] ?? Colors.blue
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted
                          ? currentMoodData['darkColor'] ?? Colors.blue
                          : (isDarkMode
                                ? Colors.grey[500]!
                                : Colors.grey[400]!),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              Text(
                _getCategoryIcon(task.category),
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: task.isCompleted
                            ? (isDarkMode ? Colors.grey[500] : Colors.grey[600])
                            : (isDarkMode ? Colors.white : Colors.black87),
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: task.isCompleted
                              ? (isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[500])
                              : (isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[700]),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? (moods[task.mood]?['darkColor'] ??
                                currentMoodData['darkColor'])
                            ?.withOpacity(0.3)
                      : (moods[task.mood]?['color'] ??
                            currentMoodData['color']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  moods[task.mood]?['emoji'] ??
                      currentMoodData['emoji'] ??
                      '😊',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
