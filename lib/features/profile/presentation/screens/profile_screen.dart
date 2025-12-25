import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/assets_path.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/imagebb_service.dart';

import '../../../auth/presentation/screens/sing_in_screen.dart';
import 'edit_profile_screen.dart';  // নতুন এডিট স্ক্রিন যোগ করুন

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final ImageBBService _imageBBService = ImageBBService();
  File? _selectedImage;
  bool _isUploading = false;
  bool _isNotificationOn = true;

  // Image picker function
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload image to server
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrl = await _imageBBService.uploadImage(_selectedImage!);
      if (imageUrl != null) {
        await Provider.of<UserProvider>(context, listen: false)
            .updateProfileImage(imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
    }
  }

  // Password change dialog
  void _showPasswordChangeDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Change Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField("Old Password", true, oldPasswordController),
              const SizedBox(height: 12),
              _buildDialogField("New Password", true, newPasswordController),
              const SizedBox(height: 12),
              _buildDialogField("Confirm New Password", true, confirmPasswordController),
              const SizedBox(height: 16),
              const Text(
                "Password must be at least 6 characters long",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.themeColor,
            ),
            onPressed: () async {
              final newPass = newPasswordController.text.trim();
              final confirmPass = confirmPasswordController.text.trim();

              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // TODO: Implement actual password change logic with backend
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "Update",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to edit profile screen
  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = userProvider.user ?? authProvider.user;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // AppBar with edit icon
          _buildCustomAppBar(isDark, user),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Academic Details
                  _sectionWithEditButton(
                    "Academic Details",
                    onEdit: _navigateToEditProfile,
                  ),
                  _buildDetailTile(
                    Icons.school,
                    "Department",
                    user?.department ?? "Not set",
                    isDark,
                  ),
                  _buildDetailTile(
                    Icons.calendar_month,
                    "Semester",
                    user?.semester ?? "Not set",
                    isDark,
                  ),
                  _buildDetailTile(
                    Icons.numbers,
                    "Roll Number",
                    user?.rollNo ?? "Not set",
                    isDark,
                  ),
                  _buildDetailTile(
                    Icons.confirmation_number,
                    "Registration No",
                    user?.regNo ?? "Not set",
                    isDark,
                  ),

                  const SizedBox(height: 24),

                  // Personal Info
                  _sectionWithEditButton(
                    "Personal Information",
                    onEdit: _navigateToEditProfile,
                  ),
                  _buildDetailTile(
                    Icons.person,
                    "Full Name",
                    user?.name ?? "Not set",
                    isDark,
                  ),
                  _buildDetailTile(
                    Icons.email,
                    "Email",
                    user?.email ?? "Not set",
                    isDark,
                  ),
                  _buildDetailTile(
                    Icons.phone_android,
                    "Phone",
                    user?.phoneNumber ?? "Not set",
                    isDark,
                  ),

                  const SizedBox(height: 24),

                  // Settings & Security
                  _sectionTitle("Settings & Security"),
                  _buildSettingSwitch(
                    Icons.dark_mode,
                    "Dark Mode",
                    isDark,
                        (v) {
                      themeProvider.setThemeMode(
                        v ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    isDark,
                  ),
                  _buildSettingSwitch(
                    Icons.notifications_active,
                    "Notifications",
                    _isNotificationOn,
                        (v) => setState(() => _isNotificationOn = v),
                    isDark,
                  ),
                  _buildActionTile(
                    Icons.lock_reset,
                    "Change Password",
                    _showPasswordChangeDialog,
                    isDark,
                  ),

                  const SizedBox(height: 40),

                  // Logout Button
                  _buildLogoutButton(authProvider),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(bool isDark, dynamic user) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile picture with upload option
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.themeColor.withOpacity(0.1),
                  child: ClipOval(
                    child: _isUploading
                        ? CircularProgressIndicator(color: AppColors.themeColor)
                        : user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: user!.profileImageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      // ✅ ইমেজ লোড হওয়ার সময় যা দেখাবে
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      // ✅ অফলাইনে থাকলে বা এরর হলে ক্যাশ থেকে ছবি দেখাবে,
                      // ছবি না থাকলে প্লেসহোল্ডার দেখাবে
                      errorWidget: (context, url, error) => Image.asset(
                        AssetsPath.placeholder, // আপনার প্লেসহোল্ডার ইমেজের পাথ
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                        : 
                    Image.asset(AssetsPath.placeholder)
                  ),
                ),
                // ক্যামেরা আইকন অংশ (আগের মতোই থাকবে)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? "User",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  user?.email ?? "",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Edit Profile Icon
          IconButton(
            onPressed: _navigateToEditProfile,
            icon: Icon(
              Icons.edit,
              color: AppColors.themeColor,
              size: 24,
            ),
            tooltip: "Edit Profile",
          ),
        ],
      ),
    );
  }

  Widget _sectionWithEditButton(String title, {required VoidCallback onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.themeColor,
            size: 20,
          ),
          const SizedBox(width: 15),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(
      IconData icon,
      String title,
      bool value,
      Function(bool) onChanged,
      bool isDark,
      ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.themeColor,
      ),
    );
  }

  Widget _buildActionTile(
      IconData icon,
      String title,
      VoidCallback onTap,
      bool isDark,
      ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  Widget _buildDialogField(
      String hint,
      bool isPass,
      TextEditingController controller,
      ) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm Logout"),
              content: const Text("Are you sure you want to logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await authProvider.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, SignInScreen.name);
            }
          }
        },
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
        ),
        label: const Text(
          "Log Out",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}