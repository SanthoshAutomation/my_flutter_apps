import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lesson.dart';
import '../models/homework.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import 'homework_screen.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final StorageService storage;
  final AIService aiService;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.storage,
    required this.aiService,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TtsService _tts = TtsService();
  List<Map<String, String>> _listeningPractice = [];
  bool _isLoadingAudio = false;
  bool _isGeneratingHomework = false;
  int? _speakingIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tts.init();
    _loadListeningPractice();
  }

  Future<void> _loadListeningPractice() async {
    setState(() => _isLoadingAudio = true);
    try {
      final practice =
          await widget.aiService.generateListeningPractice(widget.lesson);
      setState(() => _listeningPractice = practice);
    } catch (_) {
      // Use vocabulary as fallback
      setState(() {
        _listeningPractice = widget.lesson.exampleSentences.map((s) {
          final parts = s.split('|');
          return {
            'german': parts[0].trim(),
            'english': parts.length > 1 ? parts[1].trim() : '',
            'note': '',
          };
        }).toList();
      });
    } finally {
      setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _markComplete() async {
    widget.lesson.isCompleted = true;
    await widget.storage.saveLesson(widget.lesson);
    await widget.storage.recordActivity(
      lessonsCompleted: 1,
      xpEarned: 100,
      minutesStudied: 15,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Lesson completed! +100 XP earned!'),
          backgroundColor: Color(0xFF533483),
          duration: Duration(seconds: 3),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _generateAndStartHomework() async {
    setState(() => _isGeneratingHomework = true);
    try {
      // Check if homework already exists
      Homework? existing =
          await widget.storage.getHomeworkForLesson(widget.lesson.id);
      if (existing == null) {
        existing = await widget.aiService.generateHomework(widget.lesson);
        await widget.storage.saveHomework(existing);
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomeworkScreen(
            homework: existing!,
            lesson: widget.lesson,
            storage: widget.storage,
            aiService: widget.aiService,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate homework: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingHomework = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              '${widget.lesson.level} · ${widget.lesson.topic}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (!widget.lesson.isCompleted)
            TextButton.icon(
              onPressed: _markComplete,
              icon: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 18),
              label: const Text('Done',
                  style: TextStyle(color: Colors.green, fontSize: 13)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF533483),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Lesson'),
            Tab(text: 'Words'),
            Tab(text: 'Listen'),
            Tab(text: 'Links'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLessonTab(),
          _buildVocabularyTab(),
          _buildListeningTab(),
          _buildResourcesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGeneratingHomework ? null : _generateAndStartHomework,
        backgroundColor: const Color(0xFF533483),
        icon: _isGeneratingHomework
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.assignment_outlined),
        label: Text(_isGeneratingHomework ? 'Generating...' : 'Do Homework'),
      ),
    );
  }

  Widget _buildLessonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.lesson.isCompleted)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.green.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Lesson Completed! 🎉',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF533483).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖 Grammar Focus',
                  style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lesson.grammarFocus,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: widget.lesson.content,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              h2: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              h3: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              p: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.6),
              code: const TextStyle(
                  color: Colors.greenAccent,
                  backgroundColor: Color(0xFF1a1a2e),
                  fontSize: 14),
              blockquoteDecoration: BoxDecoration(
                color: const Color(0xFF16213e),
                border: Border(
                    left: BorderSide(color: Colors.amber, width: 3)),
                borderRadius: BorderRadius.circular(4),
              ),
              blockquote: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5),
              listBullet:
                  const TextStyle(color: Colors.amber, fontSize: 14),
            ),
          ),
          const SizedBox(height: 80), // FAB space
        ],
      ),
    );
  }

  Widget _buildVocabularyTab() {
    final vocab = widget.lesson.vocabulary;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vocab.length,
      itemBuilder: (_, i) {
        final parts = vocab[i].split(' - ');
        final word = parts[0].trim();
        final translation = parts.length > 1 ? parts[1].trim() : '';
        final example = parts.length > 2 ? parts[2].trim() : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (translation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        translation,
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 14),
                      ),
                    ],
                    if (example.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        example,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white54),
                    onPressed: () => _tts.speak(word),
                    tooltip: 'Pronounce word',
                  ),
                  if (example.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.slow_motion_video,
                          color: Colors.white38, size: 20),
                      onPressed: () => _tts.speakSlow(word),
                      tooltip: 'Slow pronunciation',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListeningTab() {
    if (_isLoadingAudio) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF533483)),
            SizedBox(height: 16),
            Text('Preparing audio practice...',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _listeningPractice.length,
      itemBuilder: (_, i) {
        final item = _listeningPractice[i];
        final isSpeaking = _speakingIndex == i;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSpeaking
                ? const Color(0xFF533483).withOpacity(0.3)
                : const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSpeaking
                  ? const Color(0xFF533483)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['german'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isSpeaking ? Icons.stop_circle : Icons.play_circle,
                          color: isSpeaking
                              ? Colors.red
                              : const Color(0xFF533483),
                          size: 32,
                        ),
                        onPressed: () async {
                          if (isSpeaking) {
                            await _tts.stop();
                            setState(() => _speakingIndex = null);
                          } else {
                            setState(() => _speakingIndex = i);
                            await _tts.speak(item['german'] ?? '');
                            setState(() => _speakingIndex = null);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.slow_motion_video,
                            color: Colors.white38, size: 22),
                        onPressed: () async {
                          setState(() => _speakingIndex = i);
                          await _tts.speakSlow(item['german'] ?? '');
                          setState(() => _speakingIndex = null);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if ((item['english'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item['english']!,
                  style: const TextStyle(color: Colors.amber, fontSize: 14),
                ),
              ],
              if ((item['note'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '💡 ${item['note']}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourcesTab() {
    final resources = widget.lesson.resources;
    if (resources.isEmpty) {
      return const Center(
        child: Text(
          'No resources available for this lesson',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (_, i) {
        final r = resources[i];
        return _buildResourceCard(r);
      },
    );
  }

  Widget _buildResourceCard(YoutubeResource resource) {
    final platformIcon = _platformIcon(resource.platform);
    final platformColor = _platformColor(resource.platform);

    return GestureDetector(
      onTap: () => _openUrl(resource.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: platformColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: platformColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(platformIcon, color: platformColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.description,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_filled;
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      case 'podcast':
        return Icons.mic;
      default:
        return Icons.language;
    }
  }

  Color _platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Colors.red;
      case 'instagram':
        return Colors.pink;
      case 'tiktok':
        return Colors.cyan;
      case 'podcast':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tts.dispose();
    super.dispose();
  }
}
