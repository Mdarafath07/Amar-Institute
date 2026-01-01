# Amar Institute - Student Management App

A high-end, animated Flutter app for student management with Firebase, Gemini AI integration, and modern UI/UX.

## Features

-  **Advanced Authentication**: Glassmorphic login/signup with Firebase Auth
-  **Live Timetable Tracker**: Real-time class tracking with automatic updates
-  **AI Study Assistant**: Powered by Google Gemini AI
-  **Profile Management**: Image upload using ImageBB API
-  **Modern UI/UX**: Deep Midnight theme with dark/light mode support
-  **Smooth Animations**: Staggered animations and Hero transitions
-  **Responsive Design**: Beautiful glassmorphic design elements

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


## Key Features Explained

### Live Timetable Tracker

The app automatically tracks running classes and upcoming classes based on the current time. Classes are displayed in animated cards that update in real-time.

### Holiday Logic

When `isHoliday` is set to `true` in Firestore (`app_settings/settings`), the timetable is replaced with a beautiful holiday message.

### Department & Semester Mapping

The app maps user departments and semesters to timetable groups:
- `ET-1st`, `ET-2nd`,`ET-3rd`, `ET-4th`,`ET-5th`, `ET-6th`,`ET-7th`,`ET-8th` (Electronics Technology)
- `CT-1st`, `CT-2nd`,`CT-3rd`, `CT-4th`,`CT-5th`, `CT-6th`,`CT-7th`,`CT-8th` (Computer Technology)
- `CST-1st`, `CST-2nd`,`CST-3rd`, `CST-4th`,`CT-5th`, `CST-6th`,`CST-7th`,`CST-8th`  (Computer Science & Technology)

### Real-time Updates

The app uses Firestore streams for real-time updates. Changes made in the admin panel will reflect immediately in the student app without requiring a restart.



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
