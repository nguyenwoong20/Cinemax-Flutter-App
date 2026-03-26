import 'package:cinemax/data/repositories/auth.dart';
import 'package:cinemax/data/sources/auth_api_service.dart';
import 'package:cinemax/core/network/dio_client.dart';
import 'package:cinemax/domain/auth/repositories/auth.dart';
import 'package:cinemax/domain/auth/usecases/signin.dart';
import 'package:cinemax/domain/auth/usecases/signup.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerSingleton<DioClient>(DioClient());
  sl.registerSingleton<AuthApiService>(AuthApiServiceImpl());
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  sl.registerSingleton<SignupUseCase>(SignupUseCase());
  sl.registerSingleton<SigninUseCase>(SigninUseCase());
}