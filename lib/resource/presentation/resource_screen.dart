import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});
  static const name = '/resource';

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  String _userDepartment = 'CST';
  String _userSemester = '1st';
  bool _isLoading = true;

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
      _isLoading = false;
    });
  }

  // লিঙ্ক ওপেন করার ফিক্সড ফাংশন - Android এর জন্য ফিক্সড
  Future<void> _openLink(String urlString) async {
    if (urlString.isEmpty) {
      _showSnackBar("Link is empty", Colors.orange);
      return;
    }

    try {
      String processedUrl = urlString.trim();

      // URL ভ্যালিডেট করুন
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://') &&
          !processedUrl.startsWith('tel:') &&
          !processedUrl.startsWith('mailto:')) {
        processedUrl = 'https://$processedUrl';
      }

      final Uri url = Uri.parse(processedUrl);

      // Method 1: সরাসরি launchUrl চেষ্টা করুন (canLaunchUrl ছাড়া)
      try {
        bool launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );

        if (!launched) {
          // Method 2: যদি কাজ না করে, alternative method ব্যবহার করুন
          await _launchUrlAlternative(url);
        }
      } catch (e) {
        // Method 3: যদি তাতেও কাজ না করে
        await _launchUrlAlternative(url);
      }

    } catch (e) {
      debugPrint("Link Error: $e");
      _showSnackBar("Could not open link. Please check your internet connection.", Colors.red);
    }
  }

  // Alternative URL launching method
  Future<void> _launchUrlAlternative(Uri url) async {
    try {
      // Platform-specific implementation
      if (url.toString().startsWith('tel:')) {
        // Phone call
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (url.toString().startsWith('mailto:')) {
        // Email
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Web URL - try different approaches
        String urlString = url.toString();

        // Approach 1: সরাসরি launchUrl
        bool launched = await launchUrl(
          Uri.parse(urlString),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );

        if (!launched) {
          // Approach 2: launchUrl with platform view
          launched = await launchUrl(
            Uri.parse(urlString),
            mode: LaunchMode.platformDefault,
          );

          if (!launched) {
            // Approach 3: সরাসরি browser এ ওপেন করার চেষ্টা
            _showSnackBar("Cannot open link. Please check if you have a browser installed.", Colors.red);
          }
        }
      }
    } catch (e) {
      debugPrint("Alternative launch error: $e");
      _showSnackBar("Failed to open link: ${e.toString()}", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  bool _isResourceForUser(Map<String, dynamic> data) {
    String department = data['department'] ?? 'All';
    String semester = data['semester'] ?? 'All';
    String targetType = data['targetType'] ?? 'all';

    switch (targetType) {
      case 'all':
        return true;
      case 'department':
        return department == _userDepartment || department == 'All';
      case 'semester':
        return semester == _userSemester || semester == 'All';
      case 'specific':
        return department == _userDepartment && semester == _userSemester;
      default:
        return true;
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
        return 'For ${department} Department';
      case 'semester':
        return 'For ${semester} Semester';
      case 'specific':
        return 'For ${department} ${semester}';
      default:
        return 'For All';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return DateFormat('dd MMM yyyy • hh:mm a').format(date);
      } else if (timestamp != null) {
        final date = DateTime.parse(timestamp.toString());
        return DateFormat('dd MMM yyyy • hh:mm a').format(date);
      } else if (timestamp is String) {
        final date = DateTime.parse(timestamp);
        return DateFormat('dd MMM yyyy • hh:mm a').format(date);
      }
    } catch (e) {
      debugPrint("Timestamp format error: $e");
    }
    return 'Recent';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Learning Resources"),
          backgroundColor: Colors.indigo[800],
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Learning Resources"),
            SizedBox(height: 2),
            Text(
              '$_userDepartment - $_userSemester',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resources')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Error loading data",
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No resources available",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Check back later for new resources",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          List<QueryDocumentSnapshot> filteredDocs = snapshot.data!.docs
              .where((doc) => _isResourceForUser(doc.data() as Map<String, dynamic>))
              .toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No resources for $_userDepartment $_userSemester",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Resources will appear here when available for your department/semester",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var doc = filteredDocs[index];
              var data = doc.data() as Map<String, dynamic>;

              String title = data['title'] ?? "Untitled";
              String description = data['description'] ?? "";
              String imageUrl = data['imageUrl'] ?? "";
              String linkUrl = data['linkUrl'] ?? "";
              String targetLabel = _getTargetLabel(data);

              String displayDate = data['displayDate'] ?? _formatTimestamp(data['timestamp']);

              return Card(
                margin: EdgeInsets.only(bottom: 16, left: 8, right: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              targetLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[800],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                displayDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (imageUrl.isNotEmpty && imageUrl != '')
                      GestureDetector(
                        onTap: () => _showZoomedImage(context, imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: imageUrl.isNotEmpty ? Radius.zero : Radius.circular(15),
                          ),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: Image.network(
                              imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 50, color: Colors.grey[500]),
                                        SizedBox(height: 10),
                                        Text(
                                          "Image not available",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[900],
                            ),
                          ),

                          if (description.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],

                          if (linkUrl.isNotEmpty && linkUrl != '') ...[
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openLink(linkUrl),
                                icon: Icon(Icons.open_in_new, size: 20),
                                label: Text(
                                  "Open Resource Link",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.link, size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      linkUrl,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showZoomedImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(url),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 50),
                    SizedBox(height: 16),
                    Text(
                      "Failed to load image",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}