import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson.dart';
import '../models/homework.dart';

class AIService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-opus-4-6';
  static const String _apiVersion = '2023-06-01';

  final String apiKey;

  AIService({required this.apiKey});

  Future<String> _sendMessage(String systemPrompt, String userMessage) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 4096,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } else {
      throw Exception('AI API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Generate a complete daily German lesson
  Future<Lesson> generateDailyLesson({
    required String level,
    required List<String> completedTopics,
    required List<String> weakAreas,
  }) async {
    const systemPrompt = '''You are DeutschMeister, an expert German language teacher.
You create engaging, structured, and motivating German lessons.
You deeply understand pedagogy and language acquisition.
Always respond with valid JSON only, no extra text.''';

    final completedList = completedTopics.take(10).join(', ');
    final weakList = weakAreas.join(', ');

    final userMessage = '''Create a daily German lesson for level $level.
${completedTopics.isNotEmpty ? 'Already covered topics: $completedList' : ''}
${weakAreas.isNotEmpty ? 'Areas needing reinforcement: $weakList' : ''}

Return a JSON object with this exact structure:
{
  "title": "Lesson title",
  "topic": "Main topic (e.g., Greetings, Past Tense, Shopping)",
  "grammarFocus": "Key grammar point explained clearly",
  "content": "Full lesson in markdown with sections: ## Introduction, ## Grammar, ## Examples, ## Practice Tips. Make it engaging, use emojis, real-life examples.",
  "vocabulary": ["word1 - translation - example sentence", "word2 - translation - example sentence"],
  "exampleSentences": ["German sentence | English translation", "..."],
  "resources": [
    {
      "title": "Resource title",
      "url": "https://www.youtube.com/watch?v=VALID_ID",
      "platform": "youtube",
      "description": "Why this helps"
    }
  ]
}

Make vocabulary 8-12 words. Make example sentences 5-8. Include 3-4 YouTube resources that ACTUALLY exist for learning German at this level. Focus on practical, everyday German.''';

    final response = await _sendMessage(systemPrompt, userMessage);

    try {
      // Extract JSON from response (in case there's extra text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON in response');

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final now = DateTime.now();

      return Lesson(
        id: 'lesson_${now.millisecondsSinceEpoch}',
        title: data['title'] ?? 'German Lesson',
        level: level,
        topic: data['topic'] ?? 'General',
        content: data['content'] ?? '',
        vocabulary: List<String>.from(data['vocabulary'] ?? []),
        exampleSentences: List<String>.from(data['exampleSentences'] ?? []),
        grammarFocus: data['grammarFocus'] ?? '',
        resources: (data['resources'] as List? ?? [])
            .map((r) => YoutubeResource(
                  title: r['title'] ?? '',
                  url: r['url'] ?? '',
                  platform: r['platform'] ?? 'youtube',
                  description: r['description'] ?? '',
                ))
            .toList(),
        date: now,
      );
    } catch (e) {
      throw Exception('Failed to parse lesson: $e\nResponse: $response');
    }
  }

  /// Generate homework based on a lesson
  Future<Homework> generateHomework(Lesson lesson) async {
    const systemPrompt = '''You are DeutschMeister, a German language teacher creating homework assignments.
Make exercises challenging but achievable. Mix different task types.
Always respond with valid JSON only.''';

    final userMessage = '''Create homework for this German lesson:
Topic: ${lesson.topic}
Level: ${lesson.level}
Grammar Focus: ${lesson.grammarFocus}
Vocabulary: ${lesson.vocabulary.take(6).join(', ')}

Return a JSON object:
{
  "title": "Homework title",
  "tasks": [
    {
      "type": "translation|fillBlank|writeEssay|conjugation|multipleChoice",
      "question": "The task question",
      "hint": "Optional helpful hint"
    }
  ]
}

Create 5-7 varied tasks. Include at least one essay/creative writing task.
Make tasks progressively harder. Use the lesson vocabulary and grammar.''';

    final response = await _sendMessage(systemPrompt, userMessage);

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON in response');

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final now = DateTime.now();

      final tasks = (data['tasks'] as List).asMap().entries.map((entry) {
        final i = entry.key;
        final t = entry.value;
        final typeStr = t['type'] as String? ?? 'translation';
        final type = HomeworkTaskType.values.firstWhere(
          (ht) => ht.name == typeStr,
          orElse: () => HomeworkTaskType.translation,
        );
        return HomeworkTask(
          id: 'task_${now.millisecondsSinceEpoch}_$i',
          type: type,
          question: t['question'] ?? '',
          hint: t['hint'],
        );
      }).toList();

      return Homework(
        id: 'hw_${now.millisecondsSinceEpoch}',
        lessonId: lesson.id,
        title: data['title'] ?? 'German Homework',
        tasks: tasks,
        assignedDate: now,
        dueDate: now.add(const Duration(days: 2)),
      );
    } catch (e) {
      throw Exception('Failed to parse homework: $e');
    }
  }

  /// Grade homework and provide detailed feedback
  Future<Map<String, dynamic>> gradeHomework(Homework homework, Lesson lesson) async {
    const systemPrompt = '''You are DeutschMeister, a supportive and encouraging German teacher grading homework.
Be constructive, specific, and motivating. Celebrate what they got right, gently correct mistakes.
Point out patterns in errors. Give tips for improvement.
Always respond with valid JSON only.''';

    final tasksText = homework.tasks.map((t) {
      return '''Task: ${t.question}
Student Answer: ${t.userAnswer ?? "(no answer)"}''';
    }).join('\n\n');

    final userMessage = '''Grade this German homework for a ${lesson.level} student.
Lesson topic was: ${lesson.topic}

$tasksText

Return JSON:
{
  "overallScore": 0-100,
  "overallFeedback": "Encouraging overall message (2-3 sentences, use emojis)",
  "tasks": [
    {
      "isCorrect": true/false,
      "correction": "Correct answer if wrong, or 'Perfekt!' if right",
      "explanation": "Brief explanation of the grammar/rule"
    }
  ],
  "weaknesses": ["area1", "area2"],
  "strengths": ["area1", "area2"],
  "motivationalMessage": "A personal, powerful motivational message to keep them going (2-3 sentences)",
  "nextStepTip": "One specific thing to practice next"
}''';

    final response = await _sendMessage(systemPrompt, userMessage);

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON in response');
      return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse grading: $e');
    }
  }

  /// Get a motivational message tailored to the user's progress
  Future<String> getMotivationalMessage({
    required int streak,
    required String level,
    required int totalXP,
    required List<String> recentWeakAreas,
  }) async {
    const systemPrompt = '''You are DeutschMeister, an incredibly motivating German language coach.
You know exactly how to push learners beyond their comfort zone while keeping them inspired.
Write in a direct, energetic, personal style. Use German phrases naturally.
Keep it to 2-3 sentences maximum.''';

    final userMessage = '''Give a powerful daily motivation for this learner:
- Current streak: $streak days
- Level: $level
- Total XP: $totalXP
- Recent struggles: ${recentWeakAreas.isEmpty ? 'none' : recentWeakAreas.join(', ')}

Make it personal, energetic, and push them to break their limits. Include 1-2 German words/phrases naturally.''';

    return await _sendMessage(systemPrompt, userMessage);
  }

  /// Explain a specific German grammar point
  Future<String> explainGrammar(String grammarPoint, String level) async {
    const systemPrompt = '''You are DeutschMeister, explaining German grammar clearly and engagingly.
Use analogies, examples, and memory tricks. Make it stick!
Use markdown formatting.''';

    final userMessage = 'Explain "$grammarPoint" for a $level German learner. '
        'Include: clear explanation, 5 examples, common mistakes to avoid, and a memory trick.';

    return await _sendMessage(systemPrompt, userMessage);
  }

  /// Get a list of recommended German learning resources
  Future<List<YoutubeResource>> getResources(String level, String topic) async {
    const systemPrompt = '''You are DeutschMeister, curating the best German learning resources.
Only recommend real, popular, high-quality resources.
Always respond with valid JSON only.''';

    final userMessage = '''Recommend 6 excellent resources for learning German $topic at $level level.

Return JSON array:
[
  {
    "title": "Resource name",
    "url": "https://actual-url.com",
    "platform": "youtube|instagram|tiktok|podcast|website",
    "description": "Why this is excellent for $level learners studying $topic"
  }
]

Mix YouTube channels, podcasts, and websites. Include both free resources.''';

    final response = await _sendMessage(systemPrompt, userMessage);

    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) return [];

      final list = jsonDecode(jsonMatch.group(0)!) as List;
      return list
          .map((r) => YoutubeResource(
                title: r['title'] ?? '',
                url: r['url'] ?? '',
                platform: r['platform'] ?? 'youtube',
                description: r['description'] ?? '',
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Generate audio text (sentences for TTS practice)
  Future<List<Map<String, String>>> generateListeningPractice(Lesson lesson) async {
    const systemPrompt = '''You are DeutschMeister creating listening practice content.
Create natural, conversational German sentences at the appropriate level.
Always respond with valid JSON only.''';

    final userMessage = '''Create 8 listening practice sentences for:
Level: ${lesson.level}
Topic: ${lesson.topic}

Return JSON array:
[
  {
    "german": "German sentence",
    "english": "English translation",
    "note": "Optional grammar or pronunciation note"
  }
]

Make sentences natural and increasingly complex. Focus on the lesson topic.''';

    final response = await _sendMessage(systemPrompt, userMessage);

    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) return [];
      final list = jsonDecode(jsonMatch.group(0)!) as List;
      return list.map((s) => Map<String, String>.from(s)).toList();
    } catch (e) {
      return [];
    }
  }
}
