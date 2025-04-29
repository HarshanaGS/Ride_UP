import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/components/custom_input_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _PasswordController = TextEditingController();
  final TextEditingController nicController = TextEditingController();

  final FocusNode _PasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPassword = true;
  bool _userType = false;

  bool hasUpperCase = false;
  bool hasLowerCase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  bool showPasswordCriteria = false;

  @override
  void initState() {
    super.initState();
    _PasswordFocusNode.addListener(() {
      setState(() {
        showPasswordCriteria = _PasswordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _PasswordController.dispose();
    super.dispose();
  }

  void _validarPassword(String value) {
    setState(() {
      hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
      hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
      hasNumber = RegExp(r'\d').hasMatch(value);
      hasSpecialChar = RegExp(r'[!@#\$&*~]').hasMatch(value);
      hasMinLength = value.length >= 8;
    });

    _formKey.currentState?.validate();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String name = _nameController.text.trim();
      String email = _emailController.text.trim();
      String Password = _PasswordController.text.trim();
      String userType = _userType ? "driver" : "passenger";

      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;

      UserCredential firebaseUser = await auth.createUserWithEmailAndPassword(
        email: email,
        password: Password,
      );

      await db.collection('usuarios').doc(firebaseUser.user!.uid).set({
        "name": name,
        "NIC": nicController.text,
        "email": email,
        "userType": userType,
        "foto_url": '',
        "assessment": 0.00,
      });

      _redirectUser(userType);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        CustomSnackbar.show(context, 'Connection failed. Check the internet.');
      } else {
        CustomSnackbar.show(context, 'Error registering user: ${e.message}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _redirectUser(String userType) {
    Navigator.pushNamedAndRemoveUntil(context, '/initial', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
                      image: AssetImage('assets/images/logo_text.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomInputText(
                        controller: _nameController,
                        hintText: 'Name',
                        keyboardType: TextInputType.name,
                        validator: (value) => value == null || value.isEmpty
                            ? 'This field is required!'
                            : null,
                      ),
                      CustomInputText(
                        controller: nicController,
                        hintText: 'NIC',
                        keyboardType: TextInputType.name,
                        validator: (value) => value == null || value.isEmpty
                            ? 'This field is required!'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      CustomInputText(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required!';
                          }
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          return emailRegex.hasMatch(value)
                              ? null
                              : 'Please enter a valid email address!';
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomInputText(
                        controller: _PasswordController,
                        hintText: 'Password',
                        keyboardType: TextInputType.text,
                        isPassword: true,
                        obscureText: _isPassword,
                        focusNode: _PasswordFocusNode,
                        onSuffixIconPressed: () {
                          setState(() => _isPassword = !_isPassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required!';
                          }
                          if (hasUpperCase &&
                              hasLowerCase &&
                              hasNumber &&
                              hasSpecialChar &&
                              hasMinLength) {
                            return null;
                          }
                          return 'Password does not meet All criteria!';
                        },
                        onChanged: _validarPassword,
                      ),
                      const SizedBox(height: 5),

                      if (showPasswordCriteria)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildPasswordCriteria(
                                  'At least 8 characters', hasMinLength),
                              buildPasswordCriteria(
                                  'capital letter', hasUpperCase),
                              buildPasswordCriteria(
                                  'A lowercase letter', hasLowerCase),
                              buildPasswordCriteria('A Number', hasNumber),
                              buildPasswordCriteria(
                                  'A special character (!@#\$&*~)',
                                  hasSpecialChar),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Text('Passenger'),
                          Switch(
                            value: _userType,
                            onChanged: (value) {
                              if (_userType != value) {
                                setState(() => _userType = value);
                              }
                            },
                            activeColor: AppColors.textColor,
                            inactiveTrackColor: Colors.grey,
                          ),
                          const Text('Driver'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Register',
                        funtion: _cadastrar,
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                        backgroundColor: AppColors.secundaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordCriteria(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red[800],
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red[800],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
