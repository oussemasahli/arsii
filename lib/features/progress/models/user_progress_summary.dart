import '../../exercises/models/exercise_attempt.dart';

class SkillMastery {
  final String skill;
  final double mastery;

  const SkillMastery({
    required this.skill,
    required this.mastery,
  });
}

class ProgressInsight {
  final String strongestSkill;
  final String weakestSkill;
  final String reviewNext;
  final String trend;

  const ProgressInsight({
    required this.strongestSkill,
    required this.weakestSkill,
    required this.reviewNext,
    required this.trend,
  });
}

class UserProgressSummary {
  final double completionPercentage;
  final int lessonsCompleted;
  final int lessonsAttempted;
  final int exercisesAttempted;
  final double accuracyRate;
  final String currentLevel;
  final int learningStreak;
  final String recommendedNextLesson;
  final List<String> weakAreas;
  final List<SkillMastery> masteryBySkill;
  final List<ExerciseAttempt> recentActivity;
  final ProgressInsight insight;

  const UserProgressSummary({
    required this.completionPercentage,
    required this.lessonsCompleted,
    required this.lessonsAttempted,
    required this.exercisesAttempted,
    required this.accuracyRate,
    required this.currentLevel,
    required this.learningStreak,
    required this.recommendedNextLesson,
    required this.weakAreas,
    required this.masteryBySkill,
    required this.recentActivity,
    required this.insight,
  });

  String get statusBadge {
    if (accuracyRate >= 0.8 && completionPercentage >= 0.7) return 'Advanced';
    if (accuracyRate >= 0.55 || completionPercentage >= 0.4) return 'Intermediate';
    return 'Beginner';
  }
}
