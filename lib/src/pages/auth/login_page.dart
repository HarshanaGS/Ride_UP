import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/components/custom_input_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _PasswordController = TextEditingController();
  bool _isPassword = true;
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> login(String email, String Password) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;

      UserCredential userCredential =
          await auth.signInWithEmailAndPassword(email: email, password: Password);

      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await db.collection('usuarios').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        throw Exception("User not found in database!");
      }

      _redirectUser(userDoc.data()?['userType']);
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      CustomSnackbar.show(context,
          'Error authenticating user. Check email and password and try again!');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _redirectUser(String? userType) {
    if (userType == 'driver' || userType == 'passenger') {
      Navigator.pushNamedAndRemoveUntil(context, '/initial', (_) => false);
    } else {
      CustomSnackbar.show(context, "Invalid user type!");
    }
  }

  void _navigatorForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/logo_text.png')),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomInputText(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        isLoading: _isLoading,
                        errorText:
                            _hasError ? 'Incorrect email or password' : null,
                        onChanged: (value) {
                          setState(() {
                            _hasError = false;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'This field is required!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomInputText(
                        controller: _PasswordController,
                        hintText: 'Password',
                        keyboardType: TextInputType.text,
                        isLoading: _isLoading,
                        isPassword: true,
                        obscureText: _isPassword,
                        errorText:
                            _hasError ? 'Incorrect email or password' : null,
                        onChanged: (value) {
                          setState(() {
                            _hasError = false;
                          });
                        },
                        onSuffixIconPressed: () {
                          setState(() {
                            _isPassword = !_isPassword;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'This field is required!';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _navigatorForgotPassword,
                          child: Text(
                            'Forgot your password?',
                            style: TextStyle(color: AppColors.textColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Enter',
                        funtion: () {
                          login(
                            _emailController.text,
                            _PasswordController.text,
                          );
                        },
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                        backgroundColor: AppColors.secundaryColor,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: AppColors.secundarytextColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
