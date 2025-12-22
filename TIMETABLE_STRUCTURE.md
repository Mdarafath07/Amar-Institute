# Timetable Data Structure Guide

This document describes the timetable structure based on the provided schedule images.

## Time Periods

All days have 8 periods with the following time slots:

- **Period 1**: 09:00 - 09:45
- **Period 2**: 09:45 - 10:30
- **Period 3**: 10:30 - 11:15
- **Period 4**: 11:15 - 12:00
- **Period 5**: 12:00 - 12:45
- **Period 6**: 12:45 - 01:30 (13:30)
- **Period 7**: 01:30 - 02:15 (13:30 - 14:15)
- **Period 8**: 02:15 - 03:00 (14:15 - 15:00)

## Group Keys Format

The timetable is organized by groups in the format: `{DEPARTMENT}-{SEMESTER}`

### Available Groups:

- **ET-1st** (Electronics Technology - 1st Semester)
- **ET-2nd** (Electronics Technology - 2nd Semester)
- **ET-4th** (Electronics Technology - 4th Semester)
- **ET-6th** (Electronics Technology - 6th Semester)
- **CT-1st** (Computer Technology - 1st Semester)
- **CT-2nd** (Computer Technology - 2nd Semester)
- **CT-4th** (Computer Technology - 4th Semester)
- **CT-6th** (Computer Technology - 6th Semester)
- **CST-1st** (Computer Science & Technology - 1st Semester)
- **CST-2nd** (Computer Science & Technology - 2nd Semester)
- **CST-4th** (Computer Science & Technology - 4th Semester)
- **CST-6th** (Computer Science & Technology - 6th Semester)

## Class Period Structure

Each class period contains:

```json
{
  "period": 1,
  "startTime": "09:00",
  "endTime": "09:45",
  "courseCode": "25711",
  "instructor": "AA",
  "room": "R-AUDI",
  "group": "ET-1st"
}
```

### Special Values:

- **PROJECT**: Indicates a project session
- **FIELD**: Indicates a field trip/excursion
- **Practice**: Indicates a practice session
- Empty cells: No class scheduled

## Room Codes

Common room codes found in the timetable:

- **R-AUDI**: Auditorium
- **R-301, R-302, R-303, R-305, R-306, R-307, R-308**: Regular classrooms
- **R-ET LAB**: Electronics Technology Laboratory
- **R-CT LAB**: Computer Technology Laboratory
- **R-CST LAB-1**: Computer Science & Technology Laboratory 1
- **R-CST LAB-2**: Computer Science & Technology Laboratory 2

## Example Firestore Document Structure

### For Saturday:

```json
{
  "day": "Saturday",
  "classes": {
    "ET-1st": [
      {
        "period": 1,
        "startTime": "09:00",
        "endTime": "09:45",
        "courseCode": "25711",
        "instructor": "AA",
        "room": "R-AUDI",
        "group": "ET-1st"
      },
      {
        "period": 2,
        "startTime": "09:45",
        "endTime": "10:30",
        "courseCode": "26711",
        "instructor": "SD",
        "room": "R-AUDI",
        "group": "ET-1st"
      }
    ],
    "ET-2nd": [...],
    "CT-1st": [...],
    // ... other groups
  }
}
```

## Setting Up Timetable Data

1. Create a document in the `timetables` collection for each day
2. Document ID should be the day name: `Monday`, `Tuesday`, etc.
3. Add all groups and their respective class periods
4. Ensure time format is `HH:mm` (24-hour format)

## Notes

- Times like `01:30` should be stored as `13:30` in the database for consistency
- Empty periods can be omitted from the array
- The app will automatically filter classes based on the user's department and semester

