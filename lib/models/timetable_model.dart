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

  DateTime get startDateTime {
    final timeParts = startTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  DateTime get endDateTime {
    final timeParts = endTime.split(':');
    final now = DateTime.now();
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    // Handle 01:30 as 13:30
    if (hour < 9) hour += 12;
    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
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

