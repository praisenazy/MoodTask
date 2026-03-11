import '../models/task.dart';

class SmartSuggestions {
  static List<String> generateSuggestions(
    List<Task> allTasks,
    String currentMood,
    DateTime currentDate,
  ) {
    List<String> suggestions = [];

    suggestions.addAll(_getPatternSuggestions(allTasks, currentDate));

    suggestions.addAll(_getTimeSuggestions(currentDate));

    suggestions.addAll(_getMoodHistorySuggestions(allTasks, currentMood));

    suggestions.addAll(_getStreakSuggestions(allTasks, currentDate));

    return suggestions.toSet().take(4).toList();
  }

  static List<String> _getPatternSuggestions(List<Task> tasks, DateTime now) {
    List<String> suggestions = [];
    int currentWeekday = now.weekday;

    List<Task> sameWeekdayTasks = tasks.where((task) {
      return task.createdAt.weekday == currentWeekday &&
          task.isCompleted &&
          task.createdAt.isBefore(now.subtract(Duration(days: 7)));
    }).toList();

    Map<String, int> taskFrequency = {};
    for (var task in sameWeekdayTasks) {
      taskFrequency[task.title] = (taskFrequency[task.title] ?? 0) + 1;
    }

    taskFrequency.forEach((title, count) {
      if (count >= 2) {
        String weekdayName = _getWeekdayName(currentWeekday);
        suggestions.add('You usually "$title" on $weekdayName');
      }
    });

    return suggestions;
  }

  static List<String> _getTimeSuggestions(DateTime now) {
    List<String> suggestions = [];
    int hour = now.hour;

    if (hour >= 6 && hour < 12) {
      suggestions.add('Morning boost: Start your day strong 🌅');
    } else if (hour >= 12 && hour < 17) {
      suggestions.add('Afternoon focus: Tackle your top priority');
    } else if (hour >= 17 && hour < 22) {
      suggestions.add('Evening review: Check your progress today');
    } else {
      suggestions.add('Night prep: Plan tomorrow\'s success');
    }

    if (now.weekday >= DateTime.saturday) {
      suggestions.add('Weekend self-care task?');
    }

    return suggestions;
  }

  static List<String> _getMoodHistorySuggestions(
    List<Task> tasks,
    String currentMood,
  ) {
    List<String> suggestions = [];

    List<Task> sameMoodTasks = tasks
        .where((task) => task.mood == currentMood && task.isCompleted)
        .toList();

    if (sameMoodTasks.isEmpty) return suggestions;

    Map<String, int> categoryCount = {};
    for (var task in sameMoodTasks) {
      categoryCount[task.category] = (categoryCount[task.category] ?? 0) + 1;
    }

    if (categoryCount.isNotEmpty) {
      String topCategory = categoryCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      String categoryName = _getCategoryName(topCategory);
      suggestions.add(
        '$categoryName tasks work well when ${_getMoodName(currentMood)} 🎯',
      );
    }

    return suggestions;
  }

  static List<String> _getStreakSuggestions(List<Task> tasks, DateTime now) {
    List<String> suggestions = [];

    int daysWithTasks = 0;
    for (int i = 1; i <= 3; i++) {
      DateTime checkDate = now.subtract(Duration(days: i));
      bool hasTask = tasks.any(
        (task) =>
            task.isCompleted &&
            task.createdAt.year == checkDate.year &&
            task.createdAt.month == checkDate.month &&
            task.createdAt.day == checkDate.day,
      );
      if (hasTask) daysWithTasks++;
    }

    if (daysWithTasks >= 2) {
      suggestions.add('You\'re on fire! Keep the momentum 🔥');
    }

    DateTime yesterday = now.subtract(Duration(days: 1));
    bool completedYesterday = tasks.any(
      (task) =>
          task.isCompleted &&
          task.createdAt.year == yesterday.year &&
          task.createdAt.month == yesterday.month &&
          task.createdAt.day == yesterday.day,
    );

    if (completedYesterday) {
      suggestions.add('Don\'t break your streak - add a task! 💪');
    }

    return suggestions;
  }

  static String _getWeekdayName(int weekday) {
    const days = [
      '',
      'Mondays',
      'Tuesdays',
      'Wednesdays',
      'Thursdays',
      'Fridays',
      'Saturdays',
      'Sundays',
    ];
    return days[weekday];
  }

  static String _getCategoryName(String category) {
    const names = {
      'work': 'Work',
      'personal': 'Personal',
      'health': 'Health',
      'learning': 'Learning',
      'creative': 'Creative',
      'general': 'General',
    };
    return names[category] ?? 'General';
  }

  static String _getMoodName(String mood) {
    return mood;
  }
}
