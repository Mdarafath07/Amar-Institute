# Amar Institute - Student Management App

A high-end, animated Flutter app for student management with Firebase, Gemini AI integration, and modern UI/UX.

## Features

- 🔐 **Advanced Authentication**: Glassmorphic login/signup with Firebase Auth
- 📅 **Live Timetable Tracker**: Real-time class tracking with automatic updates
- 🤖 **AI Study Assistant**: Powered by Google Gemini AI
- 📸 **Profile Management**: Image upload using ImageBB API
- 🎨 **Modern UI/UX**: Deep Midnight theme with dark/light mode support
- ✨ **Smooth Animations**: Staggered animations and Hero transitions
- 📱 **Responsive Design**: Beautiful glassmorphic design elements

## Tech Stack

- **Framework**: Flutter 3.10.3+
- **State Management**: Provider
- **Backend**: Firebase Auth & Firestore
- **AI Integration**: Google Gemini AI
- **Image Hosting**: ImageBB API
- **Networking**: Dio
- **Animations**: flutter_staggered_animations

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.10.3 or higher)
- Firebase project set up
- Google AI Studio account (for Gemini API)

### 2. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Create a Firestore database
4. Download `google-services.json` and place it in `android/app/`
5. Update `lib/firebase_options.dart` with your Firebase configuration

### 3. Firestore Structure

Create the following collections in Firestore:

#### Users Collection (`users/{userId}`)
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "department": "string (e.g., ET, CT, CST)",
  "semester": "string (e.g., 1st, 2nd, 4th, 6th)",
  "profileImageUrl": "string (optional)",
  "rollNo": "string (optional)",
  "regNo": "string (optional)",
  "phoneNumber": "string (optional)"
}
```

#### Timetables Collection (`timetables/{dayName}`)
```json
{
  "day": "Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday",
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
      }
    ],
    "CT-2nd": [...],
    "CST-4th": [...]
  }
}
```

#### App Settings Collection (`app_settings/settings`)
```json
{
  "isHoliday": false
}
```

### 4. Gemini AI Setup

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key
3. Update `lib/services/gemini_service.dart`:
   ```dart
   static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

### 5. ImageBB API

The ImageBB API key is already configured: `6f0ead1d22839466563ab662627b87b6`

### 6. Install Dependencies

```bash
flutter pub get
```

### 7. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── app/                    # App configuration
│   ├── app_colors.dart
│   ├── app_routes.dart
│   ├── app_theme.dart
│   └── app.dart
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── home/              # Home screen
│   ├── routine/           # Timetable/Routine
│   ├── ai_tools/          # AI Study Assistant
│   ├── profile/           # User Profile
│   └── common/            # Shared components
├── models/                # Data models
│   ├── user_model.dart
│   └── timetable_model.dart
├── providers/             # State management
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── timetable_provider.dart
│   └── theme_provider.dart
└── services/              # Business logic
    ├── auth_service.dart
    ├── firestore_service.dart
    ├── gemini_service.dart
    └── imagebb_service.dart
```

## Key Features Explained

### Live Timetable Tracker

The app automatically tracks running classes and upcoming classes based on the current time. Classes are displayed in animated cards that update in real-time.

### Holiday Logic

When `isHoliday` is set to `true` in Firestore (`app_settings/settings`), the timetable is replaced with a beautiful holiday message.

### Department & Semester Mapping

The app maps user departments and semesters to timetable groups:
- `ET-1st`, `ET-2nd`, `ET-4th`, `ET-6th` (Electronics Technology)
- `CT-1st`, `CT-2nd`, `CT-4th`, `CT-6th` (Computer Technology)
- `CST-1st`, `CST-2nd`, `CST-4th`, `CST-6th` (Computer Science & Technology)

### Real-time Updates

The app uses Firestore streams for real-time updates. Changes made in the admin panel will reflect immediately in the student app without requiring a restart.

## Troubleshooting

### Gemini AI not working
- Ensure you've set your API key in `lib/services/gemini_service.dart`
- Check your API key quota in Google AI Studio

### Image upload failing
- Check internet connection
- Verify ImageBB API key is correct
- Ensure proper file permissions on device

### Timetable not showing
- Verify Firestore structure matches the expected format
- Check department and semester values match timetable group keys
- Ensure `isHoliday` is set to `false` in app_settings

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is for educational purposes.
