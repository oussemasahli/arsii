import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_service.dart';

/// Represents one enrolled subject with the student's current progress.
class StudentSubject {
  final String id;
  final String name;
  final double mastery;        // 0.0 – 1.0
  final int completedLessons;
  final int totalLessons;
  final double evaluationScore; // Initial score from onboarding quiz

  const StudentSubject({
    required this.id,
    required this.name,
    this.mastery = 0.0,
    this.completedLessons = 0,
    this.totalLessons = 20,
    this.evaluationScore = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mastery': mastery,
    'completedLessons': completedLessons,
    'totalLessons': totalLessons,
    'evaluationScore': evaluationScore,
  };

  factory StudentSubject.fromMap(Map<String, dynamic> m) => StudentSubject(
    id: m['id'] ?? '',
    name: m['name'] ?? '',
    mastery: (m['mastery'] ?? 0.0).toDouble(),
    completedLessons: (m['completedLessons'] ?? 0).toInt(),
    totalLessons: (m['totalLessons'] ?? 20).toInt(),
    evaluationScore: (m['evaluationScore'] ?? 0.0).toDouble(),
  );
}

/// A single item in the student's activity feed.
class ActivityItem {
  final String title;
  final String type; // 'completed', 'started', 'quiz', 'read'
  final DateTime timestamp;

