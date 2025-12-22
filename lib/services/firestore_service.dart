
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/timetable_model.dart' show TimetableModel, ClassPeriod;

class FirestoreService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// User operations
Future<void> createUser(UserModel user) async {
await _firestore.collection('users').doc(user.uid).set(user.toMap());
}

Future<UserModel?> getUser(String uid) async {
try {
final doc = await _firestore.collection('users').doc(uid).get();
if (doc.exists && doc.data() != null) {
return UserModel.fromMap(doc.data()!);
}
return null;
} catch (e) {
print("Error getting user: $e");
return null;
}
}

Future<void> updateUser(UserModel user) async {
await _firestore.collection('users').doc(user.uid).update(user.toMap());
}

Stream<UserModel?> getUserStream(String uid) {
return _firestore
    .collection('users')
    .doc(uid)
    .snapshots()
    .map((doc) => doc.exists && doc.data() != null
? UserModel.fromMap(doc.data()!)
    : null);
}

// 🔥 FIXED: Timetable operations
Future<TimetableModel?> getTimetable(String day) async {
try {
final doc = await _firestore.collection('timetables').doc(day).get();

if (doc.exists && doc.data() != null) {
print("📅 Found timetable for $day");
return TimetableModel.fromMap(doc.data()!);
} else {
print("❌ No timetable found for $day");
return null;
}
} catch (e) {
print("🔥 Error fetching timetable for $day: $e");
return null;
}
}

Stream<TimetableModel?> getTimetableStream(String day) {
return _firestore
    .collection('timetables')
    .doc(day)
    .snapshots()
    .map((doc) {
if (doc.exists && doc.data() != null) {
return TimetableModel.fromMap(doc.data()!);
}
return null;
});
}

// 🔥 FIXED: Get timetable for ALL days
Future<Map<String, List<ClassPeriod>>> getWeeklyTimetable(
String department,
String semester,
) async {
final List<String> days = [
'Monday',
'Tuesday',
'Wednesday',
'Thursday',
'Friday',
'Saturday',
'Sunday'
];

final Map<String, List<ClassPeriod>> weeklySchedule = {};
final groupKey = _getGroupKey(department, semester);

print("🔍 Looking for group: $groupKey");
print("📅 Loading timetable for dept: $department, sem: $semester");

try {
// Fetch all days in sequence
for (final day in days) {
print("⏳ Fetching $day...");
final timetable = await getTimetable(day);

if (timetable != null) {
print("✅ Found timetable for $day");
print("📊 Available groups in $day: ${timetable.classes.keys.toList()}");

if (timetable.classes.containsKey(groupKey)) {
final classes = timetable.classes[groupKey]!;
// Sort by period
classes.sort((a, b) => a.period.compareTo(b.period));
weeklySchedule[day] = classes;
print("🎯 Found ${classes.length} classes for $groupKey on $day");
} else {
print("⚠️ No classes found for $groupKey on $day");
weeklySchedule[day] = [];
}
} else {
print("❌ No timetable document for $day");
weeklySchedule[day] = [];
}
}

print("📦 Weekly schedule loaded: $weeklySchedule");
} catch (e) {
print("🔥 Error in getWeeklyTimetable: $e");
// Initialize empty schedule for all days
for (final day in days) {
weeklySchedule[day] = [];
}
}

return weeklySchedule;
}

// Get today's classes
Future<List<ClassPeriod>> getTodayClasses(
String department,
String semester,
) async {
try {
final today = _getDayName(DateTime.now());
final timetable = await getTimetable(today);

if (timetable == null) return [];

final groupKey = _getGroupKey(department, semester);
final classes = timetable.classes[groupKey] ?? [];

classes.sort((a, b) => a.period.compareTo(b.period));
return classes;
} catch (e) {
print("Error fetching today's classes: $e");
return [];
}
}

// App settings
Future<bool> isHoliday() async {
try {
final doc = await _firestore.collection('app_settings').doc('settings').get();
if (doc.exists && doc.data() != null) {
return doc.data()!['isHoliday'] ?? false;
}
return false;
} catch (e) {
print("Error checking holiday: $e");
return false;
}
}

String _getDayName(DateTime date) {
const days = [
'Monday',
'Tuesday',
'Wednesday',
'Thursday',
'Friday',
'Saturday',
'Sunday'
];
return days[date.weekday - 1];
}

// 🔥 FIXED: Helper method to create group key
String _getGroupKey(String department, String semester) {
// Convert department to uppercase for consistency
String dept = department.trim().toUpperCase();

// Map common department names to Firestore keys
if (dept.contains('COMPUTER') || dept.contains('CST') || dept.contains('CSE')) {
dept = 'CST';
} else if (dept.contains('ELECTRONICS') || dept.contains('ETE')) {
dept = 'ET';
} else if (dept.contains('CIVIL')) {
dept = 'Civil';
} else if (dept.contains('ELECTRICAL') || dept.contains('EEE')) {
dept = 'ET';
} else if (dept.contains('MECHANICAL')) {
dept = 'ME';
} else if (dept.contains('ARCHITECTURE')) {
dept = 'ARCH';
}
// Keep as is if already in correct format
else if (dept == 'CT') {
dept = 'CT';
}

// Process semester
String sem = semester.trim();

// Remove any spaces
sem = sem.replaceAll(' ', '');

// Ensure proper suffix
if (!sem.toLowerCase().contains(RegExp(r'(st|nd|rd|th)'))) {
// Extract numeric part
final numericPart = sem.replaceAll(RegExp(r'[^0-9]'), '');
if (numericPart.isNotEmpty) {
final num = int.tryParse(numericPart);
if (num != null) {
if (num == 1) sem = '1st';
else if (num == 2) sem = '2nd';
else if (num == 3) sem = '3rd';
else sem = '${num}th';
}
}
}

// Your Firestore has keys like "CST-1st", "ET-4th", etc.
final groupKey = "$dept-$sem";
print("Generated group key: $groupKey");
return groupKey;
}
}
