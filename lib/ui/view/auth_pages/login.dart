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
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Text.rich(
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
                      ),
                    ),
                  ]),
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
                          if(value.toString().isEmpty){
                            return "Please Enter Email";
                          }
                          return null;
                        },
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        isBottomSpace: true,
                      ),
                      CustomField(
                        prefixIcon: const Icon(Icons.password),
                        controller: passwordController,
                        obscureText: true,
                        hint: "*******",
                        validator: (value) {
                          if(value.toString().isEmpty){
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
                CustomBtn(
                    name: "Sign In",
                    borderColor: const Color(0xffeceef1),
                    onTap: () {
                      if(_loginKey.currentState!.validate()){
                        FirebaseUpload().userLogin(email: emailController.text, password: passwordController.text,context: context);
                      } else {
                        showSnackBar(message: 'Please Fill up details!',context: context,isError: false);
                      }
                    },
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xff6EA9FF),
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const Register(),));
                      },
                      icon: const Center(
                        child: Text(
                          "Don't have account? Sign Up",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
