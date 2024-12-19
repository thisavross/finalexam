class Subject {
  final int? subjectId;
  final String name;
  final int credits;
  bool isSelected;

  Subject({
    this.subjectId,
    required this.name,
    required this.credits,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'name': name,
      'credits': credits,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      subjectId: map['subject_id'],
      name: map['name'],
      credits: map['credits'],
    );
  }
}