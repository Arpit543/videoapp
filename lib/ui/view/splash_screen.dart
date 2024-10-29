import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videoapp/core/constants.dart';
import 'package:videoapp/ui/view/auth_pages/login.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestPermissions();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    if (cameraStatus.isDenied || storageStatus.isDenied) {
      _showPermissionSnackBar(cameraStatus, storageStatus);
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        _navigateToNextScreen();
      });
    }
  }

  void _showPermissionSnackBar(PermissionStatus cameraStatus, PermissionStatus storageStatus) {
    String message = 'Permissions required: ';
    if (cameraStatus.isDenied) {
      message += 'Camera ';
    }
    if (storageStatus.isDenied) {
      message += 'Storage ';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          '$message permission is required. Please enable it in settings.',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  void _navigateToNextScreen() {
    final isLoggedIn = Constants.getBool(Constants.isLogin) == true;
    Get.offAll(isLoggedIn ? const HomeScreen() : const Login());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3EADCF), Color(0xff6EA9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ClipOval(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Lottie.asset(
                  "assets/anim/anim_1.json",
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
