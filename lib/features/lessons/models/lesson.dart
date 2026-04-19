class Lesson {
  final String id;
  final String topicId;
  final String title;
  final String description;
  final String content;
  final List<String> keyConcepts;
  final List<String> examples;
  final String skill;
  final String difficulty;
  final int estimatedMinutes;
  final int order;
  final List<String> tags;
  final List<String> targetLevels;

  const Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.description,
    required this.content,
    this.keyConcepts = const [],
    this.examples = const [],
    this.skill = '',
    this.difficulty = 'Beginner',
    this.estimatedMinutes = 10,
    this.order = 0,
    this.tags = const [],
    this.targetLevels = const [],
  });

  factory Lesson.fromMap({
    required String id,
    required String topicId,
    required Map<String, dynamic> data,
  }) {
    return Lesson(
      id: id,
      topicId: topicId,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      content: (data['content'] ?? '').toString(),
      keyConcepts: _toStringList(data['keyConcepts']),
      examples: _toStringList(data['examples']),
      skill: (data['skill'] ?? data['category'] ?? '').toString(),
      difficulty: (data['difficulty'] ?? 'Beginner').toString(),
      estimatedMinutes: (data['estimatedMinutes'] is num)
          ? (data['estimatedMinutes'] as num).toInt()
          : 10,
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
      tags: _toStringList(data['tags']),
      targetLevels: _toStringList(data['targetLevels']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
