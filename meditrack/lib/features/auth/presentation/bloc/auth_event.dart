part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class SignupClickedEvent extends AuthEvent {
  String fullName;
  String phone;
  String password;
  String confirmPassword;
  // String confirmPassword;

  SignupClickedEvent({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.confirmPassword,

  });
}

class SigninClickedEvent extends AuthEvent {
  String phone;
  String password;
  // String confirmPassword;

  SigninClickedEvent({
    required this.phone,
    required this.password,
  });
}
