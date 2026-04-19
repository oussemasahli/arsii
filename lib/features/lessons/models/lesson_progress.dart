import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonProgressStatus {
  notStarted,
  inProgress,
  completed,
}

class LessonProgress {
  final String lessonId;
  final LessonProgressStatus status;
  final double completionPercent;
  final DateTime? lastOpenedAt;
  final DateTime? completedAt;

  const LessonProgress({
    required this.lessonId,
    this.status = LessonProgressStatus.notStarted,
    this.completionPercent = 0,
    this.lastOpenedAt,
    this.completedAt,
  });

  factory LessonProgress.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final lessonId = (data['lessonId'] ?? id).toString();
    final rawStatus = (data['status'] ?? '').toString().toLowerCase();

    LessonProgressStatus status;
    if (rawStatus == 'completed') {
      status = LessonProgressStatus.completed;
    } else if (rawStatus == 'in_progress' || rawStatus == 'inprogress') {
      status = LessonProgressStatus.inProgress;
    } else {
      status = LessonProgressStatus.notStarted;
    }

    final completionPercent = (data['completionPercent'] is num)
      ? ((data['completionPercent'] as num).toDouble().clamp(0.0, 100.0)).toDouble()
      : 0.0;

    return LessonProgress(
      lessonId: lessonId,
      status: status,
      completionPercent: completionPercent,
      lastOpenedAt: (data['lastOpenedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lessonId': lessonId,
        'status': switch (status) {
          LessonProgressStatus.completed => 'completed',
          LessonProgressStatus.inProgress => 'in_progress',
          LessonProgressStatus.notStarted => 'not_started',
        },
        'completionPercent': completionPercent,
        'lastOpenedAt': lastOpenedAt != null ? Timestamp.fromDate(lastOpenedAt!) : null,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };
}
