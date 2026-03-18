import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/progress.dart';
import '../services/storage_service.dart';

class ProgressScreen extends StatefulWidget {
  final StorageService storage;
  const ProgressScreen({super.key, required this.storage});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  UserProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await widget.storage.getProgress();
    setState(() {
      _progress = p;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d1a),
        title: const Text('My Progress',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF533483)))
          : _progress == null
              ? const Center(
                  child: Text('No data yet',
                      style: TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLevelCard(),
                        const SizedBox(height: 20),
                        _buildStatsGrid(),
                        const SizedBox(height: 20),
                        _buildActivityChart(),
                        const SizedBox(height: 20),
                        _buildAchievements(),
                        const SizedBox(height: 20),
                        _buildWeakAreasCard(),
                        const SizedBox(height: 20),
                        _buildMasteredTopicsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLevelCard() {
    final p = _progress!;
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text('Current Level',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                p.currentLevel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.levelLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('${p.totalXP} / ${p.xpForNextLevel} XP',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.levelProgress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(p.levelProgress * 100).toInt()}% complete',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final p = _progress!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatTile('🔥', 'Current Streak',
            '${p.currentStreak} days', Colors.orange),
        _buildStatTile('🏆', 'Best Streak',
            '${p.longestStreak} days', Colors.amber),
        _buildStatTile('📚', 'Lessons Done',
            '${p.totalLessonsCompleted}', const Color(0xFF533483)),
        _buildStatTile('📝', 'Homework Done',
            '${p.totalHomeworkCompleted}', Colors.green),
      ],
    );
  }

  Widget _buildStatTile(
      String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final p = _progress!;
    if (p.activityHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final recent = p.activityHistory.length > 14
        ? p.activityHistory.sublist(p.activityHistory.length - 14)
        : p.activityHistory;

    final spots = recent.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.xpEarned.toDouble());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'XP Earned (Last 14 Days)',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF533483),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.amber,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF533483).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final p = _progress!;
    final achievements = Achievement.allAchievements;

    // Determine unlocked ones based on progress
    final unlocked = <String>{};
    if (p.totalLessonsCompleted >= 1) unlocked.add('first_lesson');
    if (p.currentStreak >= 7 || p.longestStreak >= 7) unlocked.add('streak_7');
    if (p.currentStreak >= 30 || p.longestStreak >= 30) unlocked.add('streak_30');
    if (p.totalHomeworkCompleted >= 10) unlocked.add('homework_10');
    if (p.currentLevel == 'A2' || ['B1', 'B2', 'C1', 'C2'].contains(p.currentLevel)) {
      unlocked.add('level_a2');
    }
    if (['B1', 'B2', 'C1', 'C2'].contains(p.currentLevel)) {
      unlocked.add('level_b1');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
          ),
          itemCount: achievements.length,
          itemBuilder: (_, i) {
            final a = achievements[i];
            final isUnlocked = unlocked.contains(a.id);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFF533483).withOpacity(0.25)
                    : const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked
                      ? const Color(0xFF533483).withOpacity(0.6)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    a.emoji,
                    style: TextStyle(
                      fontSize: 24,
                      color: isUnlocked ? null : Colors.transparent,
                    ),
                  ),
                  if (!isUnlocked)
                    const Icon(Icons.lock_outline,
                        color: Colors.white24, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          a.title,
                          style: TextStyle(
                            color: isUnlocked
                                ? Colors.white
                                : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '+${a.xpReward} XP',
                          style: TextStyle(
                            color: isUnlocked
                                ? Colors.amber
                                : Colors.white24,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeakAreasCard() {
    final weakAreas = _progress?.weakAreas ?? [];
    if (weakAreas.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Areas to Improve',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weakAreas.map((area) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.4)),
                ),
                child: Text(area,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 13)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteredTopicsCard() {
    final mastered = _progress?.masteredTopics ?? [];
    if (mastered.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🌟', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Mastered Topics',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mastered.map((topic) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.4)),
                ),
                child: Text(topic,
                    style: const TextStyle(
                        color: Colors.green, fontSize: 13)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
