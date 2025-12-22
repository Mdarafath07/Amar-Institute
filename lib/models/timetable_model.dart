import 'package:intl/intl.dart';

class TimetableModel {
  final String day;
  final Map<String, List<ClassPeriod>> classes; // Key: "ET-1st", "CT-2nd", etc.

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
}

class ClassPeriod {
  final int period;
  final String startTime;
  final String endTime;
  final String? courseCode;
  final String? instructor;
  final String? room;
  final String? group; // ET-1st, CT-2nd, etc.

  ClassPeriod({
    required this.period,
    required this.startTime,
    required this.endTime,
    this.courseCode,
    this.instructor,
    this.room,
    this.group,
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
    };
  }

  factory ClassPeriod.fromMap(Map<String, dynamic> map) {
    return ClassPeriod(
      period: map['period'] ?? 0,
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      courseCode: map['courseCode'],
      instructor: map['instructor'],
      room: map['room'],
      group: map['group'],
    );
  }

  // ফিক্সড: int.parse এর বদলে DateFormat ব্যবহার করা হয়েছে
  DateTime get startDateTime {
    final now = DateTime.now();
    try {
      // এটি "09:30 AM" ফরম্যাট পার্স করবে
      DateTime parsedTime = DateFormat("hh:mm a").parse(startTime);
      return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
    } catch (e) {
      // ব্যাকআপ: যদি শুধু "09:30" থাকে
      try {
        DateTime parsedTime = DateFormat("HH:mm").parse(startTime);
        return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      } catch (e) {
        return DateTime(now.year, now.month, now.day, 0, 0);
      }
    }
  }

  DateTime get endDateTime {
    final now = DateTime.now();
    try {
      DateTime parsedTime = DateFormat("hh:mm a").parse(endTime);
      return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
    } catch (e) {
      try {
        DateTime parsedTime = DateFormat("HH:mm").parse(endTime);
        return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      } catch (e) {
        return DateTime(now.year, now.month, now.day, 23, 59);
      }
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
}