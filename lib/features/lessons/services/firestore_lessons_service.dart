import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/student_service.dart';
import '../data/lesson_seed_data.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/personalized_lesson.dart';

class FirestoreLessonsService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final StudentService _studentService;

  FirestoreLessonsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StudentService? studentService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _studentService = studentService ?? StudentService();

  Future<PersonalizedLessonsData> getPersonalizedLessons() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No authenticated user.');
    }

    final profile = await _studentService.getProfile();
    if (profile == null) {
      return const PersonalizedLessonsData(
        recommended: [],
        continueLearning: [],
        reviewWeakAreas: [],
      );
    }

    final topicIds = profile.subjects.map((s) => s.id).where((e) => e.isNotEmpty).toList();
    if (topicIds.isEmpty) {
      return const PersonalizedLessonsData(
        recommended: [],
        continueLearning: [],
        reviewWeakAreas: [],
      );
    }

    final lessons = await _loadLessonsForTopics(topicIds);
    if (lessons.isEmpty) {
      return const PersonalizedLessonsData(
        recommended: [],
        continueLearning: [],
        reviewWeakAreas: [],
      );
    }

    final progressMap = await _loadProgress(uid);

    final merged = lessons.map((lesson) {
      final progress = progressMap[lesson.id] ??
          LessonProgress(
            lessonId: lesson.id,
            status: LessonProgressStatus.notStarted,
            completionPercent: 0,
          );
      return _LessonWithProgress(lesson: lesson, progress: progress);
    }).toList();

    final weakSubjects = profile.weakTopics
        .map((w) => w.subject.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final continueLearning = merged
        .where((it) => it.progress.status == LessonProgressStatus.inProgress)
        .toList()
      ..sort((a, b) {
        final aTime = a.progress.lastOpenedAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.progress.lastOpenedAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

    final reviewWeak = merged.where((it) {
      if (it.progress.status == LessonProgressStatus.completed) return false;
      final text = '${it.lesson.skill} ${it.lesson.tags.join(' ')} ${it.lesson.topicId}'.toLowerCase();
      return weakSubjects.any((weak) => weak.isNotEmpty && text.contains(weak));
    }).toList()
      ..sort((a, b) {
        final aProgress = a.progress.completionPercent;
        final bProgress = b.progress.completionPercent;
        return aProgress.compareTo(bProgress);
      });

    final continueIds = continueLearning.map((e) => e.lesson.id).toSet();

    final recommendedCandidates = merged.where((it) {
      if (it.progress.status == LessonProgressStatus.completed) return false;
      if (continueIds.contains(it.lesson.id)) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final aScore = _recommendationScore(
          item: a,
          level: profile.level,
          weakSubjects: weakSubjects,
        );
        final bScore = _recommendationScore(
          item: b,
          level: profile.level,
          weakSubjects: weakSubjects,
        );

        if (aScore != bScore) return bScore.compareTo(aScore);
        return a.lesson.order.compareTo(b.lesson.order);
      });

    String reviewReason(Lesson lesson) {
      final weak = profile.weakTopics.firstWhere(
        (w) {
          final weakSubject = w.subject.toLowerCase();
          final ltext = '${lesson.skill} ${lesson.tags.join(' ')} ${lesson.topicId}'.toLowerCase();
          return ltext.contains(weakSubject);
        },
        orElse: () => const WeakTopic(topic: '', subject: '', score: 0),
      );

      if (weak.subject.isNotEmpty) {
        return 'Focus on one of your weak skills: ${weak.subject}';
      }
      return 'Suggested from your diagnostic results';
    }

    final continueCards = continueLearning
        .take(6)
        .map((it) => PersonalizedLesson(
              lesson: it.lesson,
              progress: it.progress,
              badge: LessonBadge.inProgress,
              reason: 'You started this lesson recently',
            ))
        .toList();

    final reviewCards = reviewWeak
        .take(6)
        .map((it) => PersonalizedLesson(
              lesson: it.lesson,
              progress: it.progress,
              badge: LessonBadge.review,
              reason: reviewReason(it.lesson),
            ))
        .toList();

    final recommendedCards = recommendedCandidates
        .take(8)
        .map((it) => PersonalizedLesson(
              lesson: it.lesson,
              progress: it.progress,
              badge: LessonBadge.recommended,
              reason: 'Suggested from your diagnostic results',
            ))
        .toList();

    return PersonalizedLessonsData(
      recommended: recommendedCards,
      continueLearning: continueCards,
      reviewWeakAreas: reviewCards,
    );
  }

  Future<void> markLessonOpened({
    required Lesson lesson,
    required LessonProgress progress,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = _db.collection('students').doc(uid);
    final progressRef = userDoc.collection('lesson_progress').doc(lesson.id);

    final nextStatus = progress.status == LessonProgressStatus.completed
        ? LessonProgressStatus.completed
        : LessonProgressStatus.inProgress;
    final nextPercent = progress.completionPercent == 0
        ? 5.0
        : progress.completionPercent.clamp(0, 100).toDouble();

    await progressRef.set({
      'lessonId': lesson.id,
      'status': switch (nextStatus) {
        LessonProgressStatus.completed => 'completed',
        LessonProgressStatus.inProgress => 'in_progress',
        LessonProgressStatus.notStarted => 'not_started',
      },
      'completionPercent': nextPercent,
      'lastOpenedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _studentService.updateCurrentLesson(
      subject: lesson.skill.isNotEmpty ? lesson.skill : lesson.topicId,
      title: lesson.title,
      description: lesson.description,
      progress: (nextPercent / 100).clamp(0, 1),
    );
  }

  Future<List<Lesson>> _loadLessonsForTopics(List<String> topicIds) async {
    final all = <Lesson>[];

    for (final topicId in topicIds) {
      final snap = await _db
          .collection('topics')
          .doc(topicId)
          .collection('lessons')
          .orderBy('order')
          .get();

      List<Lesson> items;

      if (snap.docs.isNotEmpty) {
        items = snap.docs
            .map((d) {
              return Lesson.fromMap(
                id: d.id,
                topicId: topicId,
                data: d.data(),
              );
            })
            .where((lesson) => lesson.title.trim().isNotEmpty)
            .toList();
      } else {
        final fallback = LessonSeedData.byTopic[topicId] ?? const [];
        items = fallback
            .asMap()
            .entries
            .map((entry) {
              final data = entry.value;
              final id = (data['id'] ?? '${topicId}_seed_${entry.key + 1}').toString();
              return Lesson.fromMap(
                id: id,
                topicId: topicId,
                data: data,
              );
            })
            .where((lesson) => lesson.title.trim().isNotEmpty)
            .toList();
      }

      all.addAll(items);
    }

    return all;
  }

  Future<Map<String, LessonProgress>> _loadProgress(String uid) async {
    final snap = await _db
        .collection('students')
        .doc(uid)
        .collection('lesson_progress')
        .get();

    final map = <String, LessonProgress>{};
    for (final doc in snap.docs) {
      final progress = LessonProgress.fromMap(id: doc.id, data: doc.data());
      map[progress.lessonId] = progress;
      map[doc.id] = progress;
    }
    return map;
  }

  int _recommendationScore({
    required _LessonWithProgress item,
    required String level,
    required Set<String> weakSubjects,
  }) {
    var score = 0;

    final lesson = item.lesson;
    final text = '${lesson.skill} ${lesson.tags.join(' ')} ${lesson.topicId}'.toLowerCase();

    if (lesson.targetLevels.isEmpty) {
      score += 1;
    } else if (lesson.targetLevels.map((e) => e.toLowerCase()).contains(level.toLowerCase())) {
      score += 3;
    }

    if (weakSubjects.any((weak) => weak.isNotEmpty && text.contains(weak))) {
      score += 2;
    }

    if (item.progress.status == LessonProgressStatus.notStarted) {
      score += 1;
    }

    return score;
  }
}

class _LessonWithProgress {
  final Lesson lesson;
  final LessonProgress progress;

  const _LessonWithProgress({
    required this.lesson,
    required this.progress,
  });
}
