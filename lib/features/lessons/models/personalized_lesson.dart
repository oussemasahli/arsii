import 'lesson.dart';
import 'lesson_progress.dart';

enum LessonBadge {
  recommended,
  inProgress,
  review,
}

class PersonalizedLesson {
  final Lesson lesson;
  final LessonProgress progress;
  final LessonBadge badge;
  final String reason;

  const PersonalizedLesson({
    required this.lesson,
    required this.progress,
    required this.badge,
    this.reason = '',
  });

  String get badgeLabel => switch (badge) {
        LessonBadge.recommended => 'Recommended',
        LessonBadge.inProgress => 'In Progress',
        LessonBadge.review => 'Review',
      };
}

class PersonalizedLessonsData {
  final List<PersonalizedLesson> recommended;
  final List<PersonalizedLesson> continueLearning;
  final List<PersonalizedLesson> reviewWeakAreas;

  const PersonalizedLessonsData({
    required this.recommended,
    required this.continueLearning,
    required this.reviewWeakAreas,
  });

  bool get isEmpty =>
      recommended.isEmpty && continueLearning.isEmpty && reviewWeakAreas.isEmpty;
}
