import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff6EA9FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text("Sign Up",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                        hint: "John Due",
                        validator: (value) {
                          if(value.toString().isEmpty){
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
                      CustomField(
                        prefixIcon: const Icon(Icons.password),
                        controller: cPasswordController,
                        obscureText: true,
                        hint: "*******",
                        validator: (value) {
                          if(value.toString().isEmpty){
                            return "Please Enter Confirm Password";
                          } else if (value != passwordController.text){
                            return "Password Not Matched";
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
                  name: "Sign Up",
                  borderColor: const Color(0xffeceef1),
                  onTap: () {
                    if(_loginKey.currentState!.validate()){
                    print("Sign up call");
                      upload.registerUser(name: nameController.text, email: emailController.text, password: passwordController.text,cPassword: cPasswordController.text, context: context);
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
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Login(),), (route) => false);
                      },
                      icon: const Center(
                        child: Text(
                          "Have an account? Sign In",
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
