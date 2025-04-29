import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:SharedJourney/src/components/custom_input_text.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/status_request.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

import '../GoogleMapWebView.dart';

class HomePage extends StatefulWidget {
  final String? userType;
  final Function(int) updateIndex;

  const HomePage(
      this.userType, {
        super.key,
        required this.updateIndex,
      });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userType = '';
  final TextEditingController _destinationController = TextEditingController();
  late List<Map<String, dynamic>> _itensSugestoes;
  bool _emactivity = false;
  Color _corEstado = Colors.red;
  String _imageSugestao = '';
  String _textoSugestao = '';

  @override
  void initState() {
    super.initState();
    _checkActivityStatus();
    userType = widget.userType!;
    _imageSugestao = userType == 'passenger'
        ? 'assets/images/mapa.png'
        : 'assets/images/carro.png';
    _textoSugestao = userType == 'passenger' ? 'Open Map' : 'Open Tickets';

    // Build the suggestion items list
    _itensSugestoes = [
      {
        'name': _textoSugestao,
        'image': _imageSugestao,
        'function': _abrirMapa,
      },
      {
        'name': 'Activity',
        'image': Icons.library_books_rounded,
        'function': _navegaractivity,
      },
      {
        'name': 'Settings',
        'image': Icons.settings,
        'function': _navigateSettings
      },
    ];

    // Add Drop Location button only for drivers
    if (userType == 'driver') {
      _itensSugestoes.add({
        'name': 'Drop Location',
        'image': Icons.location_on,
        'function': _setDropLocation,
      });
    }

    if (userType == 'passenger') {
      _itensSugestoes.insert(1, {
        'name': 'Shared Trip',
        'image': Icons.group, // or use your own asset
        'function': _openSharedTrip,
      });
    }



  }

  void _openSharedTrip() {
    Navigator.pushNamed(context, '/shared-trip');
  }

  void _abrirMapa() {
    if (userType == 'passenger') {
      Navigator.pushNamed(context, '/passenger-panel');
    } else if (userType == 'driver') {
      widget.updateIndex(1);
    } else {
      CustomSnackbar.show(context, 'itWasNotPossibleToAccessTheMap');
    }
  }

  void _navegaractivity() {
    if (userType == 'passenger') {
      setState(() {
        widget.updateIndex(1);
      });
    } else {
      widget.updateIndex(2);
    }
  }

  void _navigateSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _setDropLocation() async {
    try {
      Usuario? usuario = await FirebaseUser.getLoggedUserData();

      if (usuario == null) {
        CustomSnackbar.show(context, 'User not found.');
        return;
      }

      // Find the first active trip with status 'trip' for the passenger
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('passenger.user_id', isEqualTo: usuario.id)
          .where('status', isEqualTo: StatusRequisicao.trip)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        CustomSnackbar.show(context, 'No active shared trip found.');
        return;
      }

      // Get the request ID and open map screen with passenger location
      var doc = querySnapshot.docs.first;
      String requestId = doc['id'];

      double passengerLat = doc['passenger']['latitude'];
      double passengerLng = doc['passenger']['longitude'];

      String googleMapsUrl =
          "https://www.google.com/maps/search/?api=1&query=$passengerLat,$passengerLng";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoogleMapWebView(
            googleMapsUrl: googleMapsUrl,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error loading shared trip: $e");
      CustomSnackbar.show(context, 'Error loading shared trip.');
    }
  }

