class UserProgress {
  String userId;
  String currentLevel; // A1, A2, B1, B2, C1, C2
  int totalLessonsCompleted;
  int totalHomeworkCompleted;
  int currentStreak; // consecutive days
  int longestStreak;
  int totalXP;
  List<DailyActivity> activityHistory;
  List<String> masteredTopics;
  List<String> weakAreas;
  DateTime lastActiveDate;
  Map<String, int> topicScores; // topic -> average score

  UserProgress({
    required this.userId,
    this.currentLevel = 'A1',
    this.totalLessonsCompleted = 0,
    this.totalHomeworkCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXP = 0,
    List<DailyActivity>? activityHistory,
    List<String>? masteredTopics,
    List<String>? weakAreas,
    DateTime? lastActiveDate,
    Map<String, int>? topicScores,
  })  : activityHistory = activityHistory ?? [],
        masteredTopics = masteredTopics ?? [],
        weakAreas = weakAreas ?? [],
        lastActiveDate = lastActiveDate ?? DateTime.now(),
        topicScores = topicScores ?? {};

  String get levelLabel {
    switch (currentLevel) {
      case 'A1': return 'Beginner';
      case 'A2': return 'Elementary';
      case 'B1': return 'Intermediate';
      case 'B2': return 'Upper Intermediate';
      case 'C1': return 'Advanced';
      case 'C2': return 'Mastery';
      default: return 'Beginner';
    }
  }

  int get xpForNextLevel {
    switch (currentLevel) {
      case 'A1': return 500;
      case 'A2': return 1500;
      case 'B1': return 3000;
      case 'B2': return 6000;
      case 'C1': return 10000;
      default: return 99999;
    }
  }

  double get levelProgress => (totalXP / xpForNextLevel).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentLevel': currentLevel,
        'totalLessonsCompleted': totalLessonsCompleted,
        'totalHomeworkCompleted': totalHomeworkCompleted,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalXP': totalXP,
        'activityHistory': activityHistory.map((a) => a.toJson()).toList(),
        'masteredTopics': masteredTopics,
        'weakAreas': weakAreas,
        'lastActiveDate': lastActiveDate.toIso8601String(),
        'topicScores': topicScores,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        userId: json['userId'],
        currentLevel: json['currentLevel'] ?? 'A1',
        totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
        totalHomeworkCompleted: json['totalHomeworkCompleted'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        longestStreak: json['longestStreak'] ?? 0,
        totalXP: json['totalXP'] ?? 0,
        activityHistory: (json['activityHistory'] as List? ?? [])
            .map((a) => DailyActivity.fromJson(a))
            .toList(),
        masteredTopics: List<String>.from(json['masteredTopics'] ?? []),
        weakAreas: List<String>.from(json['weakAreas'] ?? []),
        lastActiveDate: json['lastActiveDate'] != null
            ? DateTime.parse(json['lastActiveDate'])
            : DateTime.now(),
        topicScores: Map<String, int>.from(json['topicScores'] ?? {}),
      );
}

class DailyActivity {
  final DateTime date;
  final int lessonsCompleted;
  final int homeworkCompleted;
  final int xpEarned;
  final int minutesStudied;

  DailyActivity({
    required this.date,
    required this.lessonsCompleted,
    required this.homeworkCompleted,
    required this.xpEarned,
    required this.minutesStudied,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'lessonsCompleted': lessonsCompleted,
        'homeworkCompleted': homeworkCompleted,
        'xpEarned': xpEarned,
        'minutesStudied': minutesStudied,
      };

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
        date: DateTime.parse(json['date']),
        lessonsCompleted: json['lessonsCompleted'] ?? 0,
        homeworkCompleted: json['homeworkCompleted'] ?? 0,
        xpEarned: json['xpEarned'] ?? 0,
        minutesStudied: json['minutesStudied'] ?? 0,
      );
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  static List<Achievement> allAchievements = [
    Achievement(id: 'first_lesson', title: 'First Step', description: 'Complete your first lesson', emoji: '🎯', xpReward: 50),
    Achievement(id: 'streak_7', title: 'Week Warrior', description: '7-day learning streak', emoji: '🔥', xpReward: 200),
    Achievement(id: 'streak_30', title: 'Monthly Master', description: '30-day learning streak', emoji: '🏆', xpReward: 1000),
    Achievement(id: 'homework_10', title: 'Homework Hero', description: 'Complete 10 homework assignments', emoji: '📝', xpReward: 300),
    Achievement(id: 'perfect_score', title: 'Perfektionist', description: 'Get 100% on a homework', emoji: '⭐', xpReward: 150),
    Achievement(id: 'level_a2', title: 'A2 Unlocked', description: 'Reach A2 level', emoji: '🌟', xpReward: 500),
    Achievement(id: 'level_b1', title: 'B1 Breakthrough', description: 'Reach B1 level', emoji: '💎', xpReward: 1000),
    Achievement(id: 'vocabulary_100', title: 'Word Collector', description: 'Learn 100 German words', emoji: '📚', xpReward: 400),
  ];
}
