import 'package:flutter_application/models/course_model.dart';
import 'package:flutter_application/models/user_model.dart';

class DepartmentAssets {
  final List<Course> courses;
  final List<UserModel> faculty;
  final List<UserModel> students;

  DepartmentAssets({
    required this.courses,
    required this.faculty,
    required this.students,
  });
}
