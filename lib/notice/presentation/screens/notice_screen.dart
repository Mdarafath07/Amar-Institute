import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../app/app_colors.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  static const name = '/notice';

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F6FF),
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          children: [
            const Text(
              "Notice Box",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.0,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))
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
        backgroundColor: Colors.transparent, // Background Gradient handle করবে
        flexibleSpace: Container(
          decoration: BoxDecoration(
            // প্রিমিয়াম গ্রেডিয়েন্ট ইফেক্ট
            gradient: LinearGradient(
              colors: [AppColors.themeColor, AppColors.secendthemeColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // নিচের দিকে বড় রাউন্ড শেপ এবং শ্যাডো
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
      ),
      body: StreamBuilder<QuerySnapshot>(
// Recent First Sorting
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return _buildCompactNoticeCard(
                  snapshot.data!.docs[index], isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildCompactNoticeCard(DocumentSnapshot doc, bool isDark) {
    String priority = doc['priority'] ?? 'low';
    Color pColor = priority == 'high' ? Colors.redAccent : Colors.blueAccent;

// Track expanded state for each notice
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2236) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pColor.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: pColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(priority.toUpperCase(),
                        style: TextStyle(
                            color: pColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(
                      DateFormat('dd MMM')
                          .format((doc['timestamp'] as Timestamp).toDate()),
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              Text(doc['title'],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(doc['description'],
                  style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                      height: 1.4),
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis),

// Show "See More/Less" button only if description is long
              if (doc['description'].toString().length > 100) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpanded ? 'See Less' : 'See All',
                            style: TextStyle(
                              color: pColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: pColor,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
