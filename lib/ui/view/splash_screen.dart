import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:videoapp/core/constants.dart';
import 'package:videoapp/ui/view/auth_pages/login.dart';
import 'package:videoapp/ui/view/home_screen.dart';

import '../widget/tab.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
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
        content: Text('$message permission is required. Please enable it in settings.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  void _navigateToNextScreen() {
    final isLoggedIn = Constants.getBool(Constants.isLogin) == true;

    Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => isLoggedIn ? const TabScreen() : const Login(),),(route) => false,);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.2),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Lottie.asset(
                  "assets/anim/anim_1.json",
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
