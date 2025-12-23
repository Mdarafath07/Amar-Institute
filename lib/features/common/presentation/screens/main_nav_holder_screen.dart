import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import '../../../../app/app_colors.dart';
import '../../../../notice/presentation/screens/notice_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../routine/presentation/screens/routine_screen.dart';
import '../../../ai_tools/presentation/screens/ai_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainNavHolderScreen extends StatefulWidget {
  const MainNavHolderScreen({super.key});
  static const String name = '/main-bottom-nav-holder';

  @override
  State<MainNavHolderScreen> createState() => _MainNavHolderScreenState();
}

class _MainNavHolderScreenState extends State<MainNavHolderScreen> with WidgetsBindingObserver {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List<Widget> _screens = [
    const HomeScreen(),
    const RoutineScreen(),
    const NoticeScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App background এ যাচ্ছে
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        // Always minimize app when back is pressed
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _page,
          children: _screens,
        ),
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _page,
          height: 60.0,
          items: <Widget>[
            Icon(Icons.home_rounded, size: 30, color: _page == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
            Icon(Icons.calendar_today_rounded, size: 30, color: _page == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
            Icon(Icons.notifications_active, size: 30, color: _page == 2 ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
            Icon(Icons.person_rounded, size: 30, color: _page == 3 ? Colors.white : (isDark ? Colors.white70 : Colors.black54)),
          ],
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          buttonBackgroundColor: AppColors.themeColor,
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 600),
          onTap: (index) {
            setState(() {
              _page = index;
            });
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}