import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lesson.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class ResourcesScreen extends StatefulWidget {
  final StorageService storage;
  final AIService aiService;
  final String currentLevel;

  const ResourcesScreen({
    super.key,
    required this.storage,
    required this.aiService,
    required this.currentLevel,
  });

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<YoutubeResource> _resources = [];
  bool _isLoading = false;
  String _selectedCategory = 'Grammar';

  final List<String> _categories = [
    'Grammar',
    'Vocabulary',
    'Pronunciation',
    'Conversation',
    'Culture',
    'Music',
  ];

  // Built-in curated resources
  final List<YoutubeResource> _staticResources = [
    YoutubeResource(
      title: 'Easy German',
      url: 'https://www.youtube.com/@EasyGerman',
      platform: 'youtube',
      description: 'Street interviews with real Germans. Subtitles in German & English. Perfect for all levels.',
    ),
    YoutubeResource(
      title: 'Get Germanized',
      url: 'https://www.youtube.com/@GetGermanized',
      platform: 'youtube',
      description: 'Vocabulary, grammar, and German culture explained in a fun way.',
    ),
    YoutubeResource(
      title: 'Deutsch für Euch',
      url: 'https://www.youtube.com/@DeutschFuerEuch',
      platform: 'youtube',
      description: 'Grammar explained clearly for English speakers. Great for beginners and intermediate learners.',
    ),
    YoutubeResource(
      title: 'Lingoni German',
      url: 'https://www.youtube.com/@lingoniGERMAN',
      platform: 'youtube',
      description: 'Structured German lessons from A1 to B2. Grammar and vocabulary explained simply.',
    ),
    YoutubeResource(
      title: 'GermanPod101',
      url: 'https://www.youtube.com/@germanpod101',
      platform: 'youtube',
      description: 'Daily German words, phrases, and cultural insights. Great for all levels.',
    ),
    YoutubeResource(
      title: 'Slow German Podcast',
      url: 'https://slowgerman.com',
      platform: 'podcast',
      description: 'Slow, clearly spoken German about everyday topics. Ideal for A2-B1 learners.',
    ),
    YoutubeResource(
      title: 'Deutsche Welle Learn German',
      url: 'https://www.dw.com/en/learn-german/s-2469',
      platform: 'website',
      description: 'Free courses from A1 to C1. Videos, audio, exercises. Completely free.',
    ),
    YoutubeResource(
      title: 'Duolingo German',
      url: 'https://www.duolingo.com/course/de/en/Learn-German',
      platform: 'website',
      description: 'Gamified daily practice. Great supplement to structured learning.',
    ),
    YoutubeResource(
      title: 'Anki Decks - German',
      url: 'https://ankiweb.net/shared/decks/german',
      platform: 'website',
      description: 'Spaced repetition flashcards for vocabulary. The most effective way to memorize words.',
    ),
    YoutubeResource(
      title: 'r/German on Reddit',
      url: 'https://www.reddit.com/r/german',
      platform: 'website',
      description: 'Active community of German learners. Ask questions, get feedback, stay motivated.',
    ),
    YoutubeResource(
      title: 'German Grammar @Instagram',
      url: 'https://www.instagram.com/explore/tags/germangrammar/',
      platform: 'instagram',
      description: 'Quick grammar tips and vocabulary posts. Great for daily micro-learning.',
    ),
    YoutubeResource(
      title: 'Language Transfer German',
      url: 'https://www.languagetransfer.org/german',
      platform: 'podcast',
      description: 'Brilliant audio course that teaches you to think in German. Completely free.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _resources = _staticResources;
  }

  Future<void> _loadAIResources() async {
    setState(() => _isLoading = true);
    try {
      final aiResources = await widget.aiService.getResources(
        widget.currentLevel,
        _selectedCategory,
      );
      setState(() {
        _resources = [...aiResources, ..._staticResources];
      });
    } catch (_) {
      setState(() => _resources = _staticResources);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0d1a),
        title: const Text(
          'Learning Resources',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _loadAIResources,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.amber, strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            label: const Text('AI Pick',
                style: TextStyle(color: Colors.amber, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: _categories.map((c) {
                final isSelected = c == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = c);
                    _loadAIResources();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF533483)
                          : const Color(0xFF1a1a2e),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF533483)
                            : Colors.white12,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _resources.length,
              itemBuilder: (_, i) => _buildResourceCard(_resources[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(YoutubeResource r) {
    final color = _platformColor(r.platform);
    final icon = _platformIcon(r.platform);

    return GestureDetector(
      onTap: () => _openUrl(r.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.platform.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.description,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_filled;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'tiktok':
        return Icons.music_note;
      case 'podcast':
        return Icons.mic_rounded;
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
}
