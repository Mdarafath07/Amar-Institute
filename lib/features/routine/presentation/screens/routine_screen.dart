import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/app_colors.dart';
import '../../../../providers/timetable_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../models/timetable_model.dart';
import 'package:intl/intl.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  static const String name = '/routine';

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  int _currentTabIndex = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = _getTodayIndex();
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _currentTabIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (mounted) {
          setState(() {
            _currentTabIndex = _tabController.index;
          });
        }
      } else {
        if (mounted && _currentTabIndex != _tabController.index) {
          setState(() {
            _currentTabIndex = _tabController.index;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimetable();
    });
  }

  int _getTodayIndex() {
    int index = DateTime.now().weekday - 1;
    return index >= 0 && index < 7 ? index : 0;
  }

  String _getTodayName() => DateFormat('EEEE').format(DateTime.now());

  Future<void> _loadTimetable() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      await Provider.of<TimetableProvider>(context, listen: false)
          .loadWeeklyTimetable(
        user.department,
        user.semester,
      );
    }
  }

  void _safeNavigateBack() {
    // Debounce mechanism to prevent multiple taps
    if (_isNavigating) return;
    _isNavigating = true;

    // Use rootNavigator for safety
    Navigator.of(context, rootNavigator: true).pop();

    // Reset after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _isNavigating = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timetableProvider = Provider.of<TimetableProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        // Handle Android back button
        _safeNavigateBack();
        return false; // Prevent default behavior
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
        body: Stack(
          children: [
            _buildDecorativeHeader(isDark),
            SafeArea(
              child: Column(
                children: [
                  _buildCuteAppBar(isDark),
                  _buildDaySelector(isDark),
                  Expanded(
                    child: Consumer<TimetableProvider>(
                      builder: (context, provider, child) {
                        final hasData = provider.getClassesForDay(_days[_currentTabIndex]).isNotEmpty;

                        if (provider.isWeeklyLoading && !hasData) {
                          return _buildLoadingWidget();
                        }

                        return TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          children: _days
                              .map((day) => _buildDayContent(day, isDark, provider))
                              .toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeHeader(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 200,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.themeColor.withOpacity(0.15),
              AppColors.themeColor.withOpacity(0.02),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuteAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Cute Back Button - FIXED
          InkWell(
            onTap: _safeNavigateBack,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : AppColors.themeColor,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Cute Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Class Routine",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Stay organized, stay ahead",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Cute Sync Button
          InkWell(
            onTap: () => _loadTimetable(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.themeColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.themeColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        tabs: _days.asMap().entries.map((entry) {
          int idx = entry.key;
          String day = entry.value;
          bool isSelected = _currentTabIndex == idx;
          bool isToday = day == _getTodayName();

          return Tab(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.themeColor
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppColors.themeColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isToday && !isSelected
                      ? AppColors.themeColor.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (isToday)
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: isSelected ? Colors.white : AppColors.themeColor,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    isToday ? "Today" : day.substring(0, 3),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayContent(String day, bool isDark, TimetableProvider provider) {
    final classes = provider.getClassesForDay(day);

    if (classes.isEmpty) {
      return _buildEmptyState(day, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: classes.length + 1,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        if (index == 0) return _buildStatsHeader(classes, day, isDark);

        final period = classes[index - 1];
        bool isToday = day == _getTodayName();
        bool isLive = isToday && _isCurrentlyRunning(period.startTime, period.endTime);
        bool isFinished = false;

        if (isToday) {
          try {
            final now = DateTime.now();
            final format = DateFormat.jm();
            final endDateTime = format.parse(period.endTime);
            final realEndTime = DateTime(now.year, now.month, now.day, endDateTime.hour, endDateTime.minute);
            isFinished = now.isAfter(realEndTime);
          } catch (_) {}
        }

        return _buildCuteClassCard(period, isDark, isLive, isFinished, isToday);
      },
    );
  }

  bool _isCurrentlyRunning(String start, String end) {
    try {
      final now = DateTime.now();
      final format = DateFormat.jm();
      final startTime = format.parse(start);
      final endTime = format.parse(end);

      final nowTime = format.parse(format.format(now));
      return nowTime.isAfter(startTime) && nowTime.isBefore(endTime);
    } catch (_) {
      return false;
    }
  }

  Widget _buildStatsHeader(List<ClassPeriod> classes, String day, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 5),
      child: Text(
        "${classes.length} Classes scheduled for ${day == _getTodayName() ? 'Today' : day}",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCuteClassCard(ClassPeriod period, bool isDark, bool isLive,
      bool isFinished, bool isToday) {
    String statusLabel = "UPCOMING";
    Color statusColor = const Color(0xFF3B82F6);

    if (isToday) {
      if (isLive) {
        statusLabel = "Running";
        statusColor = Colors.green;
      } else if (isFinished) {
        statusLabel = "FINISHED";
        statusColor = Colors.blueGrey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isLive ? statusColor.withOpacity(0.1) : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isLive ? statusColor.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 90,
                color: isLive
                    ? statusColor
                    : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      period.startTime,
                      style: TextStyle(
                        color: isLive ? Colors.white : AppColors.themeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isLive ? Colors.white54 : Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      period.endTime,
                      style: TextStyle(
                        color: isLive ? Colors.white70 : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statusTag(statusLabel, statusColor, isLive),
                          if (isLive) const _LiveBlink(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        period.courseCode ?? "Subject",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isFinished
                              ? Colors.grey
                              : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          decoration: isFinished ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _iconInfo(Icons.person_rounded, period.instructor ?? "TBA", isDark),
                          const SizedBox(width: 15),
                          _iconInfo(Icons.location_on_rounded, "Room ${period.room}", isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconInfo(IconData icon, String label, bool isDark) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.themeColor.withOpacity(0.6)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.blueGrey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTag(String label, Color color, bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String day, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.themeColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Text("🎉", style: TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 20),
          Text(
            "No classes on $day",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enjoy your free time!",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.themeColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading timetable...",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
          ),
          const SizedBox(height: 20),
          Text(
            "Failed to load timetable",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LiveBlink extends StatefulWidget {
  const _LiveBlink();

  @override
  State<_LiveBlink> createState() => _LiveBlinkState();
}

class _LiveBlinkState extends State<_LiveBlink>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}