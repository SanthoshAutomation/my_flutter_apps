import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/todo.dart';
import '../models/note.dart';
import '../models/appointment.dart';
import '../models/alarm_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'assistant.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        due_date INTEGER,
        reminder_time INTEGER,
        is_completed INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        synced_to_cloud INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT DEFAULT '',
        color_index INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_pinned INTEGER DEFAULT 0,
        synced_to_cloud INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        type TEXT DEFAULT 'appointment',
        location TEXT DEFAULT '',
        reminder_time INTEGER,
        color_index INTEGER DEFAULT 0,
        synced_to_cloud INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        days TEXT DEFAULT '0,0,0,0,0,0,0',
        is_enabled INTEGER DEFAULT 1,
        sound TEXT DEFAULT 'default',
        vibrate INTEGER DEFAULT 1
      )
    ''');
  }

  // --- TODOS ---
  Future<List<Todo>> getTodos() async {
    final db = await database;
    final maps = await db.query('todos', orderBy: 'created_at DESC');
    return maps.map(Todo.fromMap).toList();
  }

  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return db.insert('todos', todo.toMap());
  }

  Future<void> updateTodo(Todo todo) async {
    final db = await database;
    await db.update('todos', todo.toMap(),
        where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // --- NOTES ---
  Future<List<Note>> getNotes() async {
    final db = await database;
    final maps = await db.query('notes',
        orderBy: 'is_pinned DESC, updated_at DESC');
    return maps.map(Note.fromMap).toList();
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert('notes', note.toMap());
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- APPOINTMENTS ---
  Future<List<Appointment>> getAppointments() async {
    final db = await database;
    final maps =
        await db.query('appointments', orderBy: 'start_date ASC');
    return maps.map(Appointment.fromMap).toList();
  }

  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    return db.insert('appointments', appointment.toMap());
  }

  Future<void> updateAppointment(Appointment appointment) async {
    final db = await database;
    await db.update('appointments', appointment.toMap(),
        where: 'id = ?', whereArgs: [appointment.id]);
  }

  Future<void> deleteAppointment(int id) async {
    final db = await database;
    await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // --- ALARMS ---
  Future<List<AlarmModel>> getAlarms() async {
    final db = await database;
    final maps =
        await db.query('alarms', orderBy: 'hour ASC, minute ASC');
    return maps.map((m) => AlarmModel.fromMap(m)).toList();
  }

  Future<int> insertAlarm(AlarmModel alarm) async {
    final db = await database;
    return db.insert('alarms', alarm.toMap());
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final db = await database;
    await db.update('alarms', alarm.toMap(),
        where: 'id = ?', whereArgs: [alarm.id]);
  }

  Future<void> deleteAlarm(int id) async {
    final db = await database;
    await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getAllDataForSync() async {
    final todos = await getTodos();
    final notes = await getNotes();
    final appointments = await getAppointments();
    return {
      'todos': todos.map((t) => t.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'appointments': appointments.map((a) => a.toMap()).toList(),
    };
  }
}
