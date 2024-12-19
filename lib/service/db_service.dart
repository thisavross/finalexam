import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'enrollment.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Student(
            student_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            total_credits INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE Subject(
            subject_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            credits INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE Enrollment(
            enrollment_id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            subject_id INTEGER,
            FOREIGN KEY (student_id) REFERENCES Student(student_id),
            FOREIGN KEY (subject_id) REFERENCES Subject(subject_id)
          )
        ''');
      },
      
    );
    
  }
  Future<void> insertInitialSubjects() async {
    final Database db = await database;
    
    // Check if subjects already exist
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM Subject'));
    
    if (count == 0) {
      await db.transaction((txn) async {
        await txn.rawInsert(
            'INSERT INTO Subject(name, credits) VALUES(?, ?)',
            ['WMP', 3]);
        await txn.rawInsert(
            'INSERT INTO Subject(name, credits) VALUES(?, ?)',
            ['Software Engineering', 3]);
        await txn.rawInsert(
            'INSERT INTO Subject(name, credits) VALUES(?, ?)',
            ['AI', 4]);
        await txn.rawInsert(
            'INSERT INTO Subject(name, credits) VALUES(?, ?)',
            ['3D', 5]);
      });
    }
  }

  Future<int> insertStudent(String name) async {
    final Database db = await database;
    return await db.insert('Student', {'name': name});
  }

  Future<bool> enrollSubject(int studentId, int subjectId) async {
    final Database db = await database;
    
    // Get current total credits
    final currentCredits = await getTotalCredits(studentId);
    final subjectCredits = await getSubjectCredits(subjectId);
    
    if (currentCredits + subjectCredits > 10) {
      return false; // Exceeds maximum credits
    }

    await db.insert('Enrollment', {
      'student_id': studentId,
      'subject_id': subjectId,
    });

    await db.update(
      'Student',
      {'total_credits': currentCredits + subjectCredits},
      where: 'student_id = ?',
      whereArgs: [studentId],
    );

    return true;
  }

  Future<int> getTotalCredits(int studentId) async {
    final Database db = await database;
    final result = await db.query(
      'Student',
      columns: ['total_credits'],
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return result.first['total_credits'] as int;
  }

  Future<int> getSubjectCredits(int subjectId) async {
    final Database db = await database;
    final result = await db.query(
      'Subject',
      columns: ['credits'],
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    return result.first['credits'] as int;
  }

  Future<List<Map<String, dynamic>>> getAllSubjects() async {
    final Database db = await database;
    return await db.query('Subject');
  }

  Future<List<Map<String, dynamic>>> getEnrolledSubjects(int studentId) async {
    final Database db = await database;
    return await db.rawQuery('''
      SELECT Subject.* FROM Subject
      JOIN Enrollment ON Subject.subject_id = Enrollment.subject_id
      WHERE Enrollment.student_id = ?
    ''', [studentId]);
  }
}

