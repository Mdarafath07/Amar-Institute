import 'package:amar_institute/app/app_colors.dart';
import 'package:amar_institute/app/assets_path.dart';
import 'package:amar_institute/features/auth/presentation/screens/sing_in_screen.dart';
import 'package:amar_institute/features/auth/presentation/screens/sing_up_screen.dart';
import 'package:flutter/material.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  static const String name = "intro";

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Headline
              const Text(
                "Manage your college\nlife with ease",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 15),

              // Subtitle
              const Text(
                "Stay updated with your class schedules, assignments, and exam dates. We help you stay organized so you can focus on learning.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
              ),

              const Spacer(),

              // Illustration Placeholder
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  AssetsPath.intro,
                  fit: BoxFit.cover,
                ),
              ),

              const Spacer(),

              // Pagination Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(isActive: false),
                  _buildDot(isActive: false),
                  _buildDot(isActive: true),
                ],
              ),

              const SizedBox(height: 20),

              // Disclaimer Text
              const Text(
                "*Schedule and notices are subject to college administration. Keep notifications on for real-time updates.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  // Login Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onTapSignInButton,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Sign Up Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onTapSignUpButton, // এখন এটি কাজ করবে
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  AppColors.themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Sign up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Pagination Dot Builder
  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }



  void _onTapSignUpButton() {
    Navigator.pushNamed(context, SingUpScreen.name);
  }

  void _onTapSignInButton() {
    Navigator.pushNamed(context, SignInScreen.name);
  }
}