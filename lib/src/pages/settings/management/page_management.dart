import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/pages/settings/management/account_information_page.dart';
import 'package:SharedJourney/src/pages/settings/management/privacy_data_page.dart';
import 'package:SharedJourney/src/pages/settings/management/security_page.dart';
import 'package:SharedJourney/src/pages/settings/management/overview_page.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class GerenciamentoPage extends StatefulWidget {
  const GerenciamentoPage({super.key});

  @override
  State<GerenciamentoPage> createState() => _GerenciamentoPageState();
}

class _GerenciamentoPageState extends State<GerenciamentoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Usuario? usuario;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getUsuario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getUsuario() async {
    setState(() {
      _isLoading = true;
    });
    User? firebaseUser = await FirebaseUser.getCurrentUser();
    if (firebaseUser == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await db.collection('usuarios').doc(firebaseUser.uid).get();

    if (snapshot.exists && mounted) {
      setState(() {
        usuario = Usuario.fromMap(snapshot.data()!, firebaseUser.uid);
      });
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      print("user not found in database.");
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabPages = [
      VisaoGeralPage(usuario),
      InformacoesAccountPage(usuario),
      SecurityPage(usuario),
      PrivacyDataPage(usuario),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(' Account'),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          dividerHeight: 3,
          dividerColor: AppColors.secundaryColor,
          indicatorColor: AppColors.textColor,
          labelColor: AppColors.textColor,
          indicatorSize: TabBarIndicatorSize.tab,
          unselectedLabelColor: AppColors.secundaryColor,
          splashBorderRadius: BorderRadius.circular(5),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Account Information'),
            Tab(text: 'Security'),
            Tab(text: 'Privacy and Data'),
          ],
        ),
      ),
      body: _isLoading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.secundaryColor),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: TabBarView(
                controller: _tabController,
                children: tabPages,
              ),
            ),
    );
  }
}
