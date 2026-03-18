import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson.dart';
import '../models/homework.dart';
import '../models/progress.dart';

class StorageService {
  static const String _progressKey = 'user_progress';
  static const String _lessonsKey = 'lessons';
  static const String _homeworkKey = 'homework_list';
  static const String _apiKeyKey = 'anthropic_api_key';
  static const String _onboardingKey = 'onboarding_complete';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ── API Key ───────────────────────────────────────────────────────────────

  Future<void> saveApiKey(String key) async {
    await _prefs.setString(_apiKeyKey, key);
  }

  String? getApiKey() => _prefs.getString(_apiKeyKey);

  bool get hasApiKey => (_prefs.getString(_apiKeyKey) ?? '').isNotEmpty;

  // ── Onboarding ────────────────────────────────────────────────────────────

  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  bool get isOnboardingComplete => _prefs.getBool(_onboardingKey) ?? false;

  // ── Progress ──────────────────────────────────────────────────────────────

  Future<UserProgress> getProgress() async {
    final json = _prefs.getString(_progressKey);
    if (json == null) {
      return UserProgress(userId: 'local_user');
    }
    try {
      return UserProgress.fromJson(jsonDecode(json));
    } catch (_) {
      return UserProgress(userId: 'local_user');
    }
  }

  Future<void> saveProgress(UserProgress progress) async {
    await _prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  Future<void> addXP(int xp) async {
    final progress = await getProgress();
    progress.totalXP += xp;
    _updateLevel(progress);
    await saveProgress(progress);
  }

  void _updateLevel(UserProgress progress) {
    if (progress.totalXP >= 10000) {
      progress.currentLevel = 'C1';
    } else if (progress.totalXP >= 6000) {
      progress.currentLevel = 'B2';
    } else if (progress.totalXP >= 3000) {
      progress.currentLevel = 'B1';
    } else if (progress.totalXP >= 1500) {
      progress.currentLevel = 'A2';
    } else {
      progress.currentLevel = 'A1';
    }
  }

  Future<void> updateStreak() async {
    final progress = await getProgress();
    final now = DateTime.now();
    final last = progress.lastActiveDate;
    final daysDiff = now.difference(last).inDays;

    if (daysDiff == 1) {
      // Consecutive day
      progress.currentStreak++;
      if (progress.currentStreak > progress.longestStreak) {
        progress.longestStreak = progress.currentStreak;
      }
    } else if (daysDiff > 1) {
      // Streak broken
      progress.currentStreak = 1;
    }
    // Same day: no change to streak

    progress.lastActiveDate = now;
    await saveProgress(progress);
  }

  Future<void> recordActivity({
    int lessonsCompleted = 0,
    int homeworkCompleted = 0,
    int xpEarned = 0,
    int minutesStudied = 0,
  }) async {
    final progress = await getProgress();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    // Find or create today's activity
    final existingIndex = progress.activityHistory.indexWhere((a) {
      final d = a.date;
      return '${d.year}-${d.month}-${d.day}' == todayStr;
    });

    if (existingIndex >= 0) {
      final existing = progress.activityHistory[existingIndex];
      progress.activityHistory[existingIndex] = DailyActivity(
        date: existing.date,
        lessonsCompleted: existing.lessonsCompleted + lessonsCompleted,
        homeworkCompleted: existing.homeworkCompleted + homeworkCompleted,
        xpEarned: existing.xpEarned + xpEarned,
        minutesStudied: existing.minutesStudied + minutesStudied,
      );
    } else {
      progress.activityHistory.add(DailyActivity(
        date: today,
        lessonsCompleted: lessonsCompleted,
        homeworkCompleted: homeworkCompleted,
        xpEarned: xpEarned,
        minutesStudied: minutesStudied,
      ));
    }

    progress.totalLessonsCompleted += lessonsCompleted;
    progress.totalHomeworkCompleted += homeworkCompleted;
    progress.totalXP += xpEarned;
    _updateLevel(progress);

    // Keep only last 60 days
    if (progress.activityHistory.length > 60) {
      progress.activityHistory = progress.activityHistory.sublist(
        progress.activityHistory.length - 60,
      );
    }

    await saveProgress(progress);
  }

  // ── Lessons ───────────────────────────────────────────────────────────────

  Future<List<Lesson>> getLessons() async {
    final json = _prefs.getString(_lessonsKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((l) => Lesson.fromJson(l)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  Future<Lesson?> getTodaysLesson() async {
    final lessons = await getLessons();
    if (lessons.isEmpty) return null;
    final today = DateTime.now();
    for (final l in lessons) {
      if (l.date.year == today.year &&
          l.date.month == today.month &&
          l.date.day == today.day) {
        return l;
      }
    }
    return null;
  }

  Future<void> saveLesson(Lesson lesson) async {
    final lessons = await getLessons();
    final existingIndex = lessons.indexWhere((l) => l.id == lesson.id);
    if (existingIndex >= 0) {
      lessons[existingIndex] = lesson;
    } else {
      lessons.insert(0, lesson);
    }
    // Keep only last 30 lessons
    final toSave = lessons.take(30).toList();
    await _prefs.setString(
        _lessonsKey, jsonEncode(toSave.map((l) => l.toJson()).toList()));
  }

  // ── Homework ──────────────────────────────────────────────────────────────

  Future<List<Homework>> getAllHomework() async {
    final json = _prefs.getString(_homeworkKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((h) => Homework.fromJson(h)).toList()
        ..sort((a, b) => b.assignedDate.compareTo(a.assignedDate));
    } catch (_) {
      return [];
    }
  }

  Future<Homework?> getHomeworkForLesson(String lessonId) async {
    final all = await getAllHomework();
    try {
      return all.firstWhere((h) => h.lessonId == lessonId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHomework(Homework homework) async {
    final all = await getAllHomework();
    final existingIndex = all.indexWhere((h) => h.id == homework.id);
    if (existingIndex >= 0) {
      all[existingIndex] = homework;
    } else {
      all.insert(0, homework);
    }
    await _prefs.setString(
        _homeworkKey, jsonEncode(all.map((h) => h.toJson()).toList()));
  }
}
