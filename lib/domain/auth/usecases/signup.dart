import 'package:cinemax/core/usecase/usecase.dart';
import 'package:cinemax/data/auth/models/signup_req_params.dart';
import 'package:cinemax/domain/auth/repositories/auth.dart';
import 'package:cinemax/service_locator.dart';
import 'package:dartz/dartz.dart';

class SignupUseCase extends Usecase<Either, SignupReqParams> {

  @override
  Future<Either> call({SignupReqParams? params}) async {
    return await sl<AuthRepository>().signup(params!);
  }
}