import 'package:cinemax/core/configs/assets/app_images.dart';
import 'package:cinemax/presentation/Home/pages/home.dart';
import 'package:cinemax/presentation/auth/pages/signin.dart';
import 'package:cinemax/presentation/splash/bloc/splash_state.dart';
import 'package:cinemax/presentation/splash/bloc/splash_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/helper/navigation/app_navigation.dart';


class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SplashCubit,SplashState>(
        listener: (context, state) {
          if(state is UnAuthenticated){
            AppNavigator.pushReplacement(context, SigninPage());
          }
          if(state is Authenticated){
            AppNavigator.pushReplacement(context, const HomePage());
          }
        },
        child: Stack(
          children: [
            Container(
              decoration:  BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      AppImages.splashBackground
                  )
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xff1A1B20).withValues(alpha: 0),
                    const Color(0xff1A1B20)
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
