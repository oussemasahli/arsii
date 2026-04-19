import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/exercises/models/exercise.dart';
import '../../features/exercises/models/exercise_attempt.dart';
import '../../features/lessons/models/lesson.dart';
import 'ai_service.dart';
import 'student_service.dart';

class ExerciseService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final AiService _aiService;
  final StudentService _studentService;

  ExerciseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AiService? aiService,
    StudentService? studentService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _aiService = aiService ?? AiService(),
        _studentService = studentService ?? StudentService();

  String? get _uid => _auth.currentUser?.uid;

  Future<List<Exercise>> loadExercisesForLesson({
    required Lesson lesson,
    int minCount = 5,
  }) async {
    final firestoreExercises = await _loadFirestoreExercises(lesson: lesson);
    if (firestoreExercises.length >= minCount) {
      return firestoreExercises.take(minCount).toList();
    }

    final profile = await _studentService.getProfile();
    final weakSkills = profile?.weakTopics.map((e) => e.topic).toList() ?? const <String>[];
    final mistakes = await _loadRecentMistakes(limit: 6);

    final aiExercises = await _aiService.generateAdaptiveExercises(
      lessonTitle: lesson.title,
      lessonContent: lesson.content,
      topic: lesson.topicId,
      studentLevel: profile?.level ?? lesson.difficulty,
      weakSkills: weakSkills,
      previousMistakes: mistakes,
      count: max(minCount, 6),
    );

    final mapped = aiExercises.asMap().entries.map((entry) {
      final e = entry.value;
      return Exercise(
        id: 'ai_${lesson.id}_${entry.key + 1}',
        lessonId: lesson.id,
        topicId: lesson.topicId,
        skill: e.skill.trim().isEmpty ? lesson.skill : e.skill,
        type: _parseExerciseType(e.type),
        question: e.question,
        options: _buildOptions(e),
        correctAnswer: e.correctAnswer,
        explanation: e.explanation,
        difficulty: e.difficulty,
      );
    }).where((e) => e.question.trim().isNotEmpty).toList();

    if (mapped.isEmpty) {
      return _fallbackTemplateExercises(lesson);
    }

    final merged = [...firestoreExercises, ...mapped];
    return merged.take(minCount).toList();
  }

  Future<ExerciseEvaluation> evaluateAnswer({
    required Exercise exercise,
    required String userAnswer,
    required Lesson lesson,
  }) async {
    if (exercise.type == ExerciseType.shortAnswer) {
      final profile = await _studentService.getProfile();
      final aiEval = await _aiService.evaluateShortAnswer(
        question: exercise.question,
        expectedAnswer: exercise.correctAnswer,
        studentAnswer: userAnswer,
        lessonContext: lesson.content,
        studentLevel: profile?.level ?? lesson.difficulty,
      );
      return ExerciseEvaluation(
        isCorrect: aiEval.isCorrect,
        score: aiEval.score,
        explanation: aiEval.explanation,
        feedback: aiEval.personalizedFeedback,
      );
    }

    final expected = exercise.correctAnswer.trim().toLowerCase();
    final actual = userAnswer.trim().toLowerCase();
    final isCorrect = expected == actual;

    return ExerciseEvaluation(
      isCorrect: isCorrect,
      score: isCorrect ? 1.0 : 0.0,
      explanation: exercise.explanation.isNotEmpty
          ? exercise.explanation
          : (isCorrect
              ? 'Correct. Great job applying the concept.'
              : 'Not quite. Re-check the key concept in this lesson.'),
      feedback: isCorrect
          ? 'Nice work. You are building momentum.'
          : 'You are close. Focus on the concept and try the next question.',
    );
  }

  Future<String> getHint({
    required Exercise exercise,
    required Lesson lesson,
  }) async {
    final profile = await _studentService.getProfile();
    return _aiService.generateExerciseHint(
      question: exercise.question,
      lessonTitle: lesson.title,
      lessonContext: lesson.content,
      studentLevel: profile?.level ?? lesson.difficulty,
    );
  }

  Future<void> saveAttempt({
    required String sessionId,
    required Exercise exercise,
    required String userAnswer,
    required ExerciseEvaluation evaluation,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final attemptRef = _db.collection('students').doc(uid).collection('exercise_attempts').doc();
    final attempt = ExerciseAttempt(
      id: attemptRef.id,
      sessionId: sessionId,
      lessonId: exercise.lessonId,
      topicId: exercise.topicId,
      questionId: exercise.id,
      question: exercise.question,
      type: exercise.type,
      skill: exercise.skill,
      correctAnswer: exercise.correctAnswer,
      userAnswer: userAnswer,
      isCorrect: evaluation.isCorrect,
      score: evaluation.score,
      explanation: evaluation.explanation,
      createdAt: DateTime.now(),
    );

    await attemptRef.set(attempt.toMap());

    await _db.collection('students').doc(uid).collection('exercise_sessions').doc(sessionId).set({
      'sessionId': sessionId,
      'lessonId': exercise.lessonId,
      'topicId': exercise.topicId,
      'lastSkill': exercise.skill,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveSessionResult(ExerciseSessionResult result) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection('students').doc(uid).collection('exercise_sessions').doc(result.sessionId).set({
      'sessionId': result.sessionId,
      'lessonId': result.lessonId,
      'topicId': result.topicId,
      'totalQuestions': result.totalQuestions,
      'correctAnswers': result.correctAnswers,
      'totalScore': result.totalScore,
      'accuracy': result.accuracy,
      'mistakesByConcept': result.mistakesByConcept,
      'weakAreas': result.weakAreas,
      'recommendedNextAction': result.recommendedNextAction,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final mastery = result.accuracy;
    await _studentService.updateSubjectProgress(
      result.topicId,
      mastery: mastery,
    );

    final progressPercent = result.accuracy >= 0.85 ? 100.0 : (30 + result.accuracy * 60);

    await _db.collection('students').doc(uid).collection('lesson_progress').doc(result.lessonId).set({
      'lessonId': result.lessonId,
      'status': result.accuracy >= 0.85 ? 'completed' : 'in_progress',
      'completionPercent': progressPercent.clamp(5.0, 100.0),
      'lastOpenedAt': FieldValue.serverTimestamp(),
      if (result.accuracy >= 0.85) 'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _studentService.addActivity(
      'Completed exercises for ${result.lessonId} (${(result.accuracy * 100).round()}%)',
      'quiz',
    );
  }

  Future<List<Exercise>> _loadFirestoreExercises({required Lesson lesson}) async {
    final snap = await _db
        .collection('topics')
        .doc(lesson.topicId)
        .collection('lessons')
        .doc(lesson.id)
        .collection('exercises')
        .get();

    return snap.docs
        .map((doc) => Exercise.fromMap(
              id: doc.id,
              lessonId: lesson.id,
              topicId: lesson.topicId,
              data: doc.data(),
            ))
        .where((e) => e.question.trim().isNotEmpty)
        .toList();
  }

  Future<List<String>> _loadRecentMistakes({int limit = 5}) async {
    final uid = _uid;
    if (uid == null) return const [];

    // Avoid composite index requirement by filtering correctness client-side.
    final snap = await _db
        .collection('students')
        .doc(uid)
        .collection('exercise_attempts')
        .orderBy('createdAt', descending: true)
      .limit(limit * 4)
        .get();

    return snap.docs
      .where((d) => d.data()['isCorrect'] == false)
      .map((d) => (d.data()['skill'] ?? '').toString())
        .where((s) => s.trim().isNotEmpty)
      .take(limit)
        .toList();
  }

  ExerciseType _parseExerciseType(String raw) {
    final value = raw.toLowerCase().trim();
    if (value == 'true_false' || value == 'truefalse') return ExerciseType.trueFalse;
    if (value == 'short_answer' || value == 'shortanswer') return ExerciseType.shortAnswer;
    return ExerciseType.multipleChoice;
  }

  List<ExerciseOption> _buildOptions(AiGeneratedExercise exercise) {
    if (exercise.type == 'short_answer') return const [];
    if (exercise.options.isNotEmpty) {
      return exercise.options
          .asMap()
          .entries
          .map((entry) => ExerciseOption(
                id: String.fromCharCode(65 + entry.key),
                text: entry.value,
              ))
          .toList();
    }
    if (exercise.type == 'true_false') {
      return const [
        ExerciseOption(id: 'A', text: 'True'),
        ExerciseOption(id: 'B', text: 'False'),
      ];
    }
    return const [];
  }

  List<Exercise> _fallbackTemplateExercises(Lesson lesson) {
    return [
      Exercise(
        id: 'fallback_${lesson.id}_1',
        lessonId: lesson.id,
        topicId: lesson.topicId,
        skill: lesson.skill,
        type: ExerciseType.multipleChoice,
        question: 'Which statement best summarizes ${lesson.title}?',
        options: [
          const ExerciseOption(id: 'A', text: 'It focuses on core principles and correct usage'),
          const ExerciseOption(id: 'B', text: 'It is mainly about memorizing syntax without understanding'),
          const ExerciseOption(id: 'C', text: 'It is unrelated to practical problem solving'),
          const ExerciseOption(id: 'D', text: 'It should only be learned after advanced topics'),
        ],
        correctAnswer: 'It focuses on core principles and correct usage',
        explanation: 'The lesson introduces fundamentals and how to apply them correctly.',
      ),
      Exercise(
        id: 'fallback_${lesson.id}_2',
        lessonId: lesson.id,
        topicId: lesson.topicId,
        skill: lesson.skill,
        type: ExerciseType.trueFalse,
        question: 'True or False: Understanding the key concepts helps reduce future mistakes.',
        options: const [
          ExerciseOption(id: 'A', text: 'True'),
          ExerciseOption(id: 'B', text: 'False'),
        ],
        correctAnswer: 'True',
        explanation: 'Strong conceptual understanding improves reasoning and transfer.',
      ),
      Exercise(
        id: 'fallback_${lesson.id}_3',
        lessonId: lesson.id,
        topicId: lesson.topicId,
        skill: lesson.skill,
        type: ExerciseType.shortAnswer,
        question: 'In 1-2 sentences, explain one key concept from this lesson in your own words.',
        correctAnswer: lesson.keyConcepts.isNotEmpty ? lesson.keyConcepts.first : lesson.title,
        explanation: 'A concise explanation should show understanding, not memorization.',
      ),
      Exercise(
        id: 'fallback_${lesson.id}_4',
        lessonId: lesson.id,
        topicId: lesson.topicId,
        skill: lesson.skill,
        type: ExerciseType.multipleChoice,
        question: 'Which action is most helpful when you get stuck on this topic?',
        options: const [
          ExerciseOption(id: 'A', text: 'Review the key concept and test it with a tiny example'),
          ExerciseOption(id: 'B', text: 'Skip all exercises'),
          ExerciseOption(id: 'C', text: 'Memorize answers only'),
          ExerciseOption(id: 'D', text: 'Ignore explanations after mistakes'),
        ],
        correctAnswer: 'Review the key concept and test it with a tiny example',
        explanation: 'Small deliberate practice loops improve learning quality quickly.',
      ),
      Exercise(
        id: 'fallback_${lesson.id}_5',
        lessonId: lesson.id,
        topicId: lesson.topicId,
        skill: lesson.skill,
        type: ExerciseType.trueFalse,
        question: 'True or False: Practice with feedback is important for mastery.',
        options: const [
          ExerciseOption(id: 'A', text: 'True'),
          ExerciseOption(id: 'B', text: 'False'),
        ],
        correctAnswer: 'True',
        explanation: 'Feedback helps correct misconceptions and improve accuracy.',
      ),
    ];
  }
}
