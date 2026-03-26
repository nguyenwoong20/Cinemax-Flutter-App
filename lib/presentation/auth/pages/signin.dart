import 'package:cinemax/common/helper/message/display_message.dart';
import 'package:cinemax/common/helper/navigation/app_navigation.dart';
import 'package:cinemax/core/configs/theme/app_colors.dart';
import 'package:cinemax/data/auth/models/signin_req_params.dart';
import 'package:cinemax/domain/auth/usecases/signin.dart';
import 'package:cinemax/presentation/Home/pages/home.dart';
import 'package:cinemax/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:reactive_button/reactive_button.dart';
import 'package:flutter/gestures.dart';

class SigninPage extends StatelessWidget {
  SigninPage({super.key});

  final TextEditingController _emailCon = TextEditingController();
  final TextEditingController _passwordCon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(top: 100, right: 16, left: 16 ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _signinText(),
              SizedBox(height: 30,),
            _emailTextField(),
              SizedBox(height: 20 ,),
            _passwordTextField(),
            SizedBox(height: 60,),
            _signinButton(context),
              SizedBox(height: 20,),
            _signupText(context),
          ],
        )
      )
    );
  }

  Widget _signinText() {
    return const Text(
      'Sign In',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emailTextField() {
    return TextField(
      controller: _emailCon,
      decoration: const InputDecoration(
        hintText: 'Email',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _passwordTextField() {
    return TextField(
      controller: _passwordCon,
      decoration: const InputDecoration(
        hintText: 'Password',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _signinButton(BuildContext context) {
    return ReactiveButton(
      title: 'Sign In',
      activeColor: AppColors.primary,
      onPressed: () async => sl<SigninUseCase>().call(
        params: SigninReqParams(
          email: _emailCon.text,
          password: _passwordCon.text,
        )
      ),
      onSuccess: () {
        AppNavigator.pushAndRemove(context, const HomePage());
      },
      onFailure: (error) {
        DisplayMessage.errorMessage(error, context);
      }
    );
  }

  Widget _signupText(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Don\'t have an account? ',
        style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Sign Up',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()..onTap = () {
              // Navigate to the sign-up page
            AppNavigator.push(context, SigninPage());  
            },
          ),
        ],
      ),
    );
  }

}