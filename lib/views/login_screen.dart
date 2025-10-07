import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/utils/app_utils.dart';
import 'package:chat_app/views/sign_up_screen.dart';
import 'package:chat_app/widgets/text_f_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> signInFormKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    try {
      AppUtils.showLoading(context);
      AuthService authService = AuthService();
      await authService.signInEmailPassword(
        emailController.text,
        passwordController.text,
      );

      AppUtils.hideLoading(context);
    } catch (e) {
      AppUtils.hideLoading(context);
      AppUtils.showErrorToast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Login Screen')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: signInFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFieldWidget(
                inputType: TextInputType.emailAddress,
                label: 'Email',
                textEditingController: emailController,
              ),
              SizedBox(height: 20),
              TextFieldWidget(
                isPassword: true,
                inputType: TextInputType.visiblePassword,
                label: 'Password',
                textEditingController: passwordController,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (signInFormKey.currentState!.validate()) {
                      login();
                    }
                  },
                  child: Text('Login'),
                ),
              ),

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
