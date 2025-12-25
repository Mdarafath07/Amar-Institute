import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timetable_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

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

  // Caching keys
  static const String _cachedTodayClassesKey = 'cached_today_classes';
  static const String _cachedWeeklyClassesKey = 'cached_weekly_classes';
  static const String _cachedHolidayKey = 'cached_is_holiday';
  static const String _cachedDepartmentKey = 'cached_department';
  static const String _cachedSemesterKey = 'cached_semester';
  static const String _cachedTimestampKey = 'cached_timestamp';

  // Stream Controller for real-time updates
  final StreamController<Map<String, dynamic>> _timetableStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  List<ClassPeriod> get todayClasses => _todayClasses;
  Map<String, List<ClassPeriod>> get weeklyClasses => _weeklyClasses;
  bool get isHoliday => _isHoliday;
  bool get isLoading => _isLoading;
  bool get isWeeklyLoading => _isWeeklyLoading;
  String? get errorMessage => _errorMessage;

  // Getter for stream
  Stream<Map<String, dynamic>> get timetableStream => _timetableStreamController.stream;

  // Method to update stream
  void _updateStream() {
    if (!_timetableStreamController.isClosed && _timetableStreamController.hasListener) {
      _timetableStreamController.add({
        'weeklyClasses': Map<String, List<ClassPeriod>>.from(_weeklyClasses),
        'todayClasses': List<ClassPeriod>.from(_todayClasses),
        'isHoliday': _isHoliday,
        'isLoading': _isLoading,
        'isWeeklyLoading': _isWeeklyLoading,
        'errorMessage': _errorMessage,
      });
    }
  }

  // Load today's timetable
  Future<void> loadTimetable(String department, String semester) async {
    _isLoading = true;
    _errorMessage = null;
    _currentDepartment = department;
    _currentSemester = semester;
    notifyListeners();
    _updateStream();

    try {
      print("Loading timetable for: $department, $semester");

      // Check holiday
      _isHoliday = await _firestoreService.isHoliday();
      if (_isHoliday) {
        print("🎉 It's a holiday!");
        _todayClasses = [];
        _isLoading = false;
        notifyListeners();
        _updateStream();
        // Cache holiday status
        await _saveToCache();
        return;
      }

      // Get today's classes
      _todayClasses = await _firestoreService.getTodayClasses(department, semester);

      print(" Loaded ${_todayClasses.length} classes for today");

      // Schedule notifications for today's classes
      if (_todayClasses.isNotEmpty) {
        _scheduleNotificationsForToday();
      }

      // Cache the data
      await _saveToCache();

      _isLoading = false;
      notifyListeners();
      _updateStream();

    } catch (e) {
      print("❌ Error loading timetable: $e");

      // Firebase ব্যর্থ হলে cache থেকে load করুন
      final cachedLoaded = await loadCachedTimetable();
      if (!cachedLoaded) {
        _errorMessage = "Failed to load timetable: $e";
        _todayClasses = [];
      }

      _isLoading = false;
      notifyListeners();
      _updateStream();
    }
  }

  // ✅ NEW: Load cached timetable data (offline mode)
  Future<bool> loadCachedTimetable() async {
    try {
      print('🔄 Loading timetable from cache...');
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists and is not too old (24 hours)
      final cachedTimestamp = prefs.getInt(_cachedTimestampKey);
      if (cachedTimestamp != null) {
        final cacheAge = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(cachedTimestamp));
        if (cacheAge.inHours > 24) {
          print('⚠️ Cache is too old (${cacheAge.inHours} hours), ignoring');
          return false;
        }
      }

      final cachedTodayClassesJson = prefs.getString(_cachedTodayClassesKey);
      final cachedWeeklyClassesJson = prefs.getString(_cachedWeeklyClassesKey);
      final cachedHoliday = prefs.getBool(_cachedHolidayKey);
      final cachedDept = prefs.getString(_cachedDepartmentKey);
      final cachedSem = prefs.getString(_cachedSemesterKey);

      if (cachedTodayClassesJson != null && cachedTodayClassesJson.isNotEmpty) {
        try {
          // Decode today's classes
          final List<dynamic> todayJsonList = jsonDecode(cachedTodayClassesJson);
          _todayClasses = todayJsonList.map((json) => ClassPeriod.fromJson(json)).toList();

          // Decode weekly classes
          if (cachedWeeklyClassesJson != null && cachedWeeklyClassesJson.isNotEmpty) {
            final Map<String, dynamic> weeklyJsonMap = jsonDecode(cachedWeeklyClassesJson);
            _weeklyClasses = {};
            weeklyJsonMap.forEach((day, classesJson) {
              if (classesJson is List) {
                _weeklyClasses[day] = classesJson.map((json) => ClassPeriod.fromJson(json)).toList();
              }
            });
          }

          // Set other cached values
          _isHoliday = cachedHoliday ?? false;
          _currentDepartment = cachedDept;
          _currentSemester = cachedSem;

          print('✅ Cached timetable loaded: ${_todayClasses.length} today classes');
          return true;
        } catch (parseError) {
          print('❌ Error parsing cached timetable JSON: $parseError');
          // Corrupted cache ডিলিট করুন
          await _clearCache();
          return false;
        }
      } else {
        print('⚠️ No cached timetable data found');
        return false;
      }
    } catch (e) {
      print('❌ Error loading cached timetable: $e');
      return false;
    }
  }

  // ✅ NEW: Save data to cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Encode today's classes
      final todayJsonList = _todayClasses.map((classPeriod) => classPeriod.toJson()).toList();
      await prefs.setString(_cachedTodayClassesKey, jsonEncode(todayJsonList));

      // Encode weekly classes
      final weeklyJsonMap = {};
      _weeklyClasses.forEach((day, classes) {
        weeklyJsonMap[day] = classes.map((classPeriod) => classPeriod.toJson()).toList();
      });
      await prefs.setString(_cachedWeeklyClassesKey, jsonEncode(weeklyJsonMap));

      // Save other data
      await prefs.setBool(_cachedHolidayKey, _isHoliday);
      await prefs.setString(_cachedDepartmentKey, _currentDepartment ?? '');
      await prefs.setString(_cachedSemesterKey, _currentSemester ?? '');
      await prefs.setInt(_cachedTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('💾 Timetable saved to cache');
    } catch (e) {
      print('❌ Error saving timetable to cache: $e');
    }
  }

  // ✅ NEW: Clear cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedTodayClassesKey);
      await prefs.remove(_cachedWeeklyClassesKey);
      await prefs.remove(_cachedHolidayKey);
      await prefs.remove(_cachedDepartmentKey);
      await prefs.remove(_cachedSemesterKey);
      await prefs.remove(_cachedTimestampKey);
      print('🗑️ Timetable cache cleared');
    } catch (e) {
      print('❌ Error clearing timetable cache: $e');
    }
  }

  // ✅ NEW: Check if cache exists
  Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTodayClassesJson = prefs.getString(_cachedTodayClassesKey);
      return cachedTodayClassesJson != null && cachedTodayClassesJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Schedule notifications for today's classes
  void _scheduleNotificationsForToday() async {
    try {
      // Initialize notification service
      await ClassNotificationService().initialize();

      // Schedule notifications
      await ClassNotificationService().checkAndScheduleNotifications(_todayClasses);
      print('🎯 Notifications scheduled for ${_todayClasses.length} classes');
    } catch (e) {
      print('⚠️ Error scheduling notifications: $e');
    }
  }

  // Load weekly timetable
  Future<void> loadWeeklyTimetable(String department, String semester) async {
    _isWeeklyLoading = true;
    _errorMessage = null;
    _currentDepartment = department;
    _currentSemester = semester;
    notifyListeners();
    _updateStream();

    try {
      print("🔄 Loading WEEKLY timetable for: $department, $semester");

      // Check holiday
      _isHoliday = await _firestoreService.isHoliday();
      if (_isHoliday) {
        print("🎉 Weekly holiday detected!");
        _weeklyClasses = {};
        _isWeeklyLoading = false;
        notifyListeners();
        _updateStream();
        return;
      }

      // Get weekly timetable
      _weeklyClasses = await _firestoreService.getWeeklyTimetable(department, semester);

      // Print summary
      print("📊 Weekly timetable summary:");
      _weeklyClasses.forEach((day, classes) {
        print("  $day: ${classes.length} classes");
      });

      // Cache the data
      await _saveToCache();

      _isWeeklyLoading = false;
      notifyListeners();
      _updateStream();

    } catch (e) {
      print("❌ Error loading weekly timetable: $e");
      _errorMessage = "Failed to load weekly timetable: $e";
      _weeklyClasses = {};
      _isWeeklyLoading = false;
      notifyListeners();
      _updateStream();
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
    _updateStream();
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

  // Close stream controller when provider is disposed
  @override
  void dispose() {
    if (!_timetableStreamController.isClosed) {
      _timetableStreamController.close();
    }
    super.dispose();
  }
}