
import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class TimetableProvider with ChangeNotifier {
final FirestoreService _firestoreService = FirestoreService();
List<ClassPeriod> _todayClasses = [];
Map<String, List<ClassPeriod>> _weeklyClasses = {};
bool _isHoliday = false;
bool _isLoading = false;
bool _isWeeklyLoading = false;
String? _currentDepartment;
String? _currentSemester;
String? _errorMessage;

List<ClassPeriod> get todayClasses => _todayClasses;
Map<String, List<ClassPeriod>> get weeklyClasses => _weeklyClasses;
bool get isHoliday => _isHoliday;
bool get isLoading => _isLoading;
bool get isWeeklyLoading => _isWeeklyLoading;
String? get errorMessage => _errorMessage;

// Load today's timetable
Future<void> loadTimetable(String department, String semester) async {
_isLoading = true;
_errorMessage = null;
_currentDepartment = department;
_currentSemester = semester;
notifyListeners();

try {
print("🔄 Loading timetable for: $department, $semester");

// Check holiday
_isHoliday = await _firestoreService.isHoliday();
if (_isHoliday) {
print("🎉 It's a holiday!");
_todayClasses = [];
_isLoading = false;
notifyListeners();
return;
}

// Get today's classes
_todayClasses = await _firestoreService.getTodayClasses(department, semester);

print("✅ Loaded ${_todayClasses.length} classes for today");
_isLoading = false;
notifyListeners();

} catch (e) {
print("❌ Error loading timetable: $e");
_errorMessage = "Failed to load timetable: $e";
_todayClasses = [];
_isLoading = false;
notifyListeners();
}
}

// Load weekly timetable
Future<void> loadWeeklyTimetable(String department, String semester) async {
_isWeeklyLoading = true;
_errorMessage = null;
_currentDepartment = department;
_currentSemester = semester;
notifyListeners();

try {
print("🔄 Loading WEEKLY timetable for: $department, $semester");

// Check holiday
_isHoliday = await _firestoreService.isHoliday();
if (_isHoliday) {
print("🎉 Weekly holiday detected!");
_weeklyClasses = {};
_isWeeklyLoading = false;
notifyListeners();
return;
}

// Get weekly timetable
_weeklyClasses = await _firestoreService.getWeeklyTimetable(department, semester);

// Print summary
print("📊 Weekly timetable summary:");
_weeklyClasses.forEach((day, classes) {
print("  $day: ${classes.length} classes");
});

_isWeeklyLoading = false;
notifyListeners();

} catch (e) {
print("❌ Error loading weekly timetable: $e");
_errorMessage = "Failed to load weekly timetable: $e";
_weeklyClasses = {};
_isWeeklyLoading = false;
notifyListeners();
}
}

// Get classes for specific day
List<ClassPeriod> getClassesForDay(String day) {
final classes = _weeklyClasses[day] ?? [];
// Ensure they're sorted by period
classes.sort((a, b) => a.period.compareTo(b.period));
return classes;
}

// Get running classes for specific day
List<ClassPeriod> getRunningClassesForDay(String day) {
final classes = getClassesForDay(day);
return classes.where((classPeriod) => classPeriod.isCurrentlyRunning).toList();
}

// Get upcoming classes for specific day
List<ClassPeriod> getUpcomingClassesForDay(String day) {
final classes = getClassesForDay(day);
return classes.where((classPeriod) => classPeriod.isUpcoming).toList();
}

// ✅ Get completed classes for specific day (নতুন method)
List<ClassPeriod> getCompletedClassesForDay(String day) {
final classes = getClassesForDay(day);
return classes.where((classPeriod) {
final now = DateTime.now();
return now.isAfter(classPeriod.endDateTime);
}).toList();
}

// ✅ Get all unique days that have classes (নতুন method)
List<String> getDaysWithClasses() {
return _weeklyClasses.keys.where((day) {
return _weeklyClasses[day]!.isNotEmpty;
}).toList();
}

// ✅ Reload data (নতুন method)
Future<void> reload() async {
if (_currentDepartment != null && _currentSemester != null) {
await loadWeeklyTimetable(_currentDepartment!, _currentSemester!);
}
}

// Clear data
void clear() {
_todayClasses = [];
_weeklyClasses = {};
_isHoliday = false;
_errorMessage = null;
notifyListeners();
}

// ✅ Get group key for debugging (নতুন method)
String getGroupKey(String department, String semester) {
String dept = department.trim().toUpperCase();

// Department mapping
if (dept.contains('COMPUTER') || dept.contains('CST')) dept = 'CST';
else if (dept.contains('ELECTRONICS')) dept = 'ET';
else if (dept.contains('CIVIL')) dept = 'Civil';
else if (dept.contains('ELECTRICAL')) dept = 'ET';
else if (dept.contains('MECHANICAL')) dept = 'ME';
else if (dept.contains('ARCHITECTURE')) dept = 'ARCH';

// Semester formatting
String sem = semester.trim().toLowerCase();
if (!sem.contains(RegExp(r'(st|nd|rd|th)'))) {
if (sem == '1') sem = '1st';
else if (sem == '2') sem = '2nd';
else if (sem == '3') sem = '3rd';
else sem = '${sem}th';
} else {
sem = semester.trim();
}

return "$dept-$sem";
}
}
