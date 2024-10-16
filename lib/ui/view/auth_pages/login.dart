import 'package:flutter/material.dart';
import 'package:videoapp/core/firebase_upload.dart';
import 'package:videoapp/ui/view/auth_pages/register.dart';
import 'package:videoapp/ui/widget/common_button.dart';
import 'package:videoapp/ui/widget/common_snackbar.dart';
import 'package:videoapp/ui/widget/common_textfield.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _loginKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false; // Loading state for button

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Sign In",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Center(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: "Welcome ",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.1,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: "Back",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.1,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff6EA9FF),
                        ),
                      ),
                    ]),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Form(
                  key: _loginKey,
                  child: Column(
                    children: [
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomBtn(
                    name: "Sign In",
                    borderColor: const Color(0xffeceef1),
                    onTap: () async {
                      if (_loginKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });

                        await FirebaseUpload().userLogin(
                          email: emailController.text,
                          password: passwordController.text,
                          context: context,
                        );

                        setState(() {
                          _isLoading = false;
                        });
                      } else {
                        showSnackBar(
                            message: 'Please fill up the details!',
                            context: context,
                            isError: false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Register()),
                    );
                  },
                  child: const Center(
                    child: Text(
                      "Don't have an account? Sign Up",
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
