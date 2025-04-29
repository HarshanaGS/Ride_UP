import 'package:flutter/material.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class SecurityPage extends StatefulWidget {
  final Usuario? usuario;
  const SecurityPage(this.usuario, {super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  Usuario? usuario;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  void _alterarInfo(String? info) {
    Navigator.pushNamed(context, '/change-info', arguments: info);
  }

  Widget _divider() => Divider(thickness: 1, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          const Text(
            'Log in to Rider',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            onTap: () {
              _alterarInfo('Password');
            },
            contentPadding: const EdgeInsets.only(right: 10),
            title: Text(
              'Password',
              style: TextStyle(color: AppColors.textColor),
            ),
            subtitle: Text(
              'Change your password',
              style: TextStyle(color: AppColors.secundarytextColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.secundaryColor,
            ),
          ),
          _divider(),
        ],
      ),
    );
  }
}
