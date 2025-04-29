import 'package:flutter/material.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final List<String> listItems = [
    'Account',
    'Accessibility',
    'Report a map issue',
    'Issue with a specific trip and refunds',
  ];

  Widget _modeloListTile(String title) {
    return ListTile(
      leading: Icon(
        Icons.list_outlined,
        color: AppColors.textColor,
        size: 25,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.secundaryColor,
      ),
      onTap: () {},
    );
  }

  Widget _divider() => Divider(thickness: 1, color: AppColors.secundaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All topics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.separated(
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  return _modeloListTile(listItems[index]);
                },
                separatorBuilder: (context, index) => _divider(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
