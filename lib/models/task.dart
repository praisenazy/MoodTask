class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  String category;
  DateTime createdAt;
  String mood;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.category = 'general',
    required this.createdAt,
    required this.mood,
  });

  // Convert Task to Map for saving
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'mood': mood,
    };
  }

  // Create Task from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      category: map['category'] ?? 'general',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      mood: map['mood'] ?? 'happy',
    );
  }
}
