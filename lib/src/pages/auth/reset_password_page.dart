import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/components/custom_input_text.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendReset() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text);

      CustomSnackbar.show(
        context,
        'Reset email sent!',
        backgroundColor: AppColors.secundaryColor,
        textColor: AppColors.textColor,
      );
      Navigator.pop(context);
    } catch (e) {
      CustomSnackbar.show(context, 'Erro: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  String? _validator(String? text) {
    final regex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com|outlook\.com|yahoo\.com)$');
    if (text == null || text.trim().isEmpty) {
      return 'Field cannot be empty';
    } else if (!regex.hasMatch(text.trim())) {
      return 'Please enter a valid email address (@gmail.com, @hotmail.com, etc.)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your Email',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              'Enter your email in the field below to receive a password reset link.',
              style: TextStyle(color: AppColors.secundarytextColor),
            ),
            const SizedBox(height: 15),
            CustomInputText(
              controller: _emailController,
              hintText: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              enable: !_isLoading,
              isLoading: _isLoading,
              hintStyle: TextStyle(
                color: AppColors.secundarytextColor,
                fontSize: 15,
              ),
              textColor: AppColors.textColor,
              cursorColor: AppColors.textColor,
              maxLength: 50,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.secundaryColor),
              ),
              validator: _validator,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: CustomButton(
                text: 'Send Reset Email',
                funtion: _sendReset,
                isLoading: _isLoading,
                enabled: !_isLoading,
                backgroundColor: AppColors.secundaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
