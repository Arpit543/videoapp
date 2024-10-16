import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:videoapp/ui/view/home_screen.dart';
import 'package:videoapp/ui/view/splash_screen.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';

import '../ui/view/auth_pages/login.dart';
import '../ui/view/story/story_view.dart';
import 'constants.dart';

class FirebaseUpload {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var nameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var cPasswordController = TextEditingController();

  List<String> imageURLs = [];
  List<String> videoURLs = [];
  String imageURL = '';
  int lenImages = 0;
  int lenVideos = 0;

  ///   Upload Image n Video to Firebase using [uploadFileInStorage]
  Future<void> uploadFileInStorage({required File file, required String type, required BuildContext context}) async {
    String fileName = file.path.split("/").last;
    Reference storageRef = FirebaseStorage.instance.ref().child("${_auth.currentUser!.uid}/$type/$fileName");

    try {
      storageRef.putFile(file);
      showSnackBar(message: 'File Uploaded successfully',context: context,isError: false);
    } catch (e) {
      showSnackBar(message: 'File Failed to Upload', context: context, isError: true);
    }
  }

  ///   Upload Image n Video to Firebase using [uploadListInStorage]
  Future<void> uploadListInStorage({required List<String> images,required String type,required BuildContext context,}) async {
    final storage = FirebaseStorage.instance;
    final auth = FirebaseAuth.instance;

    for (String imagePath in images) {
      try {
        File file = File(imagePath);
        String fileName = imagePath.split('/').last;
        Reference storageRef = storage.ref().child("${auth.currentUser!.uid}/$type/$fileName");

        UploadTask uploadTask = storageRef.putFile(file);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = 100.0 * (snapshot.bytesTransferred / snapshot.totalBytes);
          print('Upload of $fileName is $progress% complete.');
        });

        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();

        showSnackBar(message: 'Story uploaded successfully!', context: context, isError: false);
       } catch (e) {
        print(e);
        showSnackBar(message: 'Failed to upload $imagePath', context: context, isError: true);
      }
    }
  }

  Future<List<String>> fetchStoryList() async {
    try {
      final storageRefImages = FirebaseStorage.instance.ref().child("${_auth.currentUser!.uid}/Story");
      final listResultImages = await storageRefImages.listAll();
      final imageUrls = <String>[];
      for (final item in listResultImages.items) {
        final downloadUrl = await item.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } on FirebaseException {
      return [];
    }
  }

  ///   Fetch Image from Firebase Storage using [fetchImagesList]
  Future<List<String>> fetchImagesList() async {
    try {
      final storageRefImages = FirebaseStorage.instance.ref().child("${_auth.currentUser!.uid}/Images");
      final listResultImages = await storageRefImages.listAll();
      final imageUrls = <String>[];
      for (final item in listResultImages.items) {
        final downloadUrl = await item.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } on FirebaseException {
      return [];
    }
  }

  ///   Fetch Video from Firebase Storage using [fetchVideosList]
  Future<List<String>> fetchVideosList() async {
    try {
      final storageRefVideos = FirebaseStorage.instance.ref().child("${_auth.currentUser!.uid}/Videos");
      final listResultVideos = await storageRefVideos.listAll();

      final videoUrls = <String>[];
      for (final item in listResultVideos.items) {
        final downloadUrl = await item.getDownloadURL();
        videoUrls.add(downloadUrl);
      }

      return videoUrls;
    } on FirebaseException {
      return [];
    }
  }

  ///   Function [getImageData] to get image
  Future<void> getImageData() async {
    final imageUrls = await fetchImagesList();

    if (imageUrls.isNotEmpty) {
      imageURLs = imageUrls;
      lenImages = imageUrls.length;
    } else {}
  }

  ///   Function [getVideoData] to get video
  Future<void> getVideoData() async {
    final videoURL = await fetchVideosList();

    if (videoURL.isNotEmpty) {
      videoURLs = videoURL;
      lenVideos = videoURL.length;
    } else {}
  }

  ///   Function [getStoryData] to get video
  Future<List<String>> getStoryData() async {
    final videoURL = await fetchStoryList();

    if (videoURL.isNotEmpty) {
      videoURLs = videoURL;
      lenVideos = videoURL.length;

    } else {}
    return videoURLs;
  }

  ///   Register User With Email n Password
  Future<void> registerUser({required String name, required String email, required String password, required String cPassword, required BuildContext context,}) async {
    if (password != cPassword) {
      if (kDebugMode) {
        print('Passwords do not match');
      }
      showSnackBar(message: 'Passwords do not match', context: context, isError: true);
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        DatabaseMethod databaseMethod = DatabaseMethod();

        Map<String, dynamic> userInfo = {
          'id': user.uid,
          'name': name,
          'email': email,
          'password': password,
        };

        await databaseMethod.addUser(user.uid, userInfo);

        showSnackBar(message: 'You Have Been Registered Successfully!',context: context,isError: false,);
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const Login()), (Route<dynamic> route) => false,);

        nameController.clear();
        emailController.clear();
        passwordController.clear();
        cPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      showSnackBar(message: 'Registration failed: ${e.message}',context: context,
        isError: true,);
    }
  }

  ///   Login with Email n Password
  Future<void> userLogin({required String email,required String password,required BuildContext context,}) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref('User/${userCredential.user!.uid}');
        DataSnapshot userSnapshot = await userRef.get();

        if (userSnapshot.exists) {
          FirebaseDatabase.instance.ref("User/${userCredential.user!.uid}").onValue.listen((event) async {
            await Constants.setBool(Constants.isLogin, true);
            await Constants.setString(Constants.email, event.snapshot.child("email").value.toString());
            await Constants.setString(Constants.name, event.snapshot.child("name").value.toString());
            await Constants.setString(Constants.userId, event.snapshot.child("id").value.toString());
            showSnackBar(message: 'You Have Been Logged In Successfully!',context: context,isError: false,);

            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()),(Route<dynamic> route) => false,);
          });
        } else {
          throw Exception("User data not found in Realtime Database");
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = "No User Found for that Email";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong Password Provided by You";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid Email Provided by You";
      } else {
        errorMessage = "An unknown error occurred";
      }
      showSnackBar(message: errorMessage, context: context, isError: true);
    } catch (e) {
      showSnackBar(message: 'An error occurred while logging in. Please try again.',context: context,isError: true);
    }
  }

  ///   Logout Your Session
  Future<void> logout(BuildContext context) async {
    try {
      await Constants.clear();
      showSnackBar(message: 'You Have Been Logged Out Successfully!',context: context,isError: false);
      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => const SplashScreen()), (route) => false);
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    }
  }
}

///   DataBase Method To Add User In Realtime Database In Firebase
class DatabaseMethod {
  late BuildContext context;

  Future<void> addUser(String userId, Map<String, dynamic> userInfo) async {
    try {
      await FirebaseDatabase.instance.ref('User/$userId').set(userInfo);
    } catch (e) {
      showSnackBar(message: e.toString(), context: context, isError: false);
    }
  }
}
