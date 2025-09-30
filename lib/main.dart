import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/mood_selector.dart';
import 'screens/todo_list.dart';
import 'screens/add_task.dart';
import 'screens/settings.dart';

void main() {
  runApp(const MoodTaskApp());
}

class MoodTaskApp extends StatefulWidget {
  const MoodTaskApp({super.key});

  @override
  _MoodTaskAppState createState() => _MoodTaskAppState();
}

class _MoodTaskAppState extends State<MoodTaskApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  // Method to update theme (can be called from settings)
  void updateTheme(bool darkMode) {
    setState(() {
      isDarkMode = darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodTask',
      debugShowCheckedModeBanner: false,

      // Define light theme
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardColor: Colors.white,
        dividerColor: Colors.grey[300],
      ),

      // Define dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey[700],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      // Use the theme mode based on user preference
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: const SplashScreen(),
      routes: {
        '/mood-selector': (context) => const MoodSelector(),
        '/todo-list': (context) => const TodoList(),
        '/add-task': (context) => const AddTask(),
        '/settings': (context) => Settings(onThemeChanged: updateTheme),
      },
    );
  }
}
