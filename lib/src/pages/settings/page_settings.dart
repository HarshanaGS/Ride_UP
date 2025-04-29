import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_show_dialog.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  Usuario? _usuario;
  bool _isLoading = false;
  late List<Map<String, dynamic>> _itensLista;

  @override
  void initState() {
    super.initState();
    _getUsuario();

    _itensLista = [
      {
        'name': 'Home',
        'subtitle': 'Not defined',
        'icon': Icons.home_filled,
      },
      {
        'name': 'Privacy',
        'subtitle': 'Control the information you share with us',
        'icon': Icons.lock_rounded,
      },
      {
        'name': 'Accessibility',
        'subtitle': 'Manage your accessibility settings',
        'icon': Icons.accessibility,
      },
    ];
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
        _usuario = Usuario.fromMap(snapshot.data()!, firebaseUser.uid);
      });
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      print("User not found in database.");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildUserAvatar(Usuario? usuario) {
    String? fotoUrl = usuario?.fotoUrl;
    String inicial = usuario?.name?.isNotEmpty == true
        ? usuario!.name![0].toUpperCase()
        : 'U';

    return CircleAvatar(
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
    );
  }

  String _formatarname(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'Profile';

    List<String> names = fullName.split(' ');
    return names.length > 1 ? '${names[0]} ${names[1][0]}.' : names[0];
  }

  void _deslogarUsuario() {
    _ConfirmSairConta();
  }

  void _ConfirmSairConta() {
    customShowDialog(
      context: context,
      title: 'Log Out',
      content: const Text('Are you sure you want to log out of your account?'),
      cancelText: 'Cancel',
      onCancel: () => Navigator.pop(context),
      confirmText: 'Log Out',
      confirmTextColor: Colors.red,
      onConfirm: () async {
        try {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          if (mounted) {
            CustomSnackbar.show(context, 'Error logging out of account: $e');
          }
        }
      },
    );
  }

  Widget _modeloListTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textColor,
        size: 25,
      ),
      title: Text(
        title,
        style: TextStyle(color: AppColors.textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.secundarytextColor),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.secundaryColor,
      ),
      onTap: () {},
    );
  }

  Widget _divider() => Divider(thickness: 4, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.secundaryColor),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  onTap: () => Navigator.pushNamed(context, '/management'),
                  leading: _buildUserAvatar(_usuario),
                  title: Text(
                    _formatarname(_usuario?.name),
                    style: TextStyle(color: AppColors.textColor),
                  ),
                  subtitle: Text(
                    _usuario?.email ?? 'Email not available',
                    style: TextStyle(color: AppColors.secundarytextColor),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.secundaryColor,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        'Basic information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: List.generate(
                    _itensLista.length,
                    (index) {
                      final item = _itensLista[index];
                      return _modeloListTile(
                          item['name'], item['subtitle'], item['icon']);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 5),
                  child: _divider(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _deslogarUsuario,
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
