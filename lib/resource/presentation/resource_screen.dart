import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../app/app_theme.dart';
import '../../providers/user_provider.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  static const name = '/resource';

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  String _userDepartment = '';
  String _userSemester = '';
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      debugPrint("Loading user information...");


      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;

        if (user != null && user.department != null && user.semester != null) {
          debugPrint("UserProvider Data: ${user.department}, ${user.semester}");
          setState(() {
            _userDepartment = user.department!;
            _userSemester = user.semester!;
            _isLoading = false;
          });


          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userDepartment', _userDepartment);
          await prefs.setString('userSemester', _userSemester);
          return;
        }
      } catch (e) {
        debugPrint("UserProvider error: $e");
      }


      final prefs = await SharedPreferences.getInstance();
      final prefDept = prefs.getString('userDepartment');
      final prefSem = prefs.getString('userSemester');

      if (prefDept != null && prefSem != null) {
        debugPrint("SharedPreferences Data: $prefDept, $prefSem");
        setState(() {
          _userDepartment = prefDept;
          _userSemester = prefSem;
          _isLoading = false;
        });
        return;
      }

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint("Loading from Firebase for UID: ${currentUser.uid}");
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final dept = data['department']?.toString() ?? 'CST';
          final sem = data['semester']?.toString() ?? '1st';

          debugPrint("Firebase Data: $dept, $sem");


          await prefs.setString('userDepartment', dept);
          await prefs.setString('userSemester', sem);

          setState(() {
            _userDepartment = dept;
            _userSemester = sem;
            _isLoading = false;
          });
          return;
        } else {
          debugPrint("User document doesn't exist in Firebase");
        }
      } else {
        debugPrint("No user logged in");
      }


      debugPrint("Using default values: CST, 1st");
      setState(() {
        _userDepartment = 'CST';
        _userSemester = '1st';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading user info: $e");
      setState(() {
        _userDepartment = 'CST';
        _userSemester = '1st';
        _isLoading = false;
      });
    }
  }


  Future<void> _openLink(String urlString) async {
    if (urlString.isEmpty) {
      _showSnackBar("Link is empty", Colors.orange);
      return;
    }

    try {
      String processedUrl = urlString.trim();
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://') &&
          !processedUrl.startsWith('tel:') &&
          !processedUrl.startsWith('mailto:')) {
        processedUrl = 'https://$processedUrl';
      }

      final Uri url = Uri.parse(processedUrl);
      try {
        bool launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        if (!launched) await _launchUrlAlternative(url);
      } catch (e) {
        await _launchUrlAlternative(url);
      }
    } catch (e) {
      debugPrint("Link Error: $e");
      _showSnackBar("Could not open link.", Colors.red);
    }
  }

  Future<void> _launchUrlAlternative(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      _showSnackBar("Failed to open link.", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text(message, style: TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _isResourceForUser(Map<String, dynamic> data) {
    try {
      String department = (data['department'] ?? 'All').toString();
      String semester = (data['semester'] ?? 'All').toString();
      String targetType = (data['targetType'] ?? 'all').toString();

      debugPrint(
          "Checking resource - Dept: $department, Sem: $semester, Type: $targetType");
      debugPrint("Against user - Dept: $_userDepartment, Sem: $_userSemester");

      switch (targetType.toLowerCase()) {
        case 'all':
          debugPrint("Resource is for all users: true");
          return true;

        case 'department':
          bool match = department == _userDepartment;
          debugPrint(
              "Department check: $match (required: $department, user: $_userDepartment)");
          return match;

        case 'semester':
          bool match = semester == _userSemester;
          debugPrint(
              "Semester check: $match (required: $semester, user: $_userSemester)");
          return match;

        case 'specific':
          bool match =
              department == _userDepartment && semester == _userSemester;
          debugPrint(
              "Specific check: $match (Dept: $department/$_userDepartment, Sem: $semester/$_userSemester)");
          return match;

        default:
          debugPrint("Unknown target type, defaulting to true");
          return true;
      }
    } catch (e) {
      debugPrint("Error in _isResourceForUser: $e");
      return false;
    }
  }

  String _getTargetLabel(Map<String, dynamic> data) {
    String targetType = data['targetType'] ?? 'all';
    String department = data['department'] ?? 'All';
    String semester = data['semester'] ?? 'All';

    switch (targetType) {
      case 'all':
        return 'For All Students';
      case 'department':
        return department == 'All' ? 'All Departments' : 'For $department Dept';
      case 'semester':
        return semester == 'All' ? 'All Semesters' : 'For $semester Semester';
      case 'specific':
        if (department == 'All' && semester == 'All') return 'For Everyone';
        if (department == 'All') return 'All Depts • $semester Sem';
        if (semester == 'All') return '$department Dept • All Sems';
        return '$department • $semester Sem';
      default:
        return 'General Resource';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return DateFormat('dd MMM, hh:mm a').format(timestamp.toDate());
      } else if (timestamp is String) {
        return DateFormat('dd MMM, hh:mm a').format(DateTime.parse(timestamp));
      }
    } catch (e) {
      debugPrint("Date error: $e");
    }
    return 'Recent';
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: _buildCompactAppBar(isDarkMode),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.themeColor),
              SizedBox(height: 20),
              Text(
                "Loading your resources...",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                "Fetching data for your stream",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: _buildCompactAppBar(isDarkMode),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.themeColor,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('resources')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint("Firebase Stream Error: ${snapshot.error}");
              return _buildErrorState("Error loading resources", isDarkMode);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.themeColor));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState("No resources available in database", isDarkMode);
            }

            debugPrint(
                "📊 Total resources found: ${snapshot.data!.docs.length}");
            debugPrint(
                "👤 User: $_userDepartment Department, $_userSemester Semester");

            List<QueryDocumentSnapshot> filteredDocs = [];
            int allCount = 0, deptCount = 0, semCount = 0, specCount = 0;
            int deptMatched = 0, semMatched = 0, specMatched = 0;

            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String targetType = (data['targetType'] ?? 'all').toString();
              String dept = (data['department'] ?? 'All').toString();
              String sem = (data['semester'] ?? 'All').toString();

              switch (targetType) {
                case 'all':
                  allCount++;
                  break;
                case 'department':
                  deptCount++;
                  if (dept == _userDepartment) deptMatched++;
                  break;
                case 'semester':
                  semCount++;
                  if (sem == _userSemester) semMatched++;
                  break;
                case 'specific':
                  specCount++;
                  if (dept == _userDepartment && sem == _userSemester)
                    specMatched++;
                  break;
              }

              if (_isResourceForUser(data)) {
                filteredDocs.add(doc);
              }
            }

            debugPrint("📈 Resource distribution:");
            debugPrint("   • For all: $allCount");
            debugPrint(
                "   • By department: $deptCount (matched: $deptMatched)");
            debugPrint("   • By semester: $semCount (matched: $semMatched)");
            debugPrint("   • Specific: $specCount (matched: $specMatched)");
            debugPrint("✅ Filtered for user: ${filteredDocs.length}");

            if (filteredDocs.isEmpty) {
              return _buildEmptyState(
                "No resources available for:\n\n"
                    "🎓 Department: $_userDepartment\n"
                    "📚 Semester: $_userSemester\n\n"
                    "Resources will appear here when available for your stream.",
                isDarkMode,
              );
            }

            return Column(
              children: [
                // Stats bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.themeColor.withOpacity(isDarkMode ? 0.1 : 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${filteredDocs.length} resources for you",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "$_userDepartment • $_userSemester",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.themeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Resources list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    physics: BouncingScrollPhysics(),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      return _buildCompactCard(filteredDocs[index], isDarkMode);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCompactAppBar(bool isDarkMode) {
    return AppBar(
      toolbarHeight: 90,
      title: Column(
        children: [
          const Text(
            "Resource",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.0,
              color: Colors.white,
              shadows: [
                Shadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          )
        ],
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.themeColor, AppColors.secendthemeColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.themeColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Elements (Blobs)
            Positioned(
              top: -20,
              right: -10,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),

            // আরও একটি ছোট কিউট ডট
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(QueryDocumentSnapshot doc, bool isDarkMode) {
    var data = doc.data() as Map<String, dynamic>;
    String title = data['title'] ?? "Untitled";
    String description = data['description'] ?? "";

    // Handle multiple images
    List<String> imageUrls = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      imageUrls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty) {
      imageUrls = [data['imageUrl'].toString()];
    }

    String thumbnailUrl = imageUrls.isNotEmpty ? imageUrls.first : "";
    String linkUrl = data['linkUrl']?.toString() ?? "";
    String targetLabel = _getTargetLabel(data);
    String displayDate =
        data['displayDate'] ?? _formatTimestamp(data['timestamp']);

    Color badgeColor = AppColors.themeColor;
    String targetType = data['targetType'] ?? 'all';
    if (targetType == 'department') badgeColor = Colors.blue;
    if (targetType == 'semester') badgeColor = Colors.green;
    if (targetType == 'specific') badgeColor = Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: badgeColor.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: linkUrl.isNotEmpty ? () => _openLink(linkUrl) : null,
          splashColor: badgeColor.withOpacity(0.1),
          highlightColor: badgeColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image/Icon Section
                if (thumbnailUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        _showZoomedImageGallery(context, imageUrls, title),
                    child: Container(
                      width: 70,
                      height: 70,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                        image: DecorationImage(
                          image: NetworkImage(thumbnailUrl),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1)),
                      ),
                      child: Stack(
                        children: [
                          if (imageUrls.length > 1)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${imageUrls.length}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Icon(
                      linkUrl.isNotEmpty ? Icons.link : Icons.article,
                      color: badgeColor,
                      size: 24,
                    ),
                  ),

                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              targetLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          Text(
                            displayDate,
                            style:
                            TextStyle(fontSize: 9, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),

                      SizedBox(height: 6),

                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: 6),

                      // Footer indicators
                      Row(
                        children: [
                          if (imageUrls.isNotEmpty) ...[
                            Icon(Icons.image, size: 12, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              imageUrls.length > 1
                                  ? "${imageUrls.length} images"
                                  : "1 image",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          if (linkUrl.isNotEmpty) ...[
                            Icon(Icons.link, size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              "Contains link",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDarkMode) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 50,
                  color: AppColors.themeColor,
                ),
              ),
              SizedBox(height: 25),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDarkMode ? Colors.grey : Colors.grey),
                ),
                child: Column(
                  children: [
                    Text(
                      "Your Current Stream Info",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.school,
                                size: 16, color: AppColors.themeColor),
                            SizedBox(height: 4),
                            Text(
                              "Department",
                              style: TextStyle(
                                  fontSize: 10, color: isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                            ),
                          ],
                        ),
                        SizedBox(width: 20),
                        Text(
                          _userDepartment,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(width: 30),
                        Column(
                          children: [
                            Icon(Icons.class_,
                                size: 16, color: AppColors.themeColor),
                            SizedBox(height: 4),
                            Text(
                              "Semester",
                              style: TextStyle(
                                  fontSize: 10, color: isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                            ),
                          ],
                        ),
                        SizedBox(width: 20),
                        Text(
                          _userSemester,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Pull down to refresh",
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: Icon(Icons.refresh, size: 16),
            label: Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomedImageGallery(
      BuildContext context, List<String> imageUrls, String title) {
    if (imageUrls.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryScreen(
          imageUrls: imageUrls,
          title: title,
        ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final String title;

  const GalleryScreen({
    Key? key,
    required this.imageUrls,
    required this.title,
  }) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.imageUrls.length > 1)
              Text(
                '${_currentIndex + 1} of ${widget.imageUrls.length}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (widget.imageUrls.length > 1)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Swipe left/right',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.imageUrls[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes:
                PhotoViewHeroAttributes(tag: widget.imageUrls[index]),
              );
            },
            itemCount: widget.imageUrls.length,
            loadingBuilder: (context, event) => Center(
              child: Container(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
            ),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundDecoration: BoxDecoration(color: Colors.black),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                      (index) => Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}