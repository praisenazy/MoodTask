import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodSelector extends StatefulWidget {
  const MoodSelector({super.key});

  @override
  _MoodSelectorState createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector>
    with TickerProviderStateMixin {
  String? selectedMood;
  bool isDarkMode = false;
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;

  // Define moods with their colors and info
  final Map<String, Map<String, dynamic>> moods = {
    'happy': {
      'emoji': '😊',
      'name': 'Happy',
      'color': const Color(0xFFE3F2FD),
      'darkColor': const Color(0xFF1976D2),
      'description': 'Ready to tackle anything!',
    },
    'tired': {
      'emoji': '😴',
      'name': 'Tired',
      'color': const Color(0xFFF3E5F5),
      'darkColor': const Color(0xFF7B1FA2),
      'description': 'Take it easy today',
    },
    'focused': {
      'emoji': '😤',
      'name': 'Focused',
      'color': const Color(0xFFFFF3E0),
      'darkColor': const Color(0xFFE65100),
      'description': 'Time to get things done!',
    },
    'productive': {
      'emoji': '🎯',
      'name': 'Productive',
      'color': const Color(0xFFE8F5E8),
      'darkColor': const Color(0xFF388E3C),
      'description': 'Let\'s achieve goals!',
    },
    'calm': {
      'emoji': '😌',
      'name': 'Calm',
      'color': const Color(0xFFFCE4EC),
      'darkColor': const Color(0xFFC2185B),
      'description': 'Peace and mindfulness',
    },
  };

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundAnimation =
        ColorTween(begin: Colors.grey[50], end: Colors.grey[50]).animate(
          CurvedAnimation(
            parent: _backgroundController,
            curve: Curves.easeInOut,
          ),
        );

    _loadSavedMood();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _loadSavedMood() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedMood = prefs.getString('current_mood');
    if (savedMood != null && moods.containsKey(savedMood)) {
      setState(() {
        selectedMood = savedMood;
      });
      _updateBackgroundColor();
    }
  }

  Future<void> _saveMood(String mood) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_mood', mood);
    await prefs.setString('mood_date', DateTime.now().toString());
  }

  void _updateBackgroundColor() {
    if (selectedMood != null) {
      Color targetColor = isDarkMode
          ? const Color(0xFF1E1E1E)
          : moods[selectedMood]!['color'];

      _backgroundAnimation =
          ColorTween(
            begin:
                _backgroundAnimation.value ??
                (isDarkMode ? const Color(0xFF121212) : Colors.grey[50]),
            end: targetColor,
          ).animate(
            CurvedAnimation(
              parent: _backgroundController,
              curve: Curves.easeInOut,
            ),
          );

      _backgroundController.reset();
      _backgroundController.forward();
    }
  }

  void _selectMood(String mood) {
    setState(() {
      selectedMood = mood;
    });

    _updateBackgroundColor();
    _saveMood(mood);
    _showMoodConfirmation(mood);
  }

  void _showMoodConfirmation(String mood) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? moods[mood]!['darkColor'].withOpacity(0.2)
                      : moods[mood]!['color'],
                  border: Border.all(
                    color: moods[mood]!['darkColor'],
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    moods[mood]!['emoji'],
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Feeling ${moods[mood]!['name']}?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : moods[mood]!['darkColor'],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                moods[mood]!['description'],
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      selectedMood = null;
                    });
                    _backgroundController.reverse();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(
                      context,
                      '/todo-list',
                      arguments: {'mood': mood, 'moodData': moods[mood]},
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: moods[mood]!['darkColor'],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Let\'s Go!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.all(20),
        );
      },
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                    : [
                        _backgroundAnimation.value ?? Colors.grey[50]!,
                        Colors.white,
                      ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16), // Reduced padding
                child: Column(
                  children: [
                    // Header - Reduced size
                    const SizedBox(height: 20), // Reduced from 40
                    Text(
                      'How are you feeling today?',
                      style: TextStyle(
                        fontSize: 24, // Reduced from 26
                        fontWeight: FontWeight.bold,
                        color: selectedMood != null
                            ? moods[selectedMood]!['darkColor']
                            : isDarkMode
                            ? Colors.white
                            : Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Choose your mood',
                      style: TextStyle(
                        fontSize: 14, // Reduced from 15
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30), // Reduced from 60
                    // Mood Buttons Grid - Simplified
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            1.2, // Increased for more width, less height
                        children: moods.entries.map((entry) {
                          String moodKey = entry.key;
                          Map<String, dynamic> mood = entry.value;
                          bool isSelected = selectedMood == moodKey;

                          return GestureDetector(
                            onTap: () => _selectMood(moodKey),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? (isSelected
                                          ? mood['darkColor'].withOpacity(0.3)
                                          : const Color(0xFF1E1E1E))
                                    : mood['color'],
                                borderRadius: BorderRadius.circular(
                                  16,
                                ), // Reduced from 20
                                border: Border.all(
                                  color: isSelected
                                      ? mood['darkColor']
                                      : isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.transparent,
                                  width: 2, // Reduced from 3
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: mood['darkColor'].withOpacity(0.15),
                                    blurRadius: isSelected ? 12 : 6, // Reduced
                                    spreadRadius: isSelected ? 1 : 0, // Reduced
                                    offset: const Offset(0, 3), // Reduced
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    mood['emoji'],
                                    style: const TextStyle(
                                      fontSize: 40,
                                    ), // Reduced from 45
                                  ),
                                  const SizedBox(height: 8), // Reduced from 10
                                  Text(
                                    mood['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : mood['darkColor'],
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 4), // Reduced from 6
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ), // Reduced
                                      decoration: BoxDecoration(
                                        color: mood['darkColor'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '✓',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10, // Reduced
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Simple Continue Button - NO COMPLEX ANIMATIONS
                    const SizedBox(height: 20),
                    if (selectedMood != null)
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/todo-list',
                              arguments: {
                                'mood': selectedMood,
                                'moodData': moods[selectedMood],
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: moods[selectedMood]!['darkColor'],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 6,
                          ),
                          child: const Text(
                            '✨ Continue to Tasks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