  Future<void> _checkActivityStatus() async {
    try {
      Usuario? usuario = await FirebaseUser.getLoggedUserData();

      if (usuario != null) {
        DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
            .instance
            .collection('usuarios')
            .doc(usuario.id)
            .get();

        bool statusactivity = doc.data()?['activity_status'] ?? false;

        setState(() {
          _emactivity = statusactivity;
          _corEstado = _emactivity ? Colors.green : Colors.red;
        });
      }
    } catch (e) {
      print("ErrorWhenCheckingStatus: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userType == "passenger" ? _telapassenger() : _screendriver(),
    );
  }

  Widget _telapassenger() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.secundaryColor,
                borderRadius: BorderRadius.circular(20)),
            child: CustomInputText(
              controller: _destinationController,
              hintText: 'Where to?',
              hintStyle:
              TextStyle(color: AppColors.secundarytextColor, fontSize: 15),
              textColor: AppColors.textColor,
              keyboardType: TextInputType.text,
              cursorColor: AppColors.textColor,
              preffixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.secundarytextColor,
              ),
              onTap: () {
                Navigator.pushNamed(context, '/passenger-panel');
              },
              suffixIcon: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/passenger-panel');
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.primaryColor,
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'To schedule',
                      style: TextStyle(color: AppColors.textColor),
                    ),
                  ),
                ),
              ),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder:
              const OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          _ultimasCorridas(),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _suggestions(context),
        ],
      ),
    );
  }

  Widget _ultimasCorridas() {
    return FutureBuilder<Usuario?>(
      future: FirebaseUser.getLoggedUserData(),
      builder: (context, usuarioSnapshot) {
        if (usuarioSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!usuarioSnapshot.hasData || usuarioSnapshot.data == null) {
          return const Center(child: Text('Error loading user'));
        }

        String? userId = usuarioSnapshot.data!.id;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('requests')
              .where('$userType.user_id', isEqualTo: userId)
              .where('status', isEqualTo: StatusRequisicao.confirmed)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("You haven't done any trip yet"));
            }

            List<QueryDocumentSnapshot> corridas = snapshot.data!.docs;

            corridas.sort((a, b) {
              DateTime dataA = DateTime.parse(a['start_date']);
              DateTime dataB = DateTime.parse(b['start_date']);
              return dataB.compareTo(dataA);
            });

            corridas = corridas.take(2).toList();

            return Column(
              children: corridas.map((doc) {
                var dados = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/race-details',
                      arguments: {
                        'idCorrida': dados['id'].toString(),
                        'userType': widget.userType.toString(),
                        'userId': userId.toString(),
                      },
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                      BorderSide(color: AppColors.secundaryColor, width: 2),
                    ),
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secundaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.access_time_sharp,
                              color: AppColors.secundarytextColor,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 180,
                                child: Text(
                                  '${dados['destination']['road']}, ${dados['destination']['number']}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: Text(
                                  '${dados['destination']['neighborhood']} - ${dados['destination']['cep']}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(color: AppColors.textColor),
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.secundarytextColor,
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _modeloCard(String name, dynamic imageOuIcone, VoidCallback function,
      BuildContext context) {
    double screensize = MediaQuery.of(context).size.width;
    double fontSize = screensize > 600 ? 14 : (screensize > 400 ? 12 : 10);

    return GestureDetector(
      onTap: function,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.secundaryColor, width: 1.5),
        ),
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              imageOuIcone is String
                  ? Image.asset(imageOuIcone, height: 50, width: 50)
                  : Icon(
                imageOuIcone,
                size: 40,
                color: AppColors.secundarytextColor,
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestions(BuildContext context) {
    double screensize = MediaQuery.of(context).size.width;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _itensSugestoes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screensize > 600
            ? 5
            : screensize > 400
            ? 4
            : 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = _itensSugestoes[index];
        return _modeloCard(
            item['name'], item['image'], item['function'], context);
      },
    );
  }

  Widget _screendriver() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.secundaryColor,
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    Icons.circle_rounded,
                    color: _corEstado,
                  ),
                  Transform.scale(
                    scale: 1.25,
                    child: Switch(
                      value: _emactivity,
                      activeColor: AppColors.textColor,
                      inactiveTrackColor: AppColors.textColor,
                      inactiveThumbColor: Colors.grey[800],
                      trackOutlineWidth: const WidgetStatePropertyAll(0),
                      trackOutlineColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                      onChanged: (value) async {
                        setState(() {
                          _emactivity = value;
                          if (_emactivity) {
                            _corEstado = Colors.green;
                          } else {
                            _corEstado = Colors.red;
                          }
                        });

                        await _updateStatusactivity(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ultimasCorridas(),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _suggestions(context),
        ],
      ),
    );
  }

  Future<void> _updateStatusactivity(bool status) async {
    try {
      Usuario? usuario = await FirebaseUser.getLoggedUserData();

      if (usuario != null && usuario.userType == "driver") {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.id)
            .update({'activity_status': status});
      }
    } catch (e) {
      print("Error updating status: $e");
    }
  }
}