  const ActivityItem({
    required this.title,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  factory ActivityItem.fromMap(Map<String, dynamic> m) => ActivityItem(
    title: m['title'] ?? '',
    type: m['type'] ?? 'completed',
    timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

/// A weak topic the student should focus on.
class WeakTopic {
  final String topic;
  final String subject;
  final int score; // percentage 0-100

  const WeakTopic({required this.topic, required this.subject, required this.score});

  Map<String, dynamic> toMap() => {'topic': topic, 'subject': subject, 'score': score};

  factory WeakTopic.fromMap(Map<String, dynamic> m) => WeakTopic(
    topic: m['topic'] ?? '',
    subject: m['subject'] ?? '',
    score: (m['score'] ?? 0).toInt(),
  );
}

/// AI-recommended action for the student.
class Recommendation {
  final String title;
  final String description;
  final String icon; // material icon name hint

  const Recommendation({required this.title, required this.description, this.icon = 'auto_awesome'});

  Map<String, dynamic> toMap() => {'title': title, 'description': description, 'icon': icon};

  factory Recommendation.fromMap(Map<String, dynamic> m) => Recommendation(
    title: m['title'] ?? '',
    description: m['description'] ?? '',
    icon: m['icon'] ?? 'auto_awesome',
  );
}

/// Full student profile stored in Firestore.
class StudentProfile {
  final String uid;
  final String name;
  final String email;
  final String level;           // Beginner / Intermediate / Advanced
  final List<StudentSubject> subjects;
  final List<ActivityItem> recentActivity;
  final List<WeakTopic> weakTopics;
  final List<Recommendation> recommendations;
  final String currentLessonSubject;
  final String currentLessonTitle;
  final String currentLessonDesc;
  final double currentLessonProgress;
  final int streakDays;
  final DateTime? lastActiveAt;
  final bool onboardingComplete;

  const StudentProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.level = 'Beginner',
    this.subjects = const [],
    this.recentActivity = const [],
    this.weakTopics = const [],
    this.recommendations = const [],
    this.currentLessonSubject = '',
    this.currentLessonTitle = '',
    this.currentLessonDesc = '',
    this.currentLessonProgress = 0.0,
    this.streakDays = 0,
    this.lastActiveAt,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'level': level,
    'subjects': subjects.map((s) => s.toMap()).toList(),
    'recentActivity': recentActivity.map((a) => a.toMap()).toList(),
    'weakTopics': weakTopics.map((w) => w.toMap()).toList(),
    'recommendations': recommendations.map((r) => r.toMap()).toList(),
    'currentLessonSubject': currentLessonSubject,
    'currentLessonTitle': currentLessonTitle,
    'currentLessonDesc': currentLessonDesc,
    'currentLessonProgress': currentLessonProgress,
    'streakDays': streakDays,
    'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    'onboardingComplete': onboardingComplete,
  };

  factory StudentProfile.fromMap(Map<String, dynamic> m) => StudentProfile(
    uid: m['uid'] ?? '',
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    level: m['level'] ?? 'Beginner',
    subjects: (m['subjects'] as List<dynamic>?)
        ?.map((s) => StudentSubject.fromMap(s as Map<String, dynamic>))
        .toList() ?? [],
    recentActivity: (m['recentActivity'] as List<dynamic>?)
        ?.map((a) => ActivityItem.fromMap(a as Map<String, dynamic>))
        .toList() ?? [],
    weakTopics: (m['weakTopics'] as List<dynamic>?)
        ?.map((w) => WeakTopic.fromMap(w as Map<String, dynamic>))
        .toList() ?? [],
    recommendations: (m['recommendations'] as List<dynamic>?)
        ?.map((r) => Recommendation.fromMap(r as Map<String, dynamic>))
        .toList() ?? [],
    currentLessonSubject: m['currentLessonSubject'] ?? '',
    currentLessonTitle: m['currentLessonTitle'] ?? '',
    currentLessonDesc: m['currentLessonDesc'] ?? '',
    currentLessonProgress: (m['currentLessonProgress'] ?? 0.0).toDouble(),
    streakDays: (m['streakDays'] ?? 0).toInt(),
    lastActiveAt: (m['lastActiveAt'] as Timestamp?)?.toDate(),
    onboardingComplete: m['onboardingComplete'] ?? false,
  );
}

/// Service for reading/writing student profile data in Firestore.
class StudentService {
  final _db = FirebaseFirestore.instance;
  final _ai = AiService();

  /// Reference to a student's document.
  DocumentReference _doc(String uid) => _db.collection('students').doc(uid);

  /// Get the current user's UID.
  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Fetch the current student's profile. Returns `null` if not found.
  Future<StudentProfile?> getProfile() async {
    final uid = _currentUid;
    if (uid == null) return null;
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return StudentProfile.fromMap(snap.data() as Map<String, dynamic>);
  }

  /// Stream the current student's profile for live updates.
  Stream<StudentProfile?> profileStream() {
    final uid = _currentUid;
    if (uid == null) return Stream.value(null);
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return StudentProfile.fromMap(snap.data() as Map<String, dynamic>);
    });
  }

  /// Check if the current student has completed onboarding.
  Future<bool> isOnboardingComplete() async {
    final p = await getProfile();
    return p?.onboardingComplete ?? false;
  }

  /// Save a full student profile (used after onboarding).
  Future<void> saveProfile(StudentProfile profile) async {
    await _doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Save onboarding results after evaluation quiz completes.
  Future<void> saveOnboardingResults({
    required String level,
    required Map<String, double> subjectScores,
    required List<String> subjectNames,
    required List<String> subjectIds,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Build subject list with scores
    final subjects = <StudentSubject>[];
    for (int i = 0; i < subjectNames.length; i++) {
      final id = i < subjectIds.length ? subjectIds[i] : subjectNames[i].toLowerCase();
      final score = subjectScores[subjectNames[i]] ?? 0.0;
      subjects.add(StudentSubject(
        id: id,
        name: subjectNames[i],
        mastery: score,
        evaluationScore: score,
        completedLessons: 0,
        totalLessons: _totalLessonsFor(id),
      ));
    }

    // Use quick fallback data now — AI will generate better ones in background
    final weakTopics = <WeakTopic>[];
    for (final s in subjects) {
      if (s.evaluationScore < 0.5) {
        weakTopics.addAll(_generateWeakTopics(s));
      }
    }
    final recommendations = _generateRecommendations(subjects, level);

    // Determine first lesson
    final weakest = subjects.reduce((a, b) => a.mastery < b.mastery ? a : b);
    final firstLesson = _firstLessonFor(weakest);

    final profile = StudentProfile(
      uid: user.uid,
      name: user.displayName ?? 'Student',
      email: user.email ?? '',
      level: level,
      subjects: subjects,
      recentActivity: [
        ActivityItem(
          title: 'Completed initial assessment',
          type: 'quiz',
          timestamp: DateTime.now(),
        ),
        ActivityItem(
          title: 'Enrolled in ${subjectNames.length} subjects',
          type: 'started',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
        ActivityItem(
          title: 'Created account',
          type: 'completed',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ],
      weakTopics: weakTopics,
      recommendations: recommendations,
      currentLessonSubject: weakest.name,
      currentLessonTitle: firstLesson['title']!,
      currentLessonDesc: firstLesson['desc']!,
      currentLessonProgress: 0.0,
      streakDays: 1,
      lastActiveAt: DateTime.now(),
      onboardingComplete: true,
    );

    await saveProfile(profile);
  }

  /// Generates AI recommendations + weak topics in the background,
  /// updates Firestore, and returns the refreshed profile.
  Future<StudentProfile?> refreshAiContent() async {
    final uid = _currentUid;
    if (uid == null) return null;
    final profile = await getProfile();
    if (profile == null) return null;

    // Build scores map from profile
    final subjectScores = <String, double>{};
    for (final s in profile.subjects) {
      subjectScores[s.name] = s.evaluationScore;
    }

    var newWeakTopics = profile.weakTopics;
    var newRecs = profile.recommendations;

    try {
      final results = await Future.wait([
        _ai.generateWeakTopics(level: profile.level, subjectScores: subjectScores),
        _ai.generateRecommendations(level: profile.level, subjectScores: subjectScores),
      ]);

      final aiWeakTopics = results[0] as List<Map<String, dynamic>>;
      if (aiWeakTopics.isNotEmpty) {
        newWeakTopics = aiWeakTopics.map((w) => WeakTopic(
          topic: w['topic'] as String,
          subject: w['subject'] as String,
          score: ((w['score'] ?? 30) as int).clamp(10, 49),
        )).toList();
      }

      final aiRecs = results[1] as List<Map<String, String>>;
      if (aiRecs.isNotEmpty) {
        newRecs = aiRecs.map((r) => Recommendation(
          title: r['title']!,
          description: r['description']!,
          icon: r['icon'] ?? 'auto_awesome',
        )).toList();
      }
    } catch (_) {
      // AI failed — keep existing data
      return profile;
    }

    // Update Firestore with AI-generated content
    try {
      await _doc(uid).update({
        'weakTopics': newWeakTopics.map((w) => w.toMap()).toList(),
        'recommendations': newRecs.map((r) => r.toMap()).toList(),
      });
    } catch (_) {}

    // Return updated profile
    return StudentProfile(
      uid: profile.uid,
      name: profile.name,
      email: profile.email,
      level: profile.level,
      subjects: profile.subjects,
      recentActivity: profile.recentActivity,
      weakTopics: newWeakTopics,
      recommendations: newRecs,
      currentLessonSubject: profile.currentLessonSubject,
      currentLessonTitle: profile.currentLessonTitle,
      currentLessonDesc: profile.currentLessonDesc,
      currentLessonProgress: profile.currentLessonProgress,
      streakDays: profile.streakDays,
      lastActiveAt: profile.lastActiveAt,
      onboardingComplete: profile.onboardingComplete,
    );
  }

  /// Record a new activity and update last active timestamp.
  Future<void> addActivity(String title, String type) async {
    final uid = _currentUid;
    if (uid == null) return;
    final profile = await getProfile();
    if (profile == null) return;

    final updatedActivity = [
      ActivityItem(title: title, type: type, timestamp: DateTime.now()),
      ...profile.recentActivity.take(9), // Keep last 10
    ];

    await _doc(uid).update({
      'recentActivity': updatedActivity.map((a) => a.toMap()).toList(),
      'lastActiveAt': Timestamp.now(),
    });
  }

  /// Update mastery for a subject after completing a lesson/exercise.
  Future<void> updateSubjectProgress(String subjectId, {double? mastery, int? completedLessons}) async {
    final uid = _currentUid;
    if (uid == null) return;
    final profile = await getProfile();
    if (profile == null) return;

    final updatedSubjects = profile.subjects.map((s) {
      if (s.id == subjectId) {
        return StudentSubject(
          id: s.id,
          name: s.name,
          mastery: mastery ?? s.mastery,
          completedLessons: completedLessons ?? s.completedLessons,
          totalLessons: s.totalLessons,
          evaluationScore: s.evaluationScore,
        );
      }
      return s;
    }).toList();

    await _doc(uid).update({
      'subjects': updatedSubjects.map((s) => s.toMap()).toList(),
    });
  }

  /// Update the current lesson the student is working on.
  Future<void> updateCurrentLesson({
    required String subject,
    required String title,
    required String description,
    required double progress,
  }) async {
    final uid = _currentUid;
    if (uid == null) return;
    await _doc(uid).update({
      'currentLessonSubject': subject,
      'currentLessonTitle': title,
      'currentLessonDesc': description,
      'currentLessonProgress': progress,
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────

  int _totalLessonsFor(String id) {
    const map = {
      'programming': 24,
      'algorithms': 20,
      'data_structures': 18,
      'databases': 16,
      'web': 22,
    };
    return map[id] ?? 20;
  }

  List<WeakTopic> _generateWeakTopics(StudentSubject s) {
    const topicMap = {
      'programming': [
        {'topic': 'Object-Oriented Concepts', 'base': 35},
        {'topic': 'Error Handling', 'base': 40},
      ],
      'algorithms': [
        {'topic': 'Recursion', 'base': 30},
        {'topic': 'Graph Algorithms', 'base': 38},
      ],
      'data_structures': [
        {'topic': 'Binary Trees', 'base': 32},
        {'topic': 'Hash Tables', 'base': 42},
      ],
      'databases': [
        {'topic': 'SQL JOINs', 'base': 36},
        {'topic': 'Normalization', 'base': 44},
      ],
      'web': [
        {'topic': 'CSS Flexbox & Grid', 'base': 28},
        {'topic': 'JavaScript Async', 'base': 34},
      ],
    };

    final topics = topicMap[s.id] ?? [{'topic': 'Fundamentals', 'base': 35}];
    return topics.map((t) => WeakTopic(
      topic: t['topic'] as String,
      subject: s.name,
      score: ((t['base'] as int) * (0.5 + s.evaluationScore)).clamp(10, 49).toInt(),
    )).toList();
  }

  /// Fallback recommendations — only used if AI call fails.
  /// Generates minimal data-driven recs from the actual scores, no hardcoded templates.
  List<Recommendation> _generateRecommendations(List<StudentSubject> subjects, String level) {
    final recs = <Recommendation>[];
    // Sort by score ascending — weakest first
    final sorted = [...subjects]..sort((a, b) => a.evaluationScore.compareTo(b.evaluationScore));

    for (final s in sorted) {
      if (s.evaluationScore < 0.5) {
        recs.add(Recommendation(
          title: 'Strengthen ${s.name}',
          description: 'You scored ${(s.evaluationScore * 100).toInt()}% — review key concepts and practice exercises.',
          icon: 'refresh',
        ));
      } else if (s.evaluationScore >= 0.7) {
        recs.add(Recommendation(
          title: 'Advance in ${s.name}',
          description: 'Strong at ${(s.evaluationScore * 100).toInt()}% — move on to more challenging material.',
          icon: 'trending_up',
        ));
      }
      if (recs.length >= 3) break;
    }

    if (recs.isEmpty) {
      recs.add(const Recommendation(
        title: 'Keep practicing',
        description: 'Consistent daily practice is the best way to improve.',
        icon: 'auto_awesome',
      ));
    }

    return recs;
  }

  Map<String, String> _firstLessonFor(StudentSubject subject) {
    const lessons = {
      'programming': {
        'title': 'Variables, Types & Operators',
        'desc': 'Learn how data is stored and manipulated in code — the building blocks of every program.',
      },
      'algorithms': {
        'title': 'Introduction to Algorithm Analysis',
        'desc': 'Understand Big-O notation, compare algorithm efficiency, and analyze simple loops.',
      },
      'data_structures': {
        'title': 'Arrays & Linked Lists',
        'desc': 'Compare contiguous vs. node-based storage, learn traversal, insertion, and deletion.',
      },
      'databases': {
        'title': 'Relational Model & SQL Basics',
        'desc': 'Explore tables, keys, and basic SELECT / INSERT / UPDATE queries.',
      },
      'web': {
        'title': 'HTML & CSS Foundations',
        'desc': 'Build your first web page with semantic markup and modern styling.',
      },
    };
    return lessons[subject.id] ?? {'title': 'Getting Started', 'desc': 'Begin your learning journey with foundational concepts.'};
  }
}
