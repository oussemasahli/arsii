enum ExerciseType {
  multipleChoice,
  trueFalse,
  shortAnswer,
}

class ExerciseOption {
  final String id;
  final String text;

  const ExerciseOption({
    required this.id,
    required this.text,
  });

  factory ExerciseOption.fromMap(Map<String, dynamic> data) {
    return ExerciseOption(
      id: (data['id'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
    };
  }
}

class Exercise {
  final String id;
  final String lessonId;
  final String topicId;
  final String skill;
  final ExerciseType type;
  final String question;
  final List<ExerciseOption> options;
  final String correctAnswer;
  final String explanation;
  final int difficulty;

  const Exercise({
    required this.id,
    required this.lessonId,
    required this.topicId,
    required this.skill,
    required this.type,
    required this.question,
    this.options = const [],
    this.correctAnswer = '',
    this.explanation = '',
    this.difficulty = 1,
  });

  factory Exercise.fromMap({
    required String id,
    required String lessonId,
    required String topicId,
    required Map<String, dynamic> data,
  }) {
    return Exercise(
      id: id,
      lessonId: (data['lessonId'] ?? lessonId).toString(),
      topicId: (data['topicId'] ?? topicId).toString(),
      skill: (data['skill'] ?? '').toString(),
      type: _parseType((data['type'] ?? 'multiple_choice').toString()),
      question: (data['question'] ?? '').toString(),
      options: _toOptions(data['options']),
      correctAnswer: (data['correctAnswer'] ?? '').toString(),
      explanation: (data['explanation'] ?? '').toString(),
      difficulty: (data['difficulty'] is num)
          ? (data['difficulty'] as num).toInt().clamp(1, 5)
          : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'topicId': topicId,
      'skill': skill,
      'type': _typeToValue(type),
      'question': question,
      'options': options.map((e) => e.toMap()).toList(),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  static ExerciseType _parseType(String raw) {
    final value = raw.toLowerCase().trim();
    if (value == 'true_false' || value == 'truefalse') {
      return ExerciseType.trueFalse;
    }
    if (value == 'short_answer' || value == 'shortanswer') {
      return ExerciseType.shortAnswer;
    }
    return ExerciseType.multipleChoice;
  }

  static String _typeToValue(ExerciseType type) {
    return switch (type) {
      ExerciseType.multipleChoice => 'multiple_choice',
      ExerciseType.trueFalse => 'true_false',
      ExerciseType.shortAnswer => 'short_answer',
    };
  }

  static List<ExerciseOption> _toOptions(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => ExerciseOption.fromMap(Map<String, dynamic>.from(entry)))
        .where((entry) => entry.text.trim().isNotEmpty)
        .toList();
  }
}
