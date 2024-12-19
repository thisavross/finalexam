class Student {
  final int? studentId;
  final String name;
  final int totalCredits;

  Student({
    this.studentId,
    required this.name,
    this.totalCredits = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'name': name,
      'total_credits': totalCredits,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      studentId: map['student_id'],
      name: map['name'],
      totalCredits: map['total_credits'],
    );
  }
}