import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});
  static const name = '/notice';


  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<NoticeModel> notices = [];
  bool isLoading = true;
  String _userDepartment = 'CST';
  String _userSemester = '1st';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userDepartment = prefs.getString('userDepartment') ?? 'CST';
      _userSemester = prefs.getString('userSemester') ?? '1st';
    });
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() => isLoading = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notices')
          .orderBy('timestamp', descending: true)
          .get();

      List<NoticeModel> fetchedNotices = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String department = data['department'] ?? 'All';
        String semester = data['semester'] ?? 'All';

        // Check if notice is for this user
        bool isForUser = department == 'All' ||
            department == _userDepartment ||
            (department.contains('All') && department.contains(_userDepartment));

        bool isSemesterMatch = semester == 'All' ||
            semester == _userSemester ||
            (semester.contains('All') && semester.contains(_userSemester));

        if (isForUser && isSemesterMatch) {
          fetchedNotices.add(NoticeModel(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            timestamp: data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
            priority: data['priority'] ?? 'Normal',
            department: data['department'] ?? 'All',
            semester: data['semester'] ?? 'All',
            targetType: data['targetType'] ?? 'all',
          ));
        }
      }

      setState(() {
        notices = fetchedNotices;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching notices: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notices'),
            SizedBox(height: 2),
            Text(
              '$_userDepartment - $_userSemester',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchNotices,
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notices.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notices for $_userDepartment $_userSemester',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchNotices,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            return _buildNoticeCard(notices[index]);
          },
        ),
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    String timeAgo = _getTimeAgo(notice.timestamp);
    Color priorityColor = _getPriorityColor(notice.priority);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: priorityColor,
              width: 6,
            ),
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notice.priority,
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  if (notice.department != 'All' || notice.semester != 'All')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${notice.department} ${notice.semester}',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                notice.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              SizedBox(height: 8),
              Text(
                notice.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Divider(),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(notice.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Spacer(),
                  if (notice.targetType != 'all')
                    Row(
                      children: [
                        Icon(Icons.group, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          notice.targetType == 'department'
                              ? 'Dept Specific'
                              : 'Sem Specific',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final List<String> departments = ['CST', 'ET', 'CT', 'Civil', 'Mechanical'];
    final List<String> semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];

    String? selectedDept = _userDepartment;
    String? selectedSem = _userSemester;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Notices'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedDept,
              items: departments
                  .map((dept) => DropdownMenuItem(
                value: dept,
                child: Text(dept),
              ))
                  .toList(),
              onChanged: (value) => selectedDept = value,
              decoration: InputDecoration(labelText: 'Department'),
            ),
            SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedSem,
              items: semesters
                  .map((sem) => DropdownMenuItem(
                value: sem,
                child: Text(sem),
              ))
                  .toList(),
              onChanged: (value) => selectedSem = value,
              decoration: InputDecoration(labelText: 'Semester'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedDept != null && selectedSem != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userDepartment', selectedDept!);
                await prefs.setString('userSemester', selectedSem!);

                setState(() {
                  _userDepartment = selectedDept!;
                  _userSemester = selectedSem!;
                });

                Navigator.pop(context);
                _fetchNotices();
              }
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class NoticeModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String priority;
  final String department;
  final String semester;
  final String targetType;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.priority,
    required this.department,
    required this.semester,
    required this.targetType,
  });
}