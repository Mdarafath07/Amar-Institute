// models/timetable_model.dart
import 'package:intl/intl.dart';

class TimetableModel {
  final String day;
  final Map<String, List<ClassPeriod>> classes;

  TimetableModel({
    required this.day,
    required this.classes,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> classesMap = {};
    classes.forEach((key, value) {
      classesMap[key] = value.map((e) => e.toMap()).toList();
    });
    return {
      'day': day,
      'classes': classesMap,
    };
  }

  factory TimetableModel.fromMap(Map<String, dynamic> map) {
    final Map<String, List<ClassPeriod>> classesMap = {};
    if (map['classes'] != null) {
      (map['classes'] as Map).forEach((key, value) {
        classesMap[key] = (value as List)
            .map((e) => ClassPeriod.fromMap(e))
            .toList();
      });
    }
    return TimetableModel(
      day: map['day'] ?? '',
      classes: classesMap,
    );
  }

  // ✅ JSON থেকে TimetableModel তৈরি করার মেথড
  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    final Map<String, List<ClassPeriod>> classesMap = {};
    if (json['classes'] != null && json['classes'] is Map) {
      (json['classes'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          classesMap[key] = value.map((e) => ClassPeriod.fromJson(e)).toList();
        }
      });
    }
    return TimetableModel(
      day: json['day'] ?? '',
      classes: classesMap,
    );
  }

  // ✅ TimetableModel থেকে JSON তৈরি করার মেথড
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> classesMap = {};
    classes.forEach((key, value) {
      classesMap[key] = value.map((e) => e.toJson()).toList();
    });
    return {
      'day': day,
      'classes': classesMap,
    };
  }
}

class ClassPeriod {
  final int period;
  final String startTime;
  final String endTime;
  final String courseCode;
  final String instructor;
  final String room;
  final String group;
  final String day;

  ClassPeriod({
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.courseCode,
    required this.instructor,
    required this.room,
    required this.group,
    required this.day,
  });

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'startTime': startTime,
      'endTime': endTime,
      'courseCode': courseCode,
      'instructor': instructor,
      'room': room,
      'group': group,
      'day': day,
    };
  }

  factory ClassPeriod.fromMap(Map<String, dynamic> map) {
    return ClassPeriod(
      day: map['day']?.toString() ?? '',
      period: map['period'] is int ? map['period'] : int.tryParse(map['period']?.toString() ?? '0') ?? 0,
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      courseCode: map['courseCode'] ?? '',
      instructor: map['instructor'] ?? '',
      room: map['room'] ?? '',
      group: map['group'] ?? '',
    );
  }

  // ✅ JSON থেকে ClassPeriod তৈরি করার মেথড
  factory ClassPeriod.fromJson(Map<String, dynamic> json) {
    return ClassPeriod(
      day: json['day']?.toString() ?? '',
      period: json['period'] is int ? json['period'] : int.tryParse(json['period']?.toString() ?? '0') ?? 0,
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
    );
  }

  // ✅ ClassPeriod থেকে JSON তৈরি করার মেথড
  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'startTime': startTime,
      'endTime': endTime,
      'courseCode': courseCode,
      'instructor': instructor,
      'room': room,
      'group': group,
      'day': day,
    };
  }

  DateTime get startDateTime {
    try {
      final now = DateTime.now();
      final format = DateFormat('hh:mm a');
      final parsedTime = format.parse(startTime);
      return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime get endDateTime {
    try {
      final now = DateTime.now();
      final format = DateFormat('hh:mm a');
      final parsedTime = format.parse(endTime);
      return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
    } catch (e) {
      return DateTime.now().add(const Duration(hours: 1));
    }
  }

  bool get isCurrentlyRunning {
    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startDateTime);
  }

  bool get isCompleted {
    final now = DateTime.now();
    return now.isAfter(endDateTime);
  }

  String get id {
    return '$day-$period-$courseCode';
  }

  @override
  String toString() {
    return 'ClassPeriod{period: $period, courseCode: $courseCode, time: $startTime-$endTime, room: $room}';
  }

  ClassPeriod copyWith({
    String? day,
    int? period,
    String? startTime,
    String? endTime,
    String? courseCode,
    String? instructor,
    String? room,
    String? group,
  }) {
    return ClassPeriod(
      day: day ?? this.day,
      period: period ?? this.period,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      courseCode: courseCode ?? this.courseCode,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      group: group ?? this.group,
    );
  }
}