import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/screens/splash_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/timetable_provider.dart';
import '../providers/theme_provider.dart';

import 'app_routes.dart';
import 'app_theme.dart';

class AmarInstitute extends StatefulWidget {
  const AmarInstitute({super.key});

  @override
  State<AmarInstitute> createState() => _AmarInstituteState();
}

class _AmarInstituteState extends State<AmarInstitute> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            initialRoute: SplashScreen.name,
            onGenerateRoute: AppRoutes.route,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
