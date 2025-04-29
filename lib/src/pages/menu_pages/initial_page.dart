import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_overlay.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/pages/menu_pages/activity_page.dart';
import 'package:SharedJourney/src/pages/menu_pages/account_page.dart';
import 'package:SharedJourney/src/pages/menu_pages/home_page.dart';
import 'package:SharedJourney/src/pages/driver_panel.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  String? userType;

  int _selectedIndex = 0;
  bool _isCurrentPage = true;

  @override
  void initState() {
    super.initState();
    _isCurrentPage = true;
    _getuserType();
  }

  @override
  void dispose() {
    _isCurrentPage = false;
    super.dispose();
  }

  Future<void> _getuserType() async {
    User? firebaseUser = await FirebaseUser.getCurrentUser();
    if (firebaseUser == null) return;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await db.collection('usuarios').doc(firebaseUser.uid).get();

    if (snapshot.exists) {
      setState(() {
        userType = snapshot.data()?['userType'];
      });

      print("User type: $userType");

      _checkActiveRequest();
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      print("User not found in database.");
    }
  }

  Future<void> _checkActiveRequest() async {
    if (userType == null || !_isCurrentPage) return;

    Usuario? usuario = await FirebaseUser.getLoggedUserData();
    if (usuario == null) return;

    FirebaseFirestore db = FirebaseFirestore.instance;
    String colecaoRequisicao = userType == 'passenger'
        ? 'active-request'
        : 'active-request-driver';

    DocumentSnapshot<Map<String, dynamic>> requisicao =
        await db.collection(colecaoRequisicao).doc(usuario.id).get();


  }

  void _redirectToPanel() {
    if (!mounted || userType == null) return;

    String rota = userType == 'passenger'
        ? '/passenger-panel'
        : '/driver-panel';

    Navigator.pushReplacementNamed(context, rota);
  }

  List<Widget> _buildPages() {
    List<Widget> pages = [
      HomePage(userType, updateIndex: _onItemTapped),
      ActivityPage(userType),
      AccountPage(userType, updateIndex: _onItemTapped),
    ];

    if (userType == 'driver') {
      pages.insert(1, const Paneldriver());
    }

    return pages;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _bottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.secundaryColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Start'),
          if (userType == 'driver')
            const BottomNavigationBarItem(
                icon: Icon(Icons.car_crash_rounded), label: 'Calls'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.library_books_rounded), label: 'Activity'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      toolbarHeight: (_selectedIndex == 3 ||
              (userType == 'passenger' && _selectedIndex == 2))
          ? 100
          : kToolbarHeight,
      title: FutureBuilder<Usuario?>(
        future: FirebaseUser.getLoggedUserData(),
        builder: (context, snapshot) {
          return _buildTitle(snapshot.data);
        },
      ),
      titleTextStyle: Theme.of(context).textTheme.titleMedium,
      actions: [
        FutureBuilder<Usuario?>(
          future: FirebaseUser.getLoggedUserData(),
          builder: (context, snapshot) {
            return ((_selectedIndex == 3 && userType == 'driver') ||
                    (_selectedIndex == 2 && userType == 'passenger'))
                ? Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: _buildUserAvatar(snapshot.data),
                  )
                : Container();
          },
        ),
      ],
    );
  }

  Widget _buildTitle(Usuario? usuario) {
    String title = 'RIDE UP';

    if (userType == 'driver') {
      if (_selectedIndex == 1) {
        title = 'Trip Details';
      } else if (_selectedIndex == 2) {
        title = 'activity';
      } else if (_selectedIndex == 3) {
        title = _formatarname(usuario?.name);
      }
    } else {
      if (_selectedIndex == 1) {
        title = 'activity';
      } else if (_selectedIndex == 2) {
        title = _formatarname(usuario?.name);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if ((userType == 'driver' && _selectedIndex == 3) ||
            (userType == 'passenger' && _selectedIndex == 2))
          _buildUserRating(usuario),
      ],
    );
  }

  String _formatarname(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'Profile';

    List<String> names = fullName.split(' ');
    return names.length > 1 ? '${names[0]} ${names[1][0]}.' : names[0];
  }

  Widget _buildUserRating(Usuario? usuario) {
    double assessment = usuario?.assessment ?? 0.0;

    return GestureDetector(
      onTap: () {
        CustomOverlay.show(
          context,
          texto: "This assessment is based on the average feedback received.",
          top: MediaQuery.of(context).size.height * 0.18,
          left: 80,
          right: 20,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              assessment.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Usuario? usuario) {
    String? fotoUrl = usuario?.fotoUrl;
    String inicial = (usuario?.name != null && usuario!.name!.isNotEmpty)
        ? usuario.name![0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: updatePhoto,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.secundaryColor,
        backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
            ? NetworkImage(fotoUrl)
            : null,
        child: (fotoUrl == null || fotoUrl.isEmpty)
            ? Text(
                inicial,
                style: const TextStyle(color: Colors.white, fontSize: 25),
              )
            : null,
      ),
    );
  }

  void updatePhoto() {
    Navigator.pushNamed(context, '/management');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: userType == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPages()[_selectedIndex],
            ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }
}
