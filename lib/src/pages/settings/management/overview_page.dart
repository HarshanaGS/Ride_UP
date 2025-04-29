import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class VisaoGeralPage extends StatefulWidget {
  final Usuario? usuario;
  const VisaoGeralPage(this.usuario, {super.key});

  @override
  State<VisaoGeralPage> createState() => _VisaoGeralPageState();
}

class _VisaoGeralPageState extends State<VisaoGeralPage> {
  Usuario? usuario;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
  }

  String _formatarname(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'Profile';

    List<String> names = fullName.split(' ');
    return names.length > 1 ? '${names[0]}.' : names[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${_formatarname(usuario!.name)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          Text(
            'Manage your information, security and data so the Uber platform works best for you.',
            style: TextStyle(color: AppColors.secundarytextColor),
          ),
          const SizedBox(height: 15),
          Card(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: AppColors.secundaryColor,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'checkYourAccount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Icon(
                          Icons.discount_rounded,
                          color: AppColors.secundarytextColor,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                      'Verify your account to help the Uber platform work better for you and help keep you safe.'),
                  const SizedBox(height: 15),
                  CustomButton(
                    width: MediaQuery.of(context).size.width * 0.6,
                    backgroundColor: AppColors.secundarytextColor,
                    text: 'check',
                    funtion: () {},
                    isLoading: _isLoading,
                    enabled: !_isLoading,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
