class Lesson {
  final String id;
  final String title;
  final String level; // A1, A2, B1, B2, C1, C2
  final String topic;
  final String content; // Full markdown lesson content
  final List<String> vocabulary; // German words with translations
  final List<String> exampleSentences;
  final String grammarFocus;
  final List<YoutubeResource> resources;
  final DateTime date;
  bool isCompleted;

  Lesson({
    required this.id,
    required this.title,
    required this.level,
    required this.topic,
    required this.content,
    required this.vocabulary,
    required this.exampleSentences,
    required this.grammarFocus,
    required this.resources,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'level': level,
        'topic': topic,
        'content': content,
        'vocabulary': vocabulary,
        'exampleSentences': exampleSentences,
        'grammarFocus': grammarFocus,
        'resources': resources.map((r) => r.toJson()).toList(),
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'],
        title: json['title'],
        level: json['level'],
        topic: json['topic'],
        content: json['content'],
        vocabulary: List<String>.from(json['vocabulary']),
        exampleSentences: List<String>.from(json['exampleSentences']),
        grammarFocus: json['grammarFocus'],
        resources: (json['resources'] as List)
            .map((r) => YoutubeResource.fromJson(r))
            .toList(),
        date: DateTime.parse(json['date']),
        isCompleted: json['isCompleted'] ?? false,
      );
}

class YoutubeResource {
  final String title;
  final String url;
  final String platform; // youtube, instagram, tiktok, etc.
  final String description;

  YoutubeResource({
    required this.title,
    required this.url,
    required this.platform,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'platform': platform,
        'description': description,
      };

  factory YoutubeResource.fromJson(Map<String, dynamic> json) =>
      YoutubeResource(
        title: json['title'],
        url: json['url'],
        platform: json['platform'],
        description: json['description'],
      );
}
