import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../config/routes/name.dart';
import '../../../../utils/common_snackbar.dart';
import '../common_auth_widget.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _agreedToTerms = false;
  final Color _primaryGreen = const Color(0xFF10B981);
  TextEditingController fullNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailureState) {
              commonSnackBar(context, "${state.errMsg}", Colors.white,
                  Colors.red.shade200);
            }
            if (state is AuthSuccessState) {
              Navigator.pushNamedAndRemoveUntil(
                  context, NamedRoutes.HomePage, (predicate) => false);
              return;
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Header ---
                  Image.asset(
                    "assets/logos/meditrack.png",
                    height: 100,
                    width: 150,
                  ),
                  const SizedBox(height: 24),
                  const Text("Welcome to MediTrack",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text("Automating your health, one dose at a time.",
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 32),

                  // --- Form Fields ---
                  UniTextField(
                    label: "Full Name",
                    hint: "Enter your full name",
                    prefixIcon: Icons.person_outline,
                    controller: fullNameController,
                  ),
                  const SizedBox(height: 16),
                  UniTextField(
                    label: "Phone Number",
                    hint: "Enter your phone number",
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    controller: phoneController,
                  ),
                  const SizedBox(height: 16),
                  UniTextField(
                    label: "Password",
                    hint: "Create a strong password",
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Password must contain at least 8 characters",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 20),

                  // --- Terms Checkbox ---
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          activeColor: _primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(
                                  text: "Terms of Service",
                                  style: TextStyle(
                                      color: _primaryGreen,
                                      fontWeight: FontWeight.bold)),
                              const TextSpan(text: " and "),
                              TextSpan(
                                  text: "Privacy Policy",
                                  style: TextStyle(
                                      color: _primaryGreen,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Create Account Button ---
                  BouncingButton(
                    onTap: () {
                      if (passwordController.text.isEmpty ||
                          phoneController.text.isEmpty ||
                          fullNameController.text.isEmpty) {
                        commonSnackBar(context, "Required input are empty.",
                            Colors.white, Colors.red.shade300);
                      } else {
                        context.read<AuthBloc>().add(SignupClickedEvent(
                            fullName: fullNameController.text,
                            phone: phoneController.text,
                            password: passwordController.text,
                            confirmPassword: passwordController.text));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: _primaryGreen.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                        child: Text("Create Account",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Divider ---
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("or",
                              style: TextStyle(color: Colors.grey.shade600))),
                      const Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Social Buttons ---
                  const SocialButton(
                    text: "Continue with Google",
                    icon: Icons.g_mobiledata,
                    iconColor: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const SocialButton(
                    text: "Continue with Apple",
                    icon: Icons.apple,
                    iconColor: Colors.black,
                  ),
                  const SizedBox(height: 30),

                  // --- Footer ---
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      children: [
                        const TextSpan(text: "Already have an account? "),
                        TextSpan(
                          text: "Log In",
                          style: TextStyle(
                              color: _primaryGreen,
                              fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(
                                  context, NamedRoutes.SigninPage);
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Security Badge ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security, color: _primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Your data is secure",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
