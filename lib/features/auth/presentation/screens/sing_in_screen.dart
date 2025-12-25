import 'dart:ui';
import 'package:amar_institute/features/auth/presentation/screens/sing_up_screen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../common/presentation/screens/main_nav_holder_screen.dart';
import 'forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  static const String name = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, MainNavHolderScreen.name,(route) => false);
    } else if (mounted) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Sign in failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Decoration
          Positioned(
            top: -100,
            left: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: AppColors.themeColor.withOpacity(0.1),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    // Logo or Header Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.auto_stories_rounded,
                          size: 40, color: AppColors.themeColor),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to your account to continue tracking your routine.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      label: "Email Address",
                      hint: "example@mail.com",
                      icon: Icons.alternate_email_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!EmailValidator.validate(value)) return 'Invalid email format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    _buildInputField(
                      controller: _passwordController,
                      label: "Password",
                      hint: "••••••••",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (value) => value!.isEmpty ? 'Password is required' : null,
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgotPasswordScreen()));
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: AppColors.themeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.themeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Bottom Link to Sign Up
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, SingUpScreen.name),
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: AppColors.themeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            prefixIcon: Icon(icon, color: AppColors.themeColor.withOpacity(0.7), size: 20),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            )
                : null,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.themeColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}