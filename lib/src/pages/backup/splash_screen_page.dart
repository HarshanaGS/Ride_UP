import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  List<double> opacities = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _iniciarVerificacao();
  }

  void _iniciarVerificacao() async {
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < opacities.length; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          opacities[i] = 1.0;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    _verificarUsuarioLogado();
  }

  Future<void> _verificarUsuarioLogado() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;

      User? usuarioLogado = auth.currentUser;
      if (usuarioLogado != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await db.collection('usuarios').doc(usuarioLogado.uid).get();

        if (userDoc.exists) {
          String? userType = userDoc.data()?['userType'];
          _checkActiveRequest(usuarioLogado.uid, userType);
          return;
        } else {
          CustomSnackbar.show(context, "User not found in database!");
        }
      }
      _redirecionarParaLogin();
    } catch (e) {
      CustomSnackbar.show(context, "Error checking logged in user: $e");
      _redirecionarParaLogin();
    }
  }

  Future<void> _checkActiveRequest(
      String uid, String? userType) async {
    if (userType == null) {
      CustomSnackbar.show(context, "Error identifying user type.");
      _redirecionarParaLogin();
      return;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    String colecaoRequisicao = userType == 'passenger'
        ? 'active-request'
        : 'active-request-driver';

    DocumentSnapshot<Map<String, dynamic>> requisicao =
        await db.collection(colecaoRequisicao).doc(uid).get();

    if (requisicao.exists) {
      _redirectToPanel(userType);
    } else {
      _redirectUser(userType);
    }
  }

  void _redirectToPanel(String userType) {
    if (!mounted) return;

    String rota = userType == 'passenger'
        ? '/passenger-panel'
        : '/driver-panel';

    Navigator.pushReplacementNamed(context, rota);
  }

  void _redirectUser(String userType) {
    if (!mounted) return;

    if (userType == 'driver' || userType == 'passenger') {
      Navigator.pushReplacementNamed(context, '/initial');
    } else {
      CustomSnackbar.show(context, "Invalid user type!");
      _redirecionarParaLogin();
    }
  }

  void _redirecionarParaLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: opacities[index],
              child: Text(
                "RideX"[index],
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
