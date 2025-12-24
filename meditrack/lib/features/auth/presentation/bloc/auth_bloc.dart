import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/services/app_constants.dart';
import 'package:meta/meta.dart';

import '../../../../services/global.dart';
import '../../data/auth_remote_request.dart';

part 'auth_event.dart';
part 'auth_state.dart';

String baseUrl = AppConstants.baseUrl;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final authService = FirebaseAuthService();

  AuthBloc() : super(AuthInitial()) {
    on<SignupClickedEvent>(_signupClickedEvent);
    on<SigninClickedEvent>(_signinClickedEvent);
  }

  FutureOr<void> _signupClickedEvent(
    SignupClickedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    if (event.fullName.isEmpty ||
        event.password.isEmpty ||
        event.confirmPassword.isEmpty) {
      emit(AuthFailureState(errMsg: "required input is empty"));
    }
    // Inside Bloc Event Handler:
    try {
      User? user = await authService.signUp(
        name: event.fullName,
        phone: event.phone,
        password: event.password,
      );
      if (user != null) {
        await Global.storageServices.saveUserId(user.uid);
        emit(AuthSuccessState());
      }
    } catch (e) {
      emit(AuthFailureState(errMsg: e.toString()));
    }
  }

  FutureOr<void> _signinClickedEvent(
    SigninClickedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    if (event.phone.isEmpty || event.password.isEmpty) {
      emit(AuthFailureState(errMsg: "required input is empty"));
    }

    emit(AuthLoadingState());
    try {
      final user = await authService.signIn(
        phone: event.phone,
        password: event.password,
      );
      if (user != null) {
        await Global.storageServices.saveUserId(user.uid);
        emit(AuthSuccessState());
      }
    } catch (e) {
      emit(AuthFailureState(errMsg: e.toString()));
    } // signin logic
  }
}
