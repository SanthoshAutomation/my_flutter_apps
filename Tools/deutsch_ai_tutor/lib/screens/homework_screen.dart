import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/homework.dart';
import '../models/lesson.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

// Homework list shown in home bottom nav
class HomeworkListScreen extends StatefulWidget {
  final StorageService storage;
  final AIService aiService;

  const HomeworkListScreen({
    super.key,
    required this.storage,
    required this.aiService,
  });

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen> {
  List<Homework> _homeworkList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await widget.storage.getAllHomework();
    setState(() {
      _homeworkList = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d1a),
        title: const Text('Homework',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF533483)))
          : _homeworkList.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _homeworkList.length,
                    itemBuilder: (_, i) =>
                        _buildHomeworkCard(_homeworkList[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📝', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'No homework yet',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Complete a lesson and tap "Do Homework"\nto get your assignment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Homework hw) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (hw.status) {
      case HomeworkStatus.graded:
        statusColor = Colors.green;
        statusLabel = 'Graded: ${hw.score}%';
        statusIcon = Icons.grade;
        break;
      case HomeworkStatus.submitted:
        statusColor = Colors.blue;
        statusLabel = 'Submitted';
        statusIcon = Icons.send;
        break;
      case HomeworkStatus.inProgress:
        statusColor = Colors.orange;
        statusLabel = 'In Progress';
        statusIcon = Icons.edit;
        break;
      default:
        statusColor = Colors.white38;
        statusLabel = 'Pending';
        statusIcon = Icons.assignment_outlined;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomeworkScreen(
            homework: hw,
            lesson: null,
            storage: widget.storage,
            aiService: widget.aiService,
          ),
        ),
      ).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hw.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${hw.tasks.length} tasks · Due ${_formatDate(hw.dueDate)}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            if (hw.isGraded && hw.feedback != null) ...[
              const SizedBox(height: 8),
              Text(
                hw.feedback!.length > 80
                    ? '${hw.feedback!.substring(0, 80)}...'
                    : hw.feedback!,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return 'Overdue';
    return '${date.day}/${date.month}';
  }
}

// Full homework screen for doing/reviewing homework
class HomeworkScreen extends StatefulWidget {
  final Homework homework;
  final Lesson? lesson;
  final StorageService storage;
  final AIService aiService;

  const HomeworkScreen({
    super.key,
    required this.homework,
    required this.lesson,
    required this.storage,
    required this.aiService,
  });

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;
  bool _isGraded = false;
  Map<String, dynamic>? _gradingResult;

  @override
  void initState() {
    super.initState();
    _isGraded = widget.homework.isGraded;
    for (final task in widget.homework.tasks) {
      _controllers[task.id] = TextEditingController(text: task.userAnswer);
    }
  }

  Future<void> _saveProgress() async {
    for (final task in widget.homework.tasks) {
      task.userAnswer = _controllers[task.id]?.text;
    }
    widget.homework.status = HomeworkStatus.inProgress;
    await widget.storage.saveHomework(widget.homework);
  }

  Future<void> _submitHomework() async {
    // Save answers
    for (final task in widget.homework.tasks) {
      task.userAnswer = _controllers[task.id]?.text;
    }

    // Check if at least some answers are filled
    final answered = widget.homework.tasks
        .where((t) => (t.userAnswer ?? '').trim().isNotEmpty)
        .length;
    if (answered == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer at least one question first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      widget.homework.status = HomeworkStatus.submitted;
      await widget.storage.saveHomework(widget.homework);

      // Get AI to grade
      final lesson = widget.lesson ??
          Lesson(
            id: widget.homework.lessonId,
            title: widget.homework.title,
            level: 'A1',
            topic: 'German',
            content: '',
            vocabulary: [],
            exampleSentences: [],
            grammarFocus: '',
            resources: [],
            date: DateTime.now(),
          );

      final result = await widget.aiService.gradeHomework(widget.homework, lesson);
      _gradingResult = result;

      // Apply corrections to tasks
      final taskCorrections = result['tasks'] as List? ?? [];
      for (var i = 0; i < widget.homework.tasks.length && i < taskCorrections.length; i++) {
        final correction = taskCorrections[i];
        widget.homework.tasks[i].isCorrect = correction['isCorrect'] ?? false;
        widget.homework.tasks[i].correction =
            '${correction['correction'] ?? ''}\n${correction['explanation'] ?? ''}';
      }

      widget.homework.status = HomeworkStatus.graded;
      widget.homework.score = result['overallScore'] as int? ?? 0;
      widget.homework.feedback = result['overallFeedback'] as String?;

      await widget.storage.saveHomework(widget.homework);

      // Record activity
      await widget.storage.recordActivity(
        homeworkCompleted: 1,
        xpEarned: ((widget.homework.score ?? 0) * 2),
        minutesStudied: 20,
      );

      // Update weak areas
      final progress = await widget.storage.getProgress();
      final weaknesses = List<String>.from(result['weaknesses'] ?? []);
      final strengths = List<String>.from(result['strengths'] ?? []);
      for (final w in weaknesses) {
        if (!progress.weakAreas.contains(w)) progress.weakAreas.add(w);
      }
      for (final s in strengths) {
        progress.weakAreas.remove(s);
        if (!progress.masteredTopics.contains(s)) {
          progress.masteredTopics.add(s);
        }
      }
      await widget.storage.saveProgress(progress);

      setState(() => _isGraded = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error grading homework: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      widget.homework.status = HomeworkStatus.inProgress;
      await widget.storage.saveHomework(widget.homework);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d1a),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () async {
            if (!_isGraded) await _saveProgress();
            if (mounted) Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.homework.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              '${widget.homework.tasks.length} tasks',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isGraded && _gradingResult != null) _buildFeedbackHeader(),
            if (_isGraded && _gradingResult != null) const SizedBox(height: 16),
            ...widget.homework.tasks.asMap().entries.map(
                  (e) => _buildTaskCard(e.key, e.value),
                ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _isGraded
          ? null
          : _buildSubmitBar(),
    );
  }

  Widget _buildFeedbackHeader() {
    final score = widget.homework.score ?? 0;
    final scoreColor = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withOpacity(0.2),
            const Color(0xFF1a1a2e),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scoreLabel(score),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '+${score * 2} XP earned',
                      style: const TextStyle(
                          color: Colors.amber, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.homework.feedback != null) ...[
            const SizedBox(height: 12),
            MarkdownBody(
              data: widget.homework.feedback!,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
          ],
          if (_gradingResult?['motivationalMessage'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _gradingResult!['motivationalMessage'],
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_gradingResult?['nextStepTip'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next step: ${_gradingResult!['nextStepTip']}',
                      style: const TextStyle(
                          color: Colors.lightBlue, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(int index, HomeworkTask task) {
    final controller = _controllers[task.id]!;
    final isLong = task.type == HomeworkTaskType.writeEssay;

    Color? borderColor;
    if (_isGraded && task.isCorrect != null) {
      borderColor = task.isCorrect! ? Colors.green : Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor?.withOpacity(0.5) ??
              Colors.white12,
          width: borderColor != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF533483).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _taskTypeLabel(task.type),
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
              if (_isGraded && task.isCorrect != null) ...[
                const Spacer(),
                Icon(
                  task.isCorrect! ? Icons.check_circle : Icons.cancel,
                  color: task.isCorrect! ? Colors.green : Colors.red,
                  size: 22,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.question,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.5),
          ),
          if (task.hint != null) ...[
            const SizedBox(height: 8),
            Text(
              '💡 Hint: ${task.hint}',
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          if (!_isGraded)
            TextField(
              controller: controller,
              maxLines: isLong ? 6 : 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: isLong
                    ? 'Write your answer here...'
                    : 'Your answer...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF533483), width: 1.5),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.userAnswer ?? '(no answer)',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ),
                if (task.correction != null && !task.isCorrect!) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ Correction:',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.correction!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.isCorrect == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '✅ Perfekt!',
                      style:
                          TextStyle(color: Colors.green, fontSize: 13),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: const Color(0xFF1a1a2e),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saveProgress,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitHomework,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF533483),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Grading...'),
                      ],
                    )
                  : const Text(
                      'Submit & Get Feedback 🚀',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _taskTypeLabel(HomeworkTaskType type) {
    switch (type) {
      case HomeworkTaskType.translation:
        return 'Translation';
      case HomeworkTaskType.fillBlank:
        return 'Fill in the blank';
      case HomeworkTaskType.writeEssay:
        return 'Writing';
      case HomeworkTaskType.conjugation:
        return 'Conjugation';
      case HomeworkTaskType.multipleChoice:
        return 'Multiple choice';
    }
  }

  String _scoreLabel(int score) {
    if (score >= 90) return 'Ausgezeichnet! 🌟';
    if (score >= 80) return 'Sehr gut! 🎉';
    if (score >= 70) return 'Gut! 👍';
    if (score >= 60) return 'Befriedigend 💪';
    return 'Keep practicing! 📚';
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
