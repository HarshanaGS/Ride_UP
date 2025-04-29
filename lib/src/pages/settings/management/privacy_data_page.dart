import 'package:flutter/material.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class PrivacyDataPage extends StatefulWidget {
  final Usuario? usuario;
  const PrivacyDataPage(this.usuario, {super.key});

  @override
  State<PrivacyDataPage> createState() => _PrivacyDataPageState();
}

class _PrivacyDataPageState extends State<PrivacyDataPage> {
  Usuario? usuario;
  //final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  Widget _divider() => Divider(thickness: 1, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy and Data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          const Text(
            'Privacy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListTile(
            onTap: () {},
            contentPadding: const EdgeInsets.only(right: 10),
            title: Text(
              'Privacy Center',
              style: TextStyle(color: AppColors.textColor),
            ),
            subtitle: Text(
              'Control the privacy of your personal data and find out how we protect it.',
              style: TextStyle(color: AppColors.secundarytextColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.secundaryColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 15),
            child: _divider(),
          ),
          const Text(
            'Third-party apps with account access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Third-party apps that have permission to access your account appear here. Learn more.',
            style: TextStyle(color: AppColors.secundarytextColor),
          ),
        ],
      ),
    );
  }
}
