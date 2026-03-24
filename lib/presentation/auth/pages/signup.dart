import 'package:cinemax/common/helper/navigation/app_navigation.dart';
import 'package:cinemax/core/configs/theme/app_colors.dart';
import 'package:cinemax/presentation/auth/pages/signin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reactive_button/reactive_button.dart';
import 'package:flutter/gestures.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(top: 100, right: 16, left: 16 ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _signupText(),
              SizedBox(height: 30,),
            _emailTextField(),
              SizedBox(height: 20 ,),
            _passwordTextField(),
            SizedBox(height: 60,),
            _signupButton(),
              SizedBox(height: 20,),
            _SigninText(context),
          ],
        )
      )
    );
  }

  Widget _signupText() {
    return const Text(
      'Sign Up',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emailTextField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Email',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _passwordTextField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Password',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _signupButton() {
    return ReactiveButton(
      title: 'Sign Up',
      activeColor: AppColors.primary,
      onPressed: () async{},
      onSuccess: () {},
      onFailure: (error) {},
    );
  }

  Widget _SigninText(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Already have an account? ',
        style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Sign In',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()..onTap = () {
              // Navigate to the sign-in page
            AppNavigator.push(context, const SigninPage());  
            },
          ),
        ],
      ),
    );
  }

}