import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart'; // আপনার প্রোজেক্ট অনুযায়ী পাথ ঠিক করুন
import '../../../../app/app_colors.dart'; // আপনার কালার ফাইল অনুযায়ী

class ExamRoutine extends StatefulWidget {
  const ExamRoutine({super.key});
  static const name = '/exam_routine';

  @override
  State<ExamRoutine> createState() => _ExamRoutineState();
}

class _ExamRoutineState extends State<ExamRoutine> {
  @override
  Widget build(BuildContext context) {
    // ইউজারের ডাটা প্রোভাইডার থেকে নেওয়া হচ্ছে
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ইউজারের ডিপার্টমেন্ট এবং সেমিস্টার অনুযায়ী ডকুমেন্ট আইডি তৈরি
    String department = user?.department ?? 'CST';
    String semester = user?.semester ?? '1st';
    String docId = "$department-$semester";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text("My Exam Routine", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo[800],
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildUserInfoHeader(department, semester, isDark),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              // এডমিন প্যানেল থেকে পাঠানো ডাটা এখানে রিড করা হচ্ছে
              stream: FirebaseFirestore.instance
                  .collection('exam_routines')
                  .doc(docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildEmptyState(isDark);
                }

                var exams = snapshot.data!['exams'] as List;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exams.length,
                  itemBuilder: (context, i) {
                    return _buildExamCard(exams[i], isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ইউজারের বর্তমান সেকশন দেখানোর জন্য হেডার
  Widget _buildUserInfoHeader(String dept, String sem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.indigo[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _infoChip("Dept: $dept"),
          const SizedBox(width: 10),
          _infoChip("Semester: $sem"),
        ],
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // পরীক্ষার রুটিনের কার্ড ডিজাইন
  Widget _buildExamCard(Map<String, dynamic> exam, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[50],
          child: const Icon(Icons.assignment, color: Colors.indigo),
        ),
        title: Text(
          exam['subjectName'] ?? 'Subject',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Code: ${exam['subjectCode']} | Room: ${exam['room']}"),
            Text("Date: ${exam['date']}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Text(
          exam['startTime'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            "No Exam Routine Found",
            style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black54),
          ),
        ],
      ),
    );
  }
}