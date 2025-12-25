
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../exam/presentation/screens/exam_routine.dart';
import '../features/ai_tools/presentation/screens/ai_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/intro_screen.dart';
import '../features/auth/presentation/screens/sing_in_screen.dart';
import '../features/auth/presentation/screens/sing_up_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/common/presentation/screens/main_nav_holder_screen.dart';
import '../features/routine/presentation/screens/routine_screen.dart';
import '../notice/presentation/screens/notice_screen.dart';
import '../resource/presentation/resource_screen.dart';

class AppRoutes {
  static Route<dynamic> route(RouteSettings setting) {
    late Widget widget;

    if (setting.name == SplashScreen.name) {
      widget = const SplashScreen();
    } else if (setting.name == IntroScreen.name) {
      widget = const IntroScreen();
    } else if (setting.name == SignInScreen.name) {
      widget = const SignInScreen();
    } else if (setting.name == SingUpScreen.name) {
      widget = const SingUpScreen();
    } else if (setting.name == MainNavHolderScreen.name) {
      widget = const MainNavHolderScreen();
    }else if (setting.name == AiScreen.name) {
      widget = const AiScreen();
    } else if (setting.name == RoutineScreen.name) {
      widget = const RoutineScreen();
    } else if (setting.name == ExamRoutine.name) {
      widget = const ExamRoutine();
    }else if (setting.name == NoticeScreen.name) {
      widget = const NoticeScreen();
    }else if (setting.name == ResourceScreen.name) {
      widget = const ResourceScreen();
    }else if (setting.name == ForgotPasswordScreen.name) {
      widget = const ForgotPasswordScreen();
    }
    return MaterialPageRoute(builder: (ctx) => widget);
  }
}