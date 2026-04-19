import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/lessons/models/lesson.dart';
import '../../features/lessons/models/tutor_message.dart';
import 'ai_service.dart';
import 'student_service.dart';

class AiTutorService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final AiService _aiService;
  final StudentService _studentService;

  AiTutorService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AiService? aiService,
    StudentService? studentService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _aiService = aiService ?? AiService(),
        _studentService = studentService ?? StudentService();

  String? get _uid => _auth.currentUser?.uid;

  Future<List<TutorMessage>> loadMessages({String? lessonId, int limit = 30}) async {
    final uid = _uid;
    if (uid == null) return const [];

    // Keep query index-safe: only order by createdAt and filter lesson locally.
    final query = _db
        .collection('students')
        .doc(uid)
        .collection('tutor_messages')
        .orderBy('createdAt', descending: true)
        .limit(limit * 3);

    final snap = await query.get();
    final filtered = snap.docs.where((doc) {
      if (lessonId == null || lessonId.trim().isEmpty) return true;
      return (doc.data()['lessonId'] ?? '').toString() == lessonId;
    });

    return filtered
        .map((doc) => TutorMessage.fromMap(id: doc.id, data: doc.data()))
        .take(limit)
        .toList()
        .reversed
        .toList();
  }

  Future<TutorMessage> askTutor({
    required Lesson lesson,
    required String userMessage,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return TutorMessage(
        id: 'local_error',
        role: TutorRole.tutor,
        text: 'Please sign in to use AI Tutor.',
        createdAt: DateTime.now(),
      );
    }

    final student = await _studentService.getProfile();
    final weakSkills = student?.weakTopics.map((e) => e.topic).take(4).toList() ?? const <String>[];

    // Avoid composite index requirement by filtering correctness client-side.
    final mistakesSnap = await _db
        .collection('students')
        .doc(uid)
        .collection('exercise_attempts')
        .orderBy('createdAt', descending: true)
      .limit(20)
        .get();

    final mistakes = mistakesSnap.docs
      .where((e) => e.data()['isCorrect'] == false)
        .map((e) => (e.data()['question'] ?? '').toString())
        .where((e) => e.trim().isNotEmpty)
      .take(4)
        .toList();

    final progressSummary = 'Level: ${student?.level ?? lesson.difficulty}, '
        'streak: ${student?.streakDays ?? 0} days, '
        'current lesson progress: ${(student?.currentLessonProgress ?? 0) * 100}%';

    final reply = await _aiService.generateTutorReply(
      userMessage: userMessage,
      currentTopic: lesson.topicId,
      currentLesson: lesson.title,
      lessonSummary: lesson.content,
      studentLevel: student?.level ?? lesson.difficulty,
      weakSkills: weakSkills,
      recentMistakes: mistakes,
      progressSummary: progressSummary,
    );

    final now = DateTime.now();
    final userDoc = _db.collection('students').doc(uid).collection('tutor_messages').doc();
    final tutorDoc = _db.collection('students').doc(uid).collection('tutor_messages').doc();

    await _db.runTransaction((tx) async {
      tx.set(userDoc, {
        'lessonId': lesson.id,
        'topicId': lesson.topicId,
        'role': 'user',
        'text': userMessage,
        'createdAt': Timestamp.fromDate(now),
      });
      tx.set(tutorDoc, {
        'lessonId': lesson.id,
        'topicId': lesson.topicId,
        'role': 'tutor',
        'text': reply,
        'createdAt': Timestamp.fromDate(now.add(const Duration(milliseconds: 1))),
      });
    });

    return TutorMessage(
      id: tutorDoc.id,
      role: TutorRole.tutor,
      text: reply,
      createdAt: now,
    );
  }
}
