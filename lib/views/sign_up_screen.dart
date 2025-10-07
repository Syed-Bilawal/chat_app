import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/utils/app_utils.dart';
import 'package:chat_app/widgets/text_f_widget.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();

  void signUp(BuildContext context) async {
    if (signUpFormKey.currentState!.validate()) {
      if (passwordController.text != confirmPasswordController.text) {
        AppUtils.showErrorToast('Passwords do not match');
        return;
      }
      try {
        AppUtils.showLoading(context);
        AuthService authService = AuthService();
        await authService.signUpEmailPassword(
          emailController.text,
          passwordController.text,
        );
        AppUtils.hideLoading(context);
        // The AuthGate will automatically navigate to HomeScreen
        // when the auth state changes
      } catch (e) {
        AppUtils.hideLoading(context);
        AppUtils.showErrorToast(e.toString());
      }
    } else {
      AppUtils.showErrorToast('Please fill all the fields');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Sign Up Screen')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: signUpFormKey,
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
              TextFieldWidget(
                isPassword: true,
                inputType: TextInputType.visiblePassword,
                label: 'Confirm Password',
                textEditingController: confirmPasswordController,
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    signUp(context);
                  },
                  child: Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
