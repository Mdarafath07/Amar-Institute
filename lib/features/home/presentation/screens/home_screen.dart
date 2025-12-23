import 'dart:async';
import 'package:amar_institute/app/assets_path.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../app/app_colors.dart';
import '../../../../exam/presentation/screens/exam_routine.dart';
import '../../../../notice/presentation/screens/notice_screen.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../providers/timetable_provider.dart';
import '../../../../models/timetable_model.dart';
import '../../../../resource/presentation/resource_screen.dart';
import '../../../ai_tools/presentation/screens/ai_screen.dart';
import '../../../routine/presentation/screens/routine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const name = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    // Real-time update every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshTimetableData();
    });
  }

  Future<void> _loadInitialData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);
    final timetable = Provider.of<TimetableProvider>(context, listen: false);

    if (auth.user != null) {
      await user.loadUser(auth.user!.uid);
      await timetable.loadTimetable(
        auth.user!.department,
        auth.user!.semester,
      );
    }
  }

  Future<void> _refreshTimetableData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final timetable = Provider.of<TimetableProvider>(context, listen: false);

    if (auth.user != null && mounted) {
      // Silent refresh for real-time updates
      await timetable.loadTimetable(
        auth.user!.department,
        auth.user!.semester,

      );
      // Only update UI if widget is still mounted
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _handleRefresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);
    final timetable = Provider.of<TimetableProvider>(context, listen: false);

    if (auth.user != null) {
      // Refresh user data
      await user.loadUser(auth.user!.uid);
      // Refresh timetable data
      await timetable.loadTimetable(
        auth.user!.department,
        auth.user!.semester,

      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Consumer2<UserProvider, TimetableProvider>(
      builder: (context, userProvider, timetableProvider, _) {
        final user = userProvider.user;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(
              0xFFF0F4FF),

          /// 🔥 Big transparent Lottie FAB
          floatingActionButton: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AiScreen()));
            },
            child: SizedBox(
              height: 100,
              width: 100,
              child: Lottie.asset(
                'assets/lottie/robo.json',
                fit: BoxFit.contain,
              ),
            ),
          ),

          body: RefreshIndicator(
            key: _refreshIndicatorKey,
            color: AppColors.themeColor,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            strokeWidth: 3.0,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildSliverAppBar(user, isDark),

                /// Rounded body
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(
                          0xFFF0F4FF),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                              "Live Timetable", Icons.not_started_outlined),
                          const SizedBox(height: 16),
                          _buildLiveTimetable(timetableProvider, isDark),
                          const SizedBox(height: 32),
                          _sectionHeader("Campus Services",
                              Icons.auto_awesome_mosaic_rounded),
                          _quickActions(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= HEADER =================

  Widget _buildSliverAppBar(dynamic user, bool isDark) {
    return SliverAppBar(
      expandedHeight: 170.0,
      pinned: true,
      stretch: true,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.themeColor,
      title: LayoutBuilder(builder: (context, constraints) {
        var top = constraints.biggest.height;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: top <= (MediaQuery
              .of(context)
              .padding
              .top + kToolbarHeight + 10) ? 1.0 : 0.0,
          child: Text(
            user?.name ?? "Student",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }),
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
        child: FlexibleSpaceBar(
          collapseMode: CollapseMode.parallax,
          background: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [
                      AppColors.themeColor,
                      AppColors.themeColor.withOpacity(0.7)
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -20,
                right: -20,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.07),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 50,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 75, 20, 25),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white24,
                        backgroundImage: user?.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl)
                            : null,
                        child: user?.profileImageUrl == null
                            ? const Icon(
                            Icons.person, size: 38, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name ?? "Student",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white24, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_outlined, size: 14,
                                    color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  "${user?.department ?? 'N/A'} • ${user
                                      ?.semester ?? 'N/A'}",
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LIVE TIMETABLE =================

  Widget _buildLiveTimetable(TimetableProvider provider, bool isDark) {

    if (provider.isHoliday) {
      return _statusCard("Holiday 🎉", "Take rest & recharge", Icons.celebration,
          Colors.orange);
    }

    if (provider.todayClasses.isEmpty) {
      return _statusCard(
          "No Classes", "Self-study is the best study", Icons.auto_awesome,
          Colors.blue);
    }


    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
          const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        return AnimationLimiter(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.todayClasses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = provider.todayClasses[index];
              // Real-time check with current time
              final running = _isCurrentlyRunning(item.startTime, item.endTime);
              final finished = _isFinished(item.endTime);
              final accent = running
                  ? Colors.greenAccent.shade700
                  : finished
                  ? Colors.grey
                  : AppColors.themeColor;

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 600),
                child: SlideAnimation(
                  verticalOffset: 40,
                  child: FadeInAnimation(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors
                            .white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.18),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(width: 6, color: accent),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          running ? "LIVE NOW" : finished
                                              ? "FINISHED"
                                              : "NEXT CLASS",
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: accent),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.courseCode ?? "Subject",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Room ${item.room} • ${item
                                              .instructor ?? 'N/A'}",
                                          style: TextStyle(fontSize: 13,
                                              color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      children: [
                                        Text("${item.startTime} -",
                                            style: TextStyle(fontSize: 12,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87)),
                                        Text(item.endTime,
                                            style: TextStyle(fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: accent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  bool _isCurrentlyRunning(String start, String end) {
    try {
      final now = DateTime.now();
      final format = DateFormat('hh:mm a');
      final startTime = format.parse(start);
      final endTime = format.parse(end);

      final nowTime = format.parse(format.format(now));
      return nowTime.isAfter(startTime) && nowTime.isBefore(endTime);
    } catch (_) {
      return false;
    }
  }

  bool _isFinished(String end) {
    try {
      final now = DateTime.now();
      final format = DateFormat('hh:mm a');
      final endTime = format.parse(end);
      final nowTime = format.parse(format.format(now));
      return nowTime.isAfter(endTime);
    } catch (_) {
      return false;
    }
  }

  // ================= QUICK ACTIONS =================

  Widget _quickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _action("Routine", Icons.calendar_month_rounded,
                Colors.orangeAccent, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RoutineScreen()),
                  );
                }, isDark),
            _action("Exams", Icons.menu_book_rounded, Colors.redAccent, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExamRoutine()),
              );
            }, isDark),
            _action(
                "Resource", Icons.local_library_rounded, Colors.blueAccent, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ResourceScreen()),
              );
            }, isDark),
            _action(
                "Notice", Icons.notifications_active_rounded, Colors.teal, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NoticeScreen()),
              );
            }, isDark),
            _action("Game Zone", Icons.sports_esports_rounded,
                Colors.pinkAccent, () {
                  _showComingSoon("Game Center");
                }, isDark),
          ],
        ),
      ],
    );
  }

  Widget _action(String title, IconData icon, Color color, VoidCallback onTap,
      bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(
                0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.05 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$featureName is coming soon!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.themeColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.themeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.themeColor),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statusCard(String t, String s, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.withOpacity(0.12), c.withOpacity(
            0.05)
        ]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Icon(i, size: 48, color: c),
          const SizedBox(height: 16),
          Text(t, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(s, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime
        .now()
        .hour;
    if (h < 5) return "Good Night 🌙";
    if (h < 12) return "Good Morning ☀️";
    if (h < 17) return "Good Afternoon 🌤️";
    return "Good Evening ✨";
  }
}