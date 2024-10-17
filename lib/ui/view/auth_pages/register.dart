import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/auth_pages/login.dart';
import 'package:videoapp/ui/widget/common_button.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';
import 'package:videoapp/ui/widget/common_textfield.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _loginKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final cPasswordController = TextEditingController();

  FirebaseUpload upload = FirebaseUpload();
  bool _isLoading = false; // Added loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Sign Up",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Form(
                  key: _loginKey,
                  child: Column(
                    children: [
                      CustomField(
                        prefixIcon: const Icon(Icons.person),
                        controller: nameController,
                        hint: "John Doe",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter Name";
                          }
                          return null;
                        },
                        autofillHints: const [AutofillHints.name],
                        keyboardType: TextInputType.name,
                        isBottomSpace: true,
                      ),
                      CustomField(
                        prefixIcon: const Icon(Icons.email),
                        controller: emailController,
                        hint: "example@gmail.com",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter Email";
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        isBottomSpace: true,
                      ),
                      CustomField(
                        prefixIcon: const Icon(Icons.lock),
                        controller: passwordController,
                        obscureText: true,
                        hint: "*******",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter Password";
                          } else if (value.length < 6) {
                            return "Password should be at least 6 characters";
                          }
                          return null;
                        },
                        isBottomSpace: true,
                        autofillHints: const [AutofillHints.password],
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      CustomField(
                        prefixIcon: const Icon(Icons.lock),
                        controller: cPasswordController,
                        obscureText: true,
                        hint: "*******",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter Confirm Password";
                          } else if (value != passwordController.text) {
                            return "Password does not match";
                          }
                          return null;
                        },
                        isBottomSpace: true,
                        autofillHints: const [AutofillHints.password],
                        keyboardType: TextInputType.visiblePassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isLoading ? const CircularProgressIndicator() : CustomBtn(
                    name: "Sign Up",
                    borderColor: const Color(0xffeceef1),
                    onTap: () {
                      if (_loginKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });
                        upload.registerUser(
                          name: nameController.text,
                          email: emailController.text,
                          password: passwordController.text,
                          cPassword: cPasswordController.text,
                          context: context,
                        ).then((_) {
                          setState(() {
                            _isLoading = false;
                          });
                        });
                      } else {
                        showSnackBar(
                          message: 'Please fill up all the details!',
                          context: context,
                          isError: true,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Get.offAll(const Login());
                  },
                  child: const Center(
                    child: Text(
                      "Have an account? Sign In",
                      style: TextStyle(
                        color: Color(0xff6EA9FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
