import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise.dart';

class ExerciseEvaluation {
  final bool isCorrect;
  final double score;
  final String explanation;
  final String feedback;

  const ExerciseEvaluation({
    required this.isCorrect,
    required this.score,
    required this.explanation,
    required this.feedback,
  });
}

class ExerciseAttempt {
  final String id;
  final String sessionId;
  final String lessonId;
  final String topicId;
  final String questionId;
  final String question;
  final ExerciseType type;
  final String skill;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final double score;
  final String explanation;
  final DateTime createdAt;

  const ExerciseAttempt({
    required this.id,
    required this.sessionId,
    required this.lessonId,
    required this.topicId,
    required this.questionId,
    required this.question,
    required this.type,
    required this.skill,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.score,
    required this.explanation,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'lessonId': lessonId,
      'topicId': topicId,
      'questionId': questionId,
      'question': question,
      'type': switch (type) {
        ExerciseType.multipleChoice => 'multiple_choice',
        ExerciseType.trueFalse => 'true_false',
        ExerciseType.shortAnswer => 'short_answer',
      },
      'skill': skill,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'score': score,
      'explanation': explanation,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExerciseAttempt.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    return ExerciseAttempt(
      id: id,
      sessionId: (data['sessionId'] ?? '').toString(),
      lessonId: (data['lessonId'] ?? '').toString(),
      topicId: (data['topicId'] ?? '').toString(),
      questionId: (data['questionId'] ?? '').toString(),
      question: (data['question'] ?? '').toString(),
      type: type == 'true_false'
          ? ExerciseType.trueFalse
          : type == 'short_answer'
              ? ExerciseType.shortAnswer
              : ExerciseType.multipleChoice,
      skill: (data['skill'] ?? '').toString(),
      correctAnswer: (data['correctAnswer'] ?? '').toString(),
      userAnswer: (data['userAnswer'] ?? '').toString(),
      isCorrect: data['isCorrect'] == true,
      score: (data['score'] is num) ? (data['score'] as num).toDouble() : 0,
      explanation: (data['explanation'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ExerciseSessionResult {
  final String sessionId;
  final String lessonId;
  final String topicId;
  final int totalQuestions;
  final int correctAnswers;
  final double totalScore;
  final Map<String, int> mistakesByConcept;
  final List<String> weakAreas;
  final String recommendedNextAction;

  const ExerciseSessionResult({
    required this.sessionId,
    required this.lessonId,
    required this.topicId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalScore,
    required this.mistakesByConcept,
    required this.weakAreas,
    required this.recommendedNextAction,
  });

  double get accuracy => totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
}
