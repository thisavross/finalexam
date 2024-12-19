import 'package:finalexam/service/db_service.dart';
import 'package:flutter/material.dart';

class EnrollmentPage extends StatefulWidget {
  const EnrollmentPage({Key? key}) : super(key: key);

  @override
  _EnrollmentPageState createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  int? _studentId;
  List<Map<String, dynamic>> _subjects = [];
  Set<int> _selectedSubjects = {};
  int _totalCredits = 0;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _dbHelper.getAllSubjects();
    setState(() {
      _subjects = subjects;
    });
  }

  Future<void> _registerStudent() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    final studentId = await _dbHelper.insertStudent(_nameController.text);
    setState(() {
      _studentId = studentId;
    });
  }

  Future<void> _enrollSelectedSubjects() async {
    if (_studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register first')),
      );
      return;
    }

    bool success = true;
    for (final subjectId in _selectedSubjects) {
      success = await _dbHelper.enrollSubject(_studentId!, subjectId);
      if (!success) break;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment failed: Maximum credits exceeded')),
      );
      return;
    }

    final enrolledSubjects = await _dbHelper.getEnrolledSubjects(_studentId!);
    final totalCredits = await _dbHelper.getTotalCredits(_studentId!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enrollment Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${_nameController.text}'),
            const SizedBox(height: 8),
            Text('Total Credits: $totalCredits'),
            const SizedBox(height: 8),
            const Text('Enrolled Subjects:'),
            ...enrolledSubjects.map((subject) => Text(
              '- ${subject['name']} (${subject['credits']} credits)'
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Enrollment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _registerStudent,
              child: const Text('Register'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Subjects (Max 10 credits):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  return CheckboxListTile(
                    title: Text(subject['name']),
                    subtitle: Text('${subject['credits']} credits'),
                    value: _selectedSubjects.contains(subject['subject_id']),
                    onChanged: (bool? value) {
                      setState(() {
                        final credits = subject['credits'];
                        if (credits != null) {
                          if (value == true) {
                            _selectedSubjects.add(subject['subject_id']);
                            _totalCredits += (credits as int);
                          } else {
                            _selectedSubjects.remove(subject['subject_id']);
                            _totalCredits -= (credits as int);
                          }
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selected Credits: $_totalCredits/10',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _enrollSelectedSubjects,
              child: const Text('Enroll'),
            ),
          ],
        ),
      ),
    );
  }
}