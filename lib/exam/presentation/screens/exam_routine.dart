import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../app/app_colors.dart';

class ExamRoutine extends StatefulWidget {
  const ExamRoutine({super.key});
  static const name = '/exam_routine';

  @override
  State<ExamRoutine> createState() => _ExamRoutineState();
}

class _ExamRoutineState extends State<ExamRoutine> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context); //
    final user = userProvider.user; //
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String department = user?.department ?? 'CST'; //
    String semester = user?.semester ?? '1st'; //
    String docId = "$department-$semester"; //

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          children: [
            const Text(
              "Exam Schedule",
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
      body: Column(
        children: [
          _buildGlassHeader(department, semester),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('exam_routines').doc(docId).snapshots(), //
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return _buildEmptyState();

                var data = snapshot.data!.data() as Map<String, dynamic>;
                List exams = data['exams'] ?? []; //

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: exams.length,
                  itemBuilder: (context, index) => _buildTimelineCard(exams[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(String dept, String sem) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _headerItem("Dept", dept),
          Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.3)),
          _headerItem("Semester", sem),
        ],
      ),
    );
  }

  Widget _headerItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.themeColor)),
      ],
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> exam, bool isDark) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.themeColor, shape: BoxShape.circle)),
              Expanded(child: Container(width: 2, color: AppColors.themeColor.withOpacity(0.2))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam['subjectName'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled, size: 16, color: AppColors.accentColor),
                      const SizedBox(width: 5),
                      Text(exam['startTime'] ?? '', style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.meeting_room_rounded, size: 16, color: Colors.blue),
                      const SizedBox(width: 5),
                      Text("Room ${exam['room']}", style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(exam['date'] ?? '', style: const TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("No Exams Yet! 🎉"));
}