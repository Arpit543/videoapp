import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videoapp/core/constants.dart';
import 'package:videoapp/ui/view/auth_pages/login.dart';
import 'package:videoapp/ui/view/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {

    super.initState();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    if (cameraStatus.isDenied || storageStatus.isDenied) {
      if (cameraStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission is required for this app. Please enable it from app settings.'),
            action: SnackBarAction(label: 'Settings',onPressed: () => openAppSettings(),),
          ),
        );
      }

      if (storageStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission is required for this app. Please enable it from app settings.'),
            action: SnackBarAction(label: 'Settings',onPressed: () => openAppSettings(),),
          ),
        );
      }
    } else if (cameraStatus.isGranted && storageStatus.isGranted) {
      Future.delayed(const Duration(seconds: 5), () async {
        if (Constants.getBool(Constants.isLogin) == true) {
          Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
        } else {
          Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => const Login()), (route) => false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.2),
          child: ClipOval(
            child: Lottie.asset(
              "assets/anim/anim_1.json",
              width: 100,
              height: 100,
            ),
          ),
        ),
      ),
    );
  }
}
