import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/status_request.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class Paneldriver extends StatefulWidget {
  const Paneldriver({super.key});

  @override
  State<Paneldriver> createState() => _PaneldriverState();
}

class _PaneldriverState extends State<Paneldriver> {
  final _controller = StreamController<QuerySnapshot>.broadcast();
  FirebaseFirestore db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _requestsListener;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  bool _emactivity = true;

  @override
  void initState() {
    super.initState();
    _checkActivityStatus();
    _recuperarRequisicaoAtivadriver();
  }

  @override
  void dispose() {
    _requestsListener?.cancel();
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }

  Stream<QuerySnapshot> _listenerrequests() {
    final stream = db
        .collection('requests')
        .where('status', isEqualTo: StatusRequisicao.waiting)
        .snapshots();

    _requestsListener = stream.listen((dados) {
      if (mounted) {
        _controller.add(dados);
      }
    });

    return stream;
  }

  void _recuperarRequisicaoAtivadriver() async {
    User? firebaseUser = await FirebaseUser.getCurrentUser();

    DocumentSnapshot documentSnapshot = await db
        .collection('active-request-driver')
        .doc(firebaseUser?.uid)
        .get();

    var dadosRequisicao = documentSnapshot.data() as Map<String, dynamic>?;

    if (dadosRequisicao == null) {
      _listenerrequests();
    } else {
      String RequestD = dadosRequisicao['request_id'];
      Navigator.pushReplacementNamed(
        context,
        '/corrida',
        arguments: RequestD,
      );
    }
  }

  Future<void> _checkActivityStatus() async {
    if (!mounted) return;
    Usuario? usuario = await FirebaseUser.getLoggedUserData();

    if (mounted && usuario != null) {
      _subscription =
          db.collection('usuarios').doc(usuario.id).snapshots().listen((doc) {
        if (mounted) {
          setState(() {
            _emactivity = doc.data()?['activity_status'] ?? false;
          });
        }
      });
    }
  }
  Future<String?> getCityName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        // The 'locality' property typically holds the city name.
        return placemarks.first.locality;
      }
    } catch (e) {
      print("Error retrieving city name: $e");
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    var mensagemErro = const Center(
      child: Text(
        'Erro ao carregar os dados!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    var mensagemCarregando = const Center(
      child: CircularProgressIndicator(),
    );

    var mensagemNaoTemDados = const Center(
      child: Text(
        'You have no requests!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    var mensagemForaDeactivity = const Center(
      child: Text(
        'You are offline! To see your calls, activate the activity status',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (!_emactivity) {
      return Scaffold(
        body: mensagemForaDeactivity,
      );
    }
    Future<Map<String, String>> getBothCityNames({
      required double currentLat,
      required double currentLng,
      required double dropLat,
      required double dropLng,
    }) async {
      final currentCity = await getCityName(currentLat, currentLng);
      final dropCity = await getCityName(dropLat, dropLng);
      return {
        'current': currentCity ?? 'Unavailable',
        'dropOff': dropCity ?? 'Unavailable',
      };
    }
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return mensagemCarregando;
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return mensagemErro;
              } else {
                QuerySnapshot? querySnapshot = snapshot.data;
                if (querySnapshot!.docs.isEmpty) {
                  return mensagemNaoTemDados;
                } else {
                  return ListView.separated(
                    itemCount: querySnapshot.docs.length,
                    itemBuilder: (context, index) {
                      List<DocumentSnapshot> requests =
                          querySnapshot.docs.toList();
                      DocumentSnapshot item = requests[index];

                      String RequestD = item['id'];
                      String namepassenger = item['passenger']['name'];
                      String destinationroad = item['destination']['road'];
                      String destinationnumber = item['destination']['number'];

                      double latitudedestination = item['destination']['latitude'];
                      double longitudedestination = item['destination']['longitude'];
                      double latitudeorigin = item['passenger']['latitude'];
                      double longitudeorigin = item['passenger']['longitude'];
                      String  vehicleType = item['vehicleType'];
                      double distanciaEmMetros = Geolocator.distanceBetween(
                        latitudeorigin,
                        longitudeorigin,
                        latitudedestination,
                        longitudedestination,
                      );

                      double distanciaKM = distanciaEmMetros / 1000;
                      String distanciaFormatada =
                          distanciaKM.toStringAsFixed(1);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Card(
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: AppColors.secundaryColor,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.secundaryColor,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                '${distanciaFormatada}KM',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textColor,
                                ),
                              ),
                            ),
                            title: Text(
                              namepassenger,
                              style: TextStyle(color: AppColors.textColor),
                            ),
                            subtitle: FutureBuilder<Map<String, String>>(
                              future: getBothCityNames(
                                currentLat: latitudeorigin,
                                currentLng: longitudeorigin,
                                dropLat: latitudedestination,
                                dropLng: longitudedestination,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Text(
                                    "Loading location...",
                                    style: TextStyle(color: AppColors.secundarytextColor),
                                  );
                                } else if (snapshot.hasError) {
                                  return Text(
                                    "Location error",
                                    style: TextStyle(color: AppColors.secundarytextColor),
                                  );
                                } else {
                                  final locationNames = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current: ${locationNames['current']}',
                                        style: TextStyle(color: AppColors.secundarytextColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Drop Off: ${locationNames['dropOff']}',
                                        style: TextStyle(color: AppColors.secundarytextColor),
                                      ),
                                      Text(
                                        'Vehicle type:  $vehicleType',
                                        style: TextStyle(color: AppColors.secundarytextColor),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/corrida',
                                arguments: RequestD,
                              );
                            },
                          ),

                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(
                        height: 2,
                        color: Colors.grey,
                      );
                    },
                  );
                }
              }
            default:
              return Container();
          }
        },
      ),
    );
  }
}
