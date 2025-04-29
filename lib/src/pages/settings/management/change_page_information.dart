import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/components/custom_input_text.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class AlterarInformacaoPage extends StatefulWidget {
  final String? info;
  const AlterarInformacaoPage(this.info, {super.key});

  @override
  State<AlterarInformacaoPage> createState() => _AlterarInformacaoPageState();
}

class _AlterarInformacaoPageState extends State<AlterarInformacaoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _ConfirmPasswordController =
      TextEditingController();
  String mensagemInput = '';
  String mensagemTitle = '';
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  @override
  void initState() {
    super.initState();
    _setMensagens();
  }

  void _setMensagens() async {
    Usuario? usuario = await FirebaseUser.getLoggedUserData();
    if (usuario == null) return;

    setState(() {
      mensagemInput = widget.info == 'Password'
          ? '••••••••'
          : (usuario.toMap()[widget.info!.toLowerCase()] ?? '');
      mensagemTitle = widget.info == 'Password'
          ? 'Change your new ${widget.info}'
          : 'Change your new ${widget.info}';
    });
  }

  Future<void> _alterarInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Usuario? usuario = await FirebaseUser.getLoggedUserData();
      if (usuario == null) return Navigator.pop(context);

      widget.info == 'Password'
          ? await _alterarPassword()
          : await _alterarDadoFirebase(usuario);

      CustomSnackbar.show(
        context,
        '${widget.info} changed successfully!',
        backgroundColor: Colors.green,
      );
      Navigator.pop(context);
    } catch (e) {
      CustomSnackbar.show(
        context,
        'Erro ao alterar ${widget.info!.toLowerCase()}. Try again!',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _alterarPassword() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return Navigator.pop(context);

    try {
      await user.updatePassword(_ConfirmPasswordController.text);
    } catch (e) {
      CustomSnackbar.show(context, 'Unable to change Password: $e');
    }
  }

  Future<void> _alterarDadoFirebase(Usuario usuario) async {
    FirebaseFirestore.instance.collection('usuarios').doc(usuario.id).update({
      widget.info!.toLowerCase(): _infoController.text.trim(),
    });
  }

  String? _validator(String? text) {
    if (text == null || text.trim().isEmpty) {
      return '${widget.info} cannot be empty';
    }

    if (widget.info == 'Email') {
      final regex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com|outlook\.com|yahoo\.com)$');
      if (!regex.hasMatch(text.trim())) {
        return 'Please provide a valid email address (@gmail.com, @hotmail.com, etc.).)';
      }
    } else if (widget.info == 'Password') {
      final regex =
          RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
      if (!regex.hasMatch(text.trim())) {
        return 'The password must be at least 8 characters long, including at least one uppercase letter, one lowercase letter, one number, and one special character.';
      } else if (_infoController.text != _ConfirmPasswordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    TextInputType keyboardType = {
          'name': TextInputType.name,
          'Email': TextInputType.emailAddress,
          'Password': TextInputType.visiblePassword,
        }[widget.info] ??
        TextInputType.text;

    return Scaffold(
      appBar: AppBar(title: Text('Alterar ${widget.info}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(mensagemTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 15),
                if (widget.info == 'Password') ...[
                  CustomInputText(
                    controller: _infoController,
                    hintText: 'New Password',
                    isPassword: true,
                    obscureText: _obscureText,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    iconColor: AppColors.textColor,
                    enable: !_isLoading,
                    isLoading: _isLoading,
                    keyboardType: keyboardType,
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
                  const SizedBox(height: 15),
                  CustomInputText(
                    controller: _ConfirmPasswordController,
                    hintText: 'Confirm password',
                    isPassword: true,
                    obscureText: _obscureConfirmText,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureConfirmText = !_obscureConfirmText;
                      });
                    },
                    iconColor: AppColors.textColor,
                    enable: !_isLoading,
                    isLoading: _isLoading,
                    keyboardType: keyboardType,
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
                    validator: (text) => text != _infoController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                ] else
                  CustomInputText(
                    controller: _infoController,
                    hintText: mensagemInput,
                    hintStyle: TextStyle(
                      color: AppColors.secundarytextColor,
                      fontSize: 15,
                    ),
                    textColor: AppColors.textColor,
                    cursorColor: AppColors.textColor,
                    keyboardType: keyboardType,
                    maxLength: 50,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.secundaryColor),
                    ),
                    validator: _validator,
                  ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.center,
                  child: CustomButton(
                    text: 'Update',
                    funtion: _alterarInfo,
                    isLoading: _isLoading,
                    enabled: !_isLoading,
                    backgroundColor: AppColors.secundaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
