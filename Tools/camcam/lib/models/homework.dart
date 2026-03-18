class Homework {
  final String id;
  final String lessonId;
  final String title;
  final List<HomeworkTask> tasks;
  final DateTime assignedDate;
  final DateTime dueDate;
  HomeworkStatus status;
  String? feedback; // AI feedback after submission
  int? score; // 0-100

  Homework({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.tasks,
    required this.assignedDate,
    required this.dueDate,
    this.status = HomeworkStatus.pending,
    this.feedback,
    this.score,
  });

  bool get isSubmitted => status == HomeworkStatus.submitted || status == HomeworkStatus.graded;
  bool get isGraded => status == HomeworkStatus.graded;

  Map<String, dynamic> toJson() => {
        'id': id,
        'lessonId': lessonId,
        'title': title,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'assignedDate': assignedDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'feedback': feedback,
        'score': score,
      };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json['id'],
        lessonId: json['lessonId'],
        title: json['title'],
        tasks: (json['tasks'] as List).map((t) => HomeworkTask.fromJson(t)).toList(),
        assignedDate: DateTime.parse(json['assignedDate']),
        dueDate: DateTime.parse(json['dueDate']),
        status: HomeworkStatus.values.firstWhere((s) => s.name == json['status'],
            orElse: () => HomeworkStatus.pending),
        feedback: json['feedback'],
        score: json['score'],
      );
}

class HomeworkTask {
  final String id;
  final HomeworkTaskType type;
  final String question;
  final String? hint;
  String? userAnswer;
  String? correction; // AI correction
  bool? isCorrect;

  HomeworkTask({
    required this.id,
    required this.type,
    required this.question,
    this.hint,
    this.userAnswer,
    this.correction,
    this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'question': question,
        'hint': hint,
        'userAnswer': userAnswer,
        'correction': correction,
        'isCorrect': isCorrect,
      };

  factory HomeworkTask.fromJson(Map<String, dynamic> json) => HomeworkTask(
        id: json['id'],
        type: HomeworkTaskType.values.firstWhere((t) => t.name == json['type'],
            orElse: () => HomeworkTaskType.translation),
        question: json['question'],
        hint: json['hint'],
        userAnswer: json['userAnswer'],
        correction: json['correction'],
        isCorrect: json['isCorrect'],
      );
}

enum HomeworkTaskType {
  translation,    // Translate this sentence
  fillBlank,      // Fill in the blank
  writeEssay,     // Write a short paragraph
  conjugation,    // Conjugate the verb
  multipleChoice, // Multiple choice question
}

enum HomeworkStatus {
  pending,
  inProgress,
  submitted,
  graded,
}
