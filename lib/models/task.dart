class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  String category;
  DateTime createdAt;
  String mood;
  DateTime? reminderTime;
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.category = 'general',
    required this.createdAt,
    required this.mood,
    this.reminderTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'mood': mood,
      'reminderTime': reminderTime?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      category: map['category'] ?? 'general',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      mood: map['mood'] ?? 'happy',
      reminderTime: map['reminderTime'] != null
          ? DateTime.parse(map['reminderTime'])
          : null,
    );
  }
}
