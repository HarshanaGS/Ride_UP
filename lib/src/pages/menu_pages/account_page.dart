import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class AccountPage extends StatefulWidget {
  final String? userType;
  final Function(int) updateIndex;

  const AccountPage(
    this.userType, {
    super.key,
    required this.updateIndex,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String userType = '';
  double balanceWithdraw = 0.00;
  double totalBalance = 0.00;
  bool isLoading = true;
  bool transactionOn = false;

  @override
  void initState() {
    super.initState();
    userType = widget.userType!;
    _searchBalance();
  }

  final List<Map<String, dynamic>> smallCardItems = [
    {'icon': Icons.sos_rounded, 'text': 'help'},
    {'icon': Icons.wallet, 'text': 'wallet'},
    {'icon': Icons.my_library_books_rounded, 'text': 'activity'},
  ];

  final List<Map<String, dynamic>> bigCardItems = [
    {
      'icon': Icons.apps_rounded,
      'title': 'Discover our app',
      'subtitle': "Take a tour to learn about all the app's features",
    },
    {
      'icon': Icons.privacy_tip_sharp,
      'title': 'Security Check',
      'subtitle': 'Learn how to travel safer'
    },
    {
      'icon': Icons.my_library_books_rounded,
      'title': 'Privacy control',
      'subtitle': 'FTake an interactive tour of your privacy settings'
    },
  ];

  final List<Map<String, dynamic>> optionsItems = [
    {'icon': Icons.settings, 'title': 'Settings'},
    {'icon': Icons.person, 'title': 'Manage Uber Account'},
  ];

  void _navigationNextPage(String title) {
    switch (title) {
      case 'Settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'activity':
        if (userType == 'passenger') {
          widget.updateIndex(1);
        } else {
          widget.updateIndex(2);
        }
        break;
      case 'Portfolio':
        Navigator.pushNamed(context, '/Portfolio');
        break;
      case 'Help':
        Navigator.pushNamed(context, '/Help');
        break;
      case 'Manage Uber Account':
        Navigator.pushNamed(context, '/management');
        break;
      default:
    }
  }

  Future<void> _searchBalance() async {
    Usuario? usuario = await FirebaseUser.getLoggedUserData();
    if (usuario == null || usuario.userType != 'driver') {
      setState(() => isLoading = false);
      return;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await db.collection('usuarios').doc(usuario.id).get();

    setState(() {
      balanceWithdraw = (userDoc.data()?['balance_withdraw'] ?? 0).toDouble();
      totalBalance = (userDoc.data()?['total_balance'] ?? 0).toDouble();
      isLoading = false;
    });
  }

  Future<void> _withdrawBalance() async {
    Usuario? usuario = await FirebaseUser.getLoggedUserData();
    if (usuario == null || usuario.userType != 'driver') return;

    if (balanceWithdraw == 0) {
      CustomSnackbar.show(context, 'There is no value to be withdrawn');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        bool carregando = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double larguraAlert = MediaQuery.of(context).size.width;
            double alturaAlert = MediaQuery.of(context).size.height;
            return AlertDialog(
              backgroundColor: AppColors.secundaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                'Withdraw Balance',
                style: TextStyle(color: AppColors.textColor),
              ),
              content: carregando
                  ? SizedBox(
                      width: larguraAlert * 0.06,
                      height: alturaAlert * 0.06,
                      child: const Center(child: CircularProgressIndicator()))
                  : const Text(
                      'Are you sure you want to withdraw your available balance?'),
              actions: [
                carregando
                    ? Container()
                    : TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                TextButton(
                  onPressed: carregando
                      ? null
                      : () async {
                          setStateDialog(() {
                            carregando = true;
                          });

                          try {
                            FirebaseFirestore db = FirebaseFirestore.instance;
                            await db
                                .collection('usuarios')
                                .doc(usuario.id)
                                .update({'balance_withdraw': 0});

                            await Future.delayed(
                                const Duration(milliseconds: 1500));

                            setState(() {
                              balanceWithdraw = 0.00;
                            });

                            Navigator.pop(context);

                            CustomSnackbar.show(
                              context,
                              'Balance transferred successfully!',
                              backgroundColor: Colors.green,
                            );
                          } catch (e) {
                            CustomSnackbar.show(
                              context,
                              'Error performing transaction. Please try again later',
                            );

                            setStateDialog(() {
                              carregando = false;
                            });
                          }
                        },
                  child: Text(
                    'Withdraw',
                    style: TextStyle(
                        color: carregando ? Colors.grey : Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _driverbalance() {
    double tamanhoCard = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secundaryColor, width: 1),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [AppColors.primaryColor, AppColors.secundaryColor],
          ),
        ),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance to withdraw',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor)),
                const SizedBox(height: 8),
                isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('LKR ${balanceWithdraw.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor)),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.textColor),
                        ],
                      ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 10),
                  child: Text(
                      'Total already invoiced: LKR ${totalBalance.toStringAsFixed(2)}',
                      style: TextStyle(color: AppColors.secundarytextColor)),
                ),
                SizedBox(
                  width: tamanhoCard * 0.6,
                  height: 50,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(AppColors.textColor),
                      foregroundColor:
                          WidgetStatePropertyAll(AppColors.primaryColor),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    onPressed: _withdrawBalance,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Withdraw balance'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.secundaryColor),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (userType == 'driver') _driverbalance(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      smallCardItems.length,
                      (index) => Padding(
                        padding:
                            smallCardItems[index]['text'] == 'Settings'
                                ? const EdgeInsets.symmetric(horizontal: 5)
                                : const EdgeInsets.all(0),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width /
                                  smallCardItems.length -
                              16.67,
                          child: GestureDetector(
                            onTap: () => _navigationNextPage(
                                smallCardItems[index]['text']),
                            child: SizedBox(
                              height: 100,
                              child: Card(
                                color: AppColors.secundaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        smallCardItems[index]['icon'],
                                        color: AppColors.textColor,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        smallCardItems[index]['text'],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      bigCardItems.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: GestureDetector(
                          onTap: () =>
                              _navigationNextPage(bigCardItems[index]['title']),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 100,
                            child: Card(
                              color: AppColors.secundaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bigCardItems[index]['title'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                          ),
                                          Text(
                                            bigCardItems[index]['subtitle'],
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: AppColors
                                                    .secundarytextColor,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Icon(
                                        bigCardItems[index]['icon'],
                                        size: 35,
                                        color: AppColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: AppColors.secundaryColor, width: 3)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(
                      optionsItems.length,
                      (index) => GestureDetector(
                        onTap: () =>
                            _navigationNextPage(optionsItems[index]['title']),
                        child: ListTile(
                          leading: Icon(
                            optionsItems[index]['icon'],
                            size: 25,
                            color: AppColors.textColor,
                          ),
                          title: Text(
                            optionsItems[index]['title'],
                            style: TextStyle(color: AppColors.textColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
