import 'package:cinemax/core/usecase/usecase.dart';
import 'package:cinemax/data/auth/models/signin_req_params.dart';
import 'package:cinemax/domain/auth/repositories/auth.dart';
import 'package:cinemax/service_locator.dart';
import 'package:dartz/dartz.dart';

class SigninUseCase extends Usecase<Either, SigninReqParams> {

  @override
  Future<Either> call({SigninReqParams? params}) async {
    return await sl<AuthRepository>().signin(params!);
  }
}