import 'package:cinemax/common/helper/message/display_message.dart';
import 'package:cinemax/common/helper/navigation/app_navigation.dart';
import 'package:cinemax/core/configs/theme/app_colors.dart';
import 'package:cinemax/data/auth/models/signup_req_params.dart';
import 'package:cinemax/domain/auth/usecases/signup.dart';
import 'package:cinemax/presentation/Home/pages/home.dart';
import 'package:cinemax/presentation/auth/pages/signin.dart';
import 'package:cinemax/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:reactive_button/reactive_button.dart';
import 'package:flutter/gestures.dart';

class SignupPage extends StatelessWidget {
   SignupPage({super.key});

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
            _signupText(),
              SizedBox(height: 30,),
            _emailTextField(),
              SizedBox(height: 20 ,),
            _passwordTextField(),
            SizedBox(height: 60,),
            _signupButton(context),
              SizedBox(height: 20,),
            _signinText(context),
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

  Widget _signupButton(BuildContext context) {
    return ReactiveButton(
      title: 'Sign Up',
      activeColor: AppColors.primary,
      onPressed: () async{
        await sl<SignupUseCase>().call(
          params: SignupReqParams(
            email: _emailCon.text,
            password: _passwordCon.text,
          )
        );
      },
      onSuccess: () {
        AppNavigator.pushAndRemove(context, const HomePage());
      },
      onFailure: (error) {
         DisplayMessage.errorMessage(error, context);
      },
    );
  }

  Widget _signinText(BuildContext context) {
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
            AppNavigator.push(context, SigninPage());  
            },
          ),
        ],
      ),
    );
  }

}