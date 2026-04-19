import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/exercises/models/exercise_attempt.dart';
import '../../features/progress/models/user_progress_summary.dart';
import 'student_service.dart';

class FirestoreProgressService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final StudentService _studentService;

  FirestoreProgressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StudentService? studentService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _studentService = studentService ?? StudentService();

  String? get _uid => _auth.currentUser?.uid;

  Future<UserProgressSummary?> getSummary() async {
    final uid = _uid;
    if (uid == null) return null;

    final student = await _studentService.getProfile();
    if (student == null) return null;

    final progressSnap = await _db
        .collection('students')
        .doc(uid)
        .collection('lesson_progress')
        .get();

    final attemptsSnap = await _db
        .collection('students')
        .doc(uid)
        .collection('exercise_attempts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final attempts = attemptsSnap.docs
        .map((doc) => ExerciseAttempt.fromMap(id: doc.id, data: doc.data()))
        .toList();

    final completedLessons = progressSnap.docs
        .where((doc) => (doc.data()['status'] ?? '').toString() == 'completed')
        .length;
    final attemptedLessons = progressSnap.docs.length;

    final totalLessons = student.subjects.fold<int>(0, (sum, s) => sum + s.totalLessons);
    final completion = totalLessons == 0 ? 0.0 : completedLessons / totalLessons;

    final correct = attempts.where((a) => a.isCorrect).length;
    final accuracy = attempts.isEmpty ? 0.0 : correct / attempts.length;

    final skillAggregate = <String, List<double>>{};
    final mistakesBySkill = <String, int>{};

    for (final attempt in attempts) {
      final skill = attempt.skill.trim().isEmpty ? 'General' : attempt.skill.trim();
      skillAggregate.putIfAbsent(skill, () => <double>[]).add(attempt.score);
      if (!attempt.isCorrect) {
        mistakesBySkill[skill] = (mistakesBySkill[skill] ?? 0) + 1;
      }
    }

    final masteryBySkill = skillAggregate.entries.map((entry) {
      final scores = entry.value;
      final avg = scores.fold<double>(0, (sum, v) => sum + v) / scores.length;
      return SkillMastery(skill: entry.key, mastery: avg);
    }).toList()
      ..sort((a, b) => b.mastery.compareTo(a.mastery));

    final weakAreas = mistakesBySkill.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final weakestSkill = weakAreas.isNotEmpty
        ? weakAreas.first.key
        : (student.weakTopics.isNotEmpty ? student.weakTopics.first.topic : 'None yet');

    final strongestSkill = masteryBySkill.isNotEmpty ? masteryBySkill.first.skill : 'N/A';
    final reviewNext = weakestSkill == 'None yet'
        ? 'Continue your current learning path'
        : 'Review $weakestSkill with focused practice';

    final trend = _buildTrend(attempts);

    final recommendedLesson = student.currentLessonTitle.trim().isNotEmpty
        ? student.currentLessonTitle
        : 'Continue your recommended lessons';

    final summary = UserProgressSummary(
      completionPercentage: completion,
      lessonsCompleted: completedLessons,
      lessonsAttempted: attemptedLessons,
      exercisesAttempted: attempts.length,
      accuracyRate: accuracy,
      currentLevel: student.level,
      learningStreak: student.streakDays,
      recommendedNextLesson: recommendedLesson,
      weakAreas: weakAreas.take(4).map((e) => e.key).toList(),
      masteryBySkill: masteryBySkill,
      recentActivity: attempts.take(10).toList(),
      insight: ProgressInsight(
        strongestSkill: strongestSkill,
        weakestSkill: weakestSkill,
        reviewNext: reviewNext,
        trend: trend,
      ),
    );

    await _db.collection('students').doc(uid).collection('progress_summary').doc('main').set({
      'completionPercentage': summary.completionPercentage,
      'lessonsCompleted': summary.lessonsCompleted,
      'lessonsAttempted': summary.lessonsAttempted,
      'exercisesAttempted': summary.exercisesAttempted,
      'accuracyRate': summary.accuracyRate,
      'currentLevel': summary.currentLevel,
      'learningStreak': summary.learningStreak,
      'recommendedNextLesson': summary.recommendedNextLesson,
      'weakAreas': summary.weakAreas,
      'masteryBySkill': summary.masteryBySkill
          .map((s) => {'skill': s.skill, 'mastery': s.mastery})
          .toList(),
      'insight': {
        'strongestSkill': summary.insight.strongestSkill,
        'weakestSkill': summary.insight.weakestSkill,
        'reviewNext': summary.insight.reviewNext,
        'trend': summary.insight.trend,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return summary;
  }

  String _buildTrend(List<ExerciseAttempt> attempts) {
    if (attempts.length < 6) {
      return 'Keep practicing to unlock trend insights.';
    }

    final recent = attempts.take(5).toList();
    final older = attempts.skip(5).take(5).toList();

    final recentAvg = recent.fold<double>(0, (sum, a) => sum + a.score) / recent.length;
    final olderAvg = older.fold<double>(0, (sum, a) => sum + a.score) / older.length;

    if (recentAvg > olderAvg + 0.08) {
      return 'Improving: your latest answers are stronger than earlier attempts.';
    }
    if (recentAvg + 0.08 < olderAvg) {
      return 'Momentum dipped recently. Revisit weak concepts for a quick recovery.';
    }
    return 'Stable performance. Push with slightly harder exercises.';
  }
}
