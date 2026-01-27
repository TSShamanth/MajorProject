class AppConstants {
  // API & Firebase Collections
  static const String usersCollection = 'users';
  static const String subjectsCollection = 'subjects';
  static const String attendanceCollection = 'attendance';

  // Attendance Status
  static const String roleStudent = 'student';
  static const String roleFaculty = 'faculty';
  static const String roleAdmin = 'admin';

  // Error Messages
  static const String errorLoadingSubjects = 'Failed to load subjects. Please try again.';
  static const String errorLoadingStudents = 'Failed to load students. Please try again.';
  static const String errorMarkingAttendance = 'Failed to mark attendance. Please try again.';
  static const String errorLoadingHistory = 'Failed to load attendance history.';
  static const String errorSelectSubject = 'Please select a subject first.';
  static const String errorSelectDate = 'Please select a valid date.';
  static const String errorNoStudents = 'No students found for this subject.';

  // Success Messages
  static const String successAttendanceMarked = 'Attendance marked successfully!';
  static const String successAttendanceUpdated = 'Attendance updated successfully!';

  // Timeout Duration (in seconds)
  static const int firestoreTimeout = 10;
  static const int retryAttempts = 3;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 1.0;

  // Attendance Thresholds (Percentages)
  static const double attendanceExcellent = 80.0; // Green
  static const double attendanceGood = 70.0;      // Amber
  // Below 70 is Red

  // Date Formats
  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatStorage = 'yyyy-MM-dd';
}

class AppStrings {
  // Navigation
  static const String markAttendance = 'Mark Attendance';
  static const String attendanceHistory = 'Attendance History';
  static const String facultyPortal = 'Faculty Portal';

  // Form Labels
  static const String selectSubject = 'Select Subject';
  static const String selectDate = 'Select Date';
  static const String students = 'Students';
  static const String attendance = 'Attendance';
  static const String present = 'Present';
  static const String absent = 'Absent';

  // Buttons
  static const String submit = 'Submit Attendance';
  static const String reset = 'Reset';
  static const String markAll = 'Mark All';
  static const String clearAll = 'Clear All';
  static const String back = 'Back';
  static const String retry = 'Retry';

  // Status
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String noStudentsFound = 'No students found';
}
