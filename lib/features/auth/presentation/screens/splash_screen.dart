import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../providers/auth_provider.dart';
import '../../../common/presentation/screens/main_nav_holder_screen.dart';
import '../widgets/app_logo.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String name = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checkingNetwork = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // UI রেন্ডার হওয়ার পর লজিক রান করুন
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNetworkAndMove();
    });
  }

  Future<void> _checkNetworkAndMove() async {
    try {
      // ১. নেটওয়ার্ক চেক (নতুন API অনুযায়ী List হ্যান্ডলিং)
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      _isOffline = results.contains(ConnectivityResult.none);
    } catch (e) {
      _isOffline = true;
    }

    if (mounted) setState(() => _checkingNetwork = false);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setOfflineMode(_isOffline);

    // ২. ডাটা লোডিং (Timeout সহ)
    try {
      if (_isOffline) {
        await authProvider.loadCachedUser().timeout(const Duration(seconds: 2));
      } else {
        await authProvider.loadUser().timeout(const Duration(seconds: 4), onTimeout: () {
          return authProvider.loadCachedUser();
        });
      }
    } catch (e) {
      debugPrint('Data loading error: $e');
    }

    // ৩. নেভিগেশন (অবশ্যই ৩-৪ সেকেন্ডের মধ্যে কল হবে)
    if (!mounted) return;
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, MainNavHolderScreen.name);
    } else {
      Navigator.pushReplacementNamed(context, IntroScreen.name);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            AppLogo(height: 200, width: 200),
            const SizedBox(height: 20),
            if (_checkingNetwork)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            if (!_checkingNetwork && _isOffline)
              Column(
                children: [
                  const Icon(Icons.wifi_off, size: 40, color: Colors.orange),
                  const SizedBox(height: 10),
                  Text('Offline Mode', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 5),
                  Text('Using cached data', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}