import 'package:cinemax/data/auth/models/signup_req_params.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {

  Future <Either>signUp(SignupReqParams params);

}  