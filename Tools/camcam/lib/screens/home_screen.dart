import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/progress.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'lesson_screen.dart';
import 'homework_screen.dart';
import 'progress_screen.dart';
import 'resources_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;
  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Lesson? _todaysLesson;
  UserProgress? _progress;
  String _motivationalMessage = '';
  bool _isLoadingLesson = false;
  bool _isLoadingMotivation = false;
  late AIService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService(apiKey: widget.storage.getApiKey() ?? '');
    _loadData();
  }

  Future<void> _loadData() async {
    await widget.storage.updateStreak();
    final progress = await widget.storage.getProgress();
    final todaysLesson = await widget.storage.getTodaysLesson();
    setState(() {
      _progress = progress;
      _todaysLesson = todaysLesson;
    });
    _loadMotivation(progress);
  }

  Future<void> _loadMotivation(UserProgress progress) async {
    setState(() => _isLoadingMotivation = true);
    try {
      final msg = await _aiService.getMotivationalMessage(
        streak: progress.currentStreak,
        level: progress.currentLevel,
        totalXP: progress.totalXP,
        recentWeakAreas: progress.weakAreas,
      );
      setState(() => _motivationalMessage = msg);
    } catch (_) {
      setState(() => _motivationalMessage =
          'Heute ist ein neuer Tag! Every lesson brings you closer to fluency. Du schaffst das! 💪');
    } finally {
      setState(() => _isLoadingMotivation = false);
    }
  }

  Future<void> _generateTodaysLesson() async {
    setState(() => _isLoadingLesson = true);
    try {
      final progress = await widget.storage.getProgress();
      final lessons = await widget.storage.getLessons();
      final completedTopics = lessons.map((l) => l.topic).toList();

      final lesson = await _aiService.generateDailyLesson(
        level: progress.currentLevel,
        completedTopics: completedTopics,
        weakAreas: progress.weakAreas,
      );

      await widget.storage.saveLesson(lesson);
      await widget.storage.recordActivity(lessonsCompleted: 0, xpEarned: 0);
      setState(() => _todaysLesson = lesson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLesson = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex == 2) {
      return ProgressScreen(storage: widget.storage);
    }
    if (_selectedIndex == 3) {
      return ResourcesScreen(
        storage: widget.storage,
        aiService: _aiService,
        currentLevel: _progress?.currentLevel ?? 'A1',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d1a),
        elevation: 0,
        title: const Row(
          children: [
            Text('🇩🇪', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'DeutschMeister',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(storage: widget.storage),
              ),
            ).then((_) {
              _aiService = AIService(apiKey: widget.storage.getApiKey() ?? '');
              _loadData();
            }),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHomeTab() : _buildHomeworkTab(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1a1a2e),
        indicatorColor: const Color(0xFF533483),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Resources',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressHeader(),
            const SizedBox(height: 20),
            _buildMotivationCard(),
            const SizedBox(height: 20),
            _buildTodaysLesson(),
            const SizedBox(height: 20),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = _progress;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF533483), Color(0xFF0f3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${progress.currentLevel}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    progress.levelLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildStreakBadge(progress.currentStreak),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.totalXP} XP',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${progress.xpForNextLevel} XP',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.levelProgress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress.levelProgress * 100).toInt()}% to ${_nextLevel(progress.currentLevel)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: streak > 0 ? Colors.orange.withOpacity(0.2) : Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: streak > 0 ? Colors.orange : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            streak > 0 ? '🔥' : '💤',
            style: const TextStyle(fontSize: 24),
          ),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Text(
            'day streak',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: _isLoadingMotivation
                ? const SizedBox(
                    height: 20,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  )
                : Text(
                    _motivationalMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysLesson() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Lesson",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_todaysLesson != null)
          _buildLessonCard(_todaysLesson!)
        else
          _buildGenerateLessonCard(),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonScreen(
            lesson: lesson,
            storage: widget.storage,
            aiService: _aiService,
          ),
        ),
      ).then((_) => _loadData()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: lesson.isCompleted
                ? Colors.green.withOpacity(0.5)
                : const Color(0xFF533483).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF533483),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.level,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (lesson.isCompleted)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('Completed',
                          style:
                              TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white38, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lesson.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lesson.topic,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              lesson.grammarFocus.length > 100
                  ? '${lesson.grammarFocus.substring(0, 100)}...'
                  : lesson.grammarFocus,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.book_outlined,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${lesson.vocabulary.length} words',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.headphones_outlined,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${lesson.resources.length} resources',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateLessonCard() {
    return GestureDetector(
      onTap: _isLoadingLesson ? null : _generateTodaysLesson,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF533483).withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          children: [
            if (_isLoadingLesson)
              const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF533483)),
                  SizedBox(height: 16),
                  Text(
                    'Your AI teacher is preparing\nyour personalized lesson...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'Generate Today\'s Lesson',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your AI teacher will create a personalized\nGerman lesson just for you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF533483), Color(0xFF0f3460)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Generate Lesson ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final progress = _progress;
    if (progress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Journey',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('📚', '${progress.totalLessonsCompleted}', 'Lessons'),
            const SizedBox(width: 12),
            _buildStatCard('📝', '${progress.totalHomeworkCompleted}', 'Homework'),
            const SizedBox(width: 12),
            _buildStatCard('⭐', '${progress.totalXP}', 'Total XP'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkTab() {
    return HomeworkListScreen(
      storage: widget.storage,
      aiService: _aiService,
    );
  }

  String _nextLevel(String current) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final idx = levels.indexOf(current);
    if (idx < levels.length - 1) return levels[idx + 1];
    return 'Max';
  }
}
