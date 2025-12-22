import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amar_institute/app/assets_path.dart';
import '../../../../app/app_colors.dart';
import '../../../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _rollNoController;
  late TextEditingController _regNoController;

  String? _selectedDepartment;
  String? _selectedSemester;

  final List<String> _departments = ['CST', 'ET', 'CT', 'MT', 'ENT'];
  final List<String> _semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _rollNoController = TextEditingController(text: user?.rollNo ?? '');
    _regNoController = TextEditingController(text: user?.regNo ?? '');

    _selectedDepartment = _departments.contains(user?.department) ? user?.department : null;
    _selectedSemester = _semesters.contains(user?.semester) ? user?.semester : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rollNoController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        department: _selectedDepartment ?? '',
        semester: _selectedSemester ?? '',
        rollNo: _rollNoController.text.trim(),
        regNo: _regNoController.text.trim(),
      );

      await userProvider.updateUser(updatedUser);

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.themeColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1222) : const Color(0xFFF0F4FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- Sliver App Bar ---
          SliverAppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text(
              "Edit Profile",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark ? const Color(0xFF0B1222) : const Color(0xFFF0F4FF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Content ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- Top Cute Avatar Header ---
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        child: Image.asset(AssetsPath.edit, width: 250),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- Basic Info Section ---
                  _buildSectionCard(
                    isDark: isDark,
                    title: "Basic Info",
                    icon: Icons.person,
                    children: [
                      _buildTextField("Full Name", Icons.person_outline_rounded, _nameController, isDark),
                      _buildTextField("Email", Icons.alternate_email_rounded, _emailController, isDark),
                      _buildTextField("Phone", Icons.phone_iphone_rounded, _phoneController, isDark),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- Academic Section ---
                  _buildSectionCard(
                    isDark: isDark,
                    title: "Academic Info",
                    icon: Icons.auto_stories_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildDropdownField(
                              "Department",
                              _selectedDepartment,
                              _departments,
                                  (v) => setState(() => _selectedDepartment = v),
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: _buildDropdownField(
                              "Semester",
                              _selectedSemester,
                              _semesters,
                                  (v) => setState(() => _selectedSemester = v),
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField("Roll No", Icons.badge_outlined, _rollNoController, isDark),
                      _buildTextField("Reg No", Icons.assignment_outlined, _regNoController, isDark),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // --- Stylish Save Button ---
                  _buildSaveButton(isDark),

                  // --- Cancel Button (Optional) ---
                  const SizedBox(height: 15),
                  _buildCancelButton(isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.themeColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
              ),
            ],
          ),
          const Divider(height: 25, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: AppColors.themeColor.withOpacity(0.7)),
          filled: true,
          fillColor: isDark ? Colors.black12 : Colors.grey[50],
          contentPadding: const EdgeInsets.all(18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.themeColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint, String? value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey)),
          icon: Icon(Icons.expand_more_rounded, color: AppColors.themeColor),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return InkWell(
      onTap: _isLoading ? null : _saveChanges,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppColors.themeColor, const Color(0xFF6366F1)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.themeColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                "Update Profile",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          side: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          "Cancel",
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}