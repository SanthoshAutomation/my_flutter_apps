class Note {
  final int? id;
  final String title;
  final String content;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool syncedToCloud;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.colorIndex = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.syncedToCloud = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? syncedToCloud,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'color_index': colorIndex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_pinned': isPinned ? 1 : 0,
      'synced_to_cloud': syncedToCloud ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      colorIndex: map['color_index'] ?? 0,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isPinned: (map['is_pinned'] ?? 0) == 1,
      syncedToCloud: (map['synced_to_cloud'] ?? 0) == 1,
    );
  }
}
