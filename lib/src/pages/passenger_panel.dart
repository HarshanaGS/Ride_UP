import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:SharedJourney/src/components/custom_show_dialog.dart';
import 'package:SharedJourney/src/models/destiny.dart';
import 'package:SharedJourney/src/models/request.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/components/custom_input_text.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/status_request.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class Panelpassenger extends StatefulWidget {
  const Panelpassenger({super.key});

  @override
  State<Panelpassenger> createState() => _PanelpassengerState();
}

class _PanelpassengerState extends State<Panelpassenger> {
  final TextEditingController _meuLocalController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isLoading = false;
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(-22.24107528364154, -49.927157894975515),
    zoom: 16,
  );

  late StreamSubscription<Position> _positionStream;
  Position? _localpassenger;
  Map<String, dynamic>? data_request;
  Set<Marker> _markers = {};
  String _RequestD = '';
  StreamSubscription<DocumentSnapshot>? _streamSubscriptionrequests;
  double _assessmentnote = 0.0;

  @override
  void initState() {
    super.initState();
    _recuperarRequisicaoAtiva();
    _locationListener();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _destinationController.dispose();
    _meuLocalController.dispose();
    _streamSubscriptionrequests?.cancel();
    _streamSubscriptionrequests = null;
    super.dispose();
  }

  void _locationListener() {
    var locationOptions = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationOptions).listen(
              (Position position) async {
            if (_RequestD.isNotEmpty) {
              FirebaseUser.atualizarDadosLocalizacao(
                _RequestD,
                position.latitude,
                position.longitude,
                'passenger',
              );
            } else {
              setState(() {
                _localpassenger = position;
              });
              _statusUberNaoChamado();
            }
          },
          onError: (error) {
            CustomSnackbar.show(
                context, 'Erro no rastreamento de localização: $error');
          },
        );
  }

  void _exibirmarkerpassenger(Position local) async {
    Marker markerpassenger = Marker(
      markerId: const MarkerId('marker-passenger'),
      position: LatLng(local.latitude, local.longitude),
      infoWindow: const InfoWindow(title: 'Meu Local'),
      icon: BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _markers.clear();
      _markers.add(markerpassenger);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  void _chamarUber() async {
    String enderecodestination = _destinationController.text;

    if (enderecodestination.isNotEmpty) {
      try {
        print(enderecodestination);

        setState(() {
          _isLoading = true;
        });

        List<Location> listaEnderecos =
        await locationFromAddress(enderecodestination);

        if (listaEnderecos.isNotEmpty) {
          Location endereco = listaEnderecos[0];

          List<Placemark> placemarks = await placemarkFromCoordinates(
            endereco.latitude,
            endereco.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks[0];

            Destiny destination = Destiny(
              road: placemark.street ?? '',
              number: placemark.subThoroughfare ?? '',
              city: placemark.subAdministrativeArea ?? '',
              neighborhood: placemark.subLocality ?? '',
              cep: placemark.postalCode ?? '',
              latitude: endereco.latitude,
              longitude: endereco.longitude,
            );

            // Declare a mutable variable for the selected vehicle type.
            String selectedVehicle = 'Car';

            customShowDialog(
              context: context,
              title: 'Confirm Address & Price',
              content: StatefulBuilder(
                builder: (context, setState) {
                  double distanceInMeters = _localpassenger != null
                      ? Geolocator.distanceBetween(
                    _localpassenger!.latitude,
                    _localpassenger!.longitude,
                    endereco.latitude,
                    endereco.longitude,
                  )
                      : 0.0;
                  double distanceKM = distanceInMeters / 1000;

                  double carPrice;
                  if (distanceKM <= 5) {
                    carPrice = distanceKM * 40;
                  } else {
                    carPrice = (5 * 40) + ((distanceKM - 5) * 30);
                  }

                  double suvPrice;
                  if (distanceKM <= 5) {
                    suvPrice = distanceKM * 50;
                  } else {
                    suvPrice = (5 * 50) + ((distanceKM - 5) * 35);
                  }

                  double estimatedPrice = selectedVehicle == 'Car' ? carPrice : suvPrice;
print(estimatedPrice);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'City: ${destination.city ?? 'Not available'}',
                      ),
                      Text(
                        'Road: ${destination.road ?? 'Not available'}, ${destination.number ?? 'S/N'}',
                      ),
                      Text(
                        'Address: ${destination.neighborhood ?? 'Not available'}',
                      ),
                      Text(
                        'CEP: ${destination.cep ?? 'Not available'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Distance: ${distanceKM.toStringAsFixed(2)} km',
                      ),
                      Text(
                        'Estimated Price: LKR ${estimatedPrice.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Radio<String>(
                            value: 'Car',
                            groupValue: selectedVehicle,
                            onChanged: (value) {
                              setState(() {
                                selectedVehicle = value!;
                              });
                            },
                          ),
                          const Text('Car'),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'SUV',
                            groupValue: selectedVehicle,
                            onChanged: (value) {
                              setState(() {
                                selectedVehicle = value!;
                              });
                            },
                          ),
                          const Text('SUV'),
                        ],
                      )
                    ],
                  );
                },
              ),
              cancelText: 'Cancel',
              cancelTextColor: Colors.red,
              onCancel: () => Navigator.pop(context),
              confirmText: 'Confirm',
              confirmTextColor: Colors.green,
              onConfirm: () {
                // Recalculate distance and estimated price before confirming.
                double distanceInMeters = _localpassenger != null
                    ? Geolocator.distanceBetween(
                  _localpassenger!.latitude,
                  _localpassenger!.longitude,
                  endereco.latitude,
                  endereco.longitude,
                )
                    : 0.0;
                double distanceKM = distanceInMeters / 1000;

// Calculate Car Price
                double carPrice;
                if (distanceKM <= 5) {
                  carPrice = distanceKM * 1;
                } else {
                  carPrice = (5 * 1) + ((distanceKM - 5) * 1);
                }

// Calculate SUV Price
                double suvPrice;
                if (distanceKM <= 5) {
                  suvPrice = distanceKM * 1;
                } else {
                  suvPrice = (5 * 1) + ((distanceKM - 5) * 1);
                }

// Final price based on selected vehicle
                double finalPrice = selectedVehicle == 'Car' ? carPrice : suvPrice;

                Navigator.pop(context);
                _salvarRequisicao(destination, selectedVehicle, finalPrice);
              },
            );

            setState(() {});
          } else {
            CustomSnackbar.show(
                context, 'Unable to retrieve address details.');
          }
        }
      } catch (e, stackTrace) {
        print('Error searching for destination: $e\n$stackTrace');
        CustomSnackbar.show(context, 'Error searching for destination: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      CustomSnackbar.show(context, 'Please enter a valid address.');
    }
  }

  Future<void> _salvarRequisicao(
      Destiny destination, String vehicleType, double estimatedPrice) async {
    Usuario? passenger = await FirebaseUser.getLoggedUserData();
    passenger?.latitude = _localpassenger!.latitude;
    passenger?.longitude = _localpassenger!.longitude;

    Requisicao requisicao = Requisicao(
      status: StatusRequisicao.waiting,
      passenger: passenger!,
      destination: destination,
    );

    // Convert the request to a map and add the extra fields.
    Map<String, dynamic> requisicaoMap = requisicao.toMap();
    requisicaoMap['vehicleType'] = vehicleType;
    requisicaoMap['estimatedPrice'] = estimatedPrice;

    FirebaseFirestore db = FirebaseFirestore.instance;

    await db.collection('requests').doc(requisicao.id).set(requisicaoMap);

    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva['request_id'] = requisicao.id;
    dadosRequisicaoAtiva['user_id'] = passenger.id;
    dadosRequisicaoAtiva['status'] = StatusRequisicao.waiting;

    await db
        .collection('active-request')
        .doc(passenger.id)
        .set(dadosRequisicaoAtiva);

    if (_streamSubscriptionrequests == null) {
      _adicionarListenerRequisicao(requisicao.id!);
    }
  }

  bool _exibirCaixaEnderecodestination = true;
  String _buttontext = 'Find a rider';
  Color _corBotao = Colors.black;
  VoidCallback _functionBotao = () {};

  void _alterarBotaoPrincipal(String text, Color color, VoidCallback function) {
    setState(() {
      _buttontext = text;
      _corBotao = color;
      _functionBotao = function;
    });
  }

  void _statusUberNaoChamado() async {
    setState(() {
      _exibirCaixaEnderecodestination = true;
    });

    _alterarBotaoPrincipal(
      'Find a rider',
      Colors.black,
          () {
        _chamarUber();
      },
    );

    if (_localpassenger != null) {
      Position position = Position(
        longitude: _localpassenger!.longitude,
        latitude: _localpassenger!.latitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      _exibirmarkerpassenger(position);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 25,
      );

      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    }
  }

  void _statusUberwaiting() async {
    setState(() {
      _exibirCaixaEnderecodestination = false;
    });

    _alterarBotaoPrincipal(
      'Cancel',
      Colors.red[400]!,
          () {
        _cancelarUber();
      },
    );

    double passengerLat = data_request!['passenger']['latitude'];
    double passengerLon = data_request!['passenger']['longitude'];

    Position position = Position(
      longitude: passengerLon,
      latitude: passengerLat,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    _exibirmarkerpassenger(position);
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 16,
    );

    _movimentarCamera(cameraPosition);
  }

  void _statusUberACaminho() async {
    setState(() {
      _exibirCaixaEnderecodestination = false;
    });

    _alterarBotaoPrincipal(
      'Driver is on TheWay',
      Colors.grey,
          () {},
    );

    double latitudepassenger = data_request!['passenger']['latitude'];
    double longitudepassenger = data_request!['passenger']['longitude'];
    double latitudedriver = data_request!['driver']['latitude'];
    double longitudedriver = data_request!['driver']['longitude'];

    await _exibirDoismarkeres(
      LatLng(latitudedriver, longitudedriver),
      LatLng(latitudepassenger, longitudepassenger),
    );

    double nLat =
    [latitudedriver, latitudepassenger].reduce((a, b) => a > b ? a : b);
    double sLat =
    [latitudedriver, latitudepassenger].reduce((a, b) => a < b ? a : b);
    double nLon = [longitudedriver, longitudepassenger]
        .reduce((a, b) => a > b ? a : b);
    double sLon = [longitudedriver, longitudepassenger]
        .reduce((a, b) => a < b ? a : b);

    _movimentarCameraBounds(LatLngBounds(
      northeast: LatLng(nLat, nLon),
      southwest: LatLng(sLat, sLon),
    ));
  }

  void _statusUberEmtrip() async {
    _exibirLoading();

    while (data_request == null) {
      await Future.delayed(const Duration(seconds: 1));
    }

    _esconderLoading();

    _alterarBotaoPrincipal(
      'Trip started',
      Colors.grey,
          () {},
    );

    double latitudedestination = data_request!['destination']['latitude'];
    double longitudedestination = data_request!['destination']['longitude'];
    double latitudeorigin = data_request!['driver']['latitude'];
    double longitudeorigin = data_request!['driver']['longitude'];

    await _exibirDoismarkeres(
      LatLng(latitudeorigin, longitudeorigin),
      LatLng(latitudedestination, longitudedestination),
    );

    double nLat =
    [latitudeorigin, latitudedestination].reduce((a, b) => a > b ? a : b);
    double sLat =
    [latitudeorigin, latitudedestination].reduce((a, b) => a < b ? a : b);
    double nLon =
    [longitudeorigin, longitudedestination].reduce((a, b) => a > b ? a : b);
    double sLon =
    [longitudeorigin, longitudedestination].reduce((a, b) => a < b ? a : b);

    _movimentarCameraBounds(LatLngBounds(
      northeast: LatLng(nLat, nLon),
      southwest: LatLng(sLat, sLon),
    ));
  }

  void _statusUberfinished() async {
    double latitudedestination = data_request!['destination']['latitude'];
    double longitudedestination = data_request!['destination']['longitude'];
    double latitudeorigin = data_request!['origin']['latitude'];
    double longitudeorigin = data_request!['origin']['longitude'];

    double distanciaEmMetros = Geolocator.distanceBetween(
      latitudeorigin,
      longitudeorigin,
      latitudedestination,
      longitudedestination,
    );

    double distanciaKM = distanciaEmMetros / 1000;
    double valortrip = distanciaKM * 100; // Example: Rs. 100 per KM

    var f = NumberFormat("#,##0.00", "en_US");

    var valortripFormatado = f.format(valortrip);

    _alterarBotaoPrincipal(
      'Trip Completed',
      Colors.green,
          () {},
    );

    Position position = Position(
      longitude: longitudedestination,
      latitude: latitudedestination,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    setState(() {
      _markers.clear();
    });

    _exibirmarker(
      position,
      'assets/images/destination.png',
      'destination',
    );
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 19,
    );
    _movimentarCamera(cameraPosition);
  }

  Widget _fazerassessment() {
    return RatingBar.builder(
      initialRating: 0,
      minRating: 0,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {
        setState(() {
          _assessmentnote = rating;
        });
      },
    );
  }

  Future<void> _enviarassessment() async {
    if (_assessmentnote == 0) {
      CustomSnackbar.show(
        context,
        'Please select a note before submitting.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var requestRef = FirebaseFirestore.instance
          .collection('requests')
          .doc(_RequestD);
      var snapshotRequest = await requestRef.get();

      if (!snapshotRequest.exists) {
        throw Exception("Request not found");
      }

      var requestDate = snapshotRequest.data()!;

      if (!requestDate.containsKey('driver') ||
          requestDate['driver'] == null ||
          !requestDate['driver'].containsKey('user_id')) {
        throw Exception("Incomplete or poorly formatted request data");
      }

      String userIdReviewed = requestDate['driver']['user_id'];
      String campoassessment = 'assessment-driver';

      await requestRef.update({
        campoassessment: _assessmentnote,
      });

      await _atualizarMediaassessment(userIdReviewed);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.pop(context);

        CustomSnackbar.show(context, 'Assessment completed successfully!',
            backgroundColor: Colors.green);
      }
    } catch (e) {
      print("Error sending review: $e");
      CustomSnackbar.show(context, 'Error sending review: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _atualizarMediaassessment(String userIdReviewed) async {
    try {
      var usuarioRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userIdReviewed);
      var usuarioSnapshot = await usuarioRef.get();

      double assessmentAtual = 0;
      int quantidadeAvaliacoes = 0;

      if (usuarioSnapshot.exists &&
          usuarioSnapshot.data()!.containsKey('assessment')) {
        assessmentAtual =
            (usuarioSnapshot.data()!['assessment'] as num).toDouble();
      }
      if (usuarioSnapshot.exists &&
          usuarioSnapshot.data()!.containsKey('quantity_reviews')) {
        quantidadeAvaliacoes =
        usuarioSnapshot.data()!['quantity_reviews'] as int;
      }

      double novaMedia =
          ((assessmentAtual * quantidadeAvaliacoes) + _assessmentnote) /
              (quantidadeAvaliacoes + 1);
      await usuarioRef.update({
        'assessment': novaMedia,
        'quantity_reviews': quantidadeAvaliacoes + 1,
      });
    } catch (e) {
      CustomSnackbar.show(context, 'Error updating average rating: $e');
      print("Error updating average rating:: $e");
    }
  }

  void _statusFinalizacaoconfirmed() {
    if (_streamSubscriptionrequests != null) {
      setState(() {
        _streamSubscriptionrequests!.cancel();
        _streamSubscriptionrequests = null;
        _exibirCaixaEnderecodestination = true;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.secundaryColor,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Race finished. Do you want to rate the driver?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _fazerassessment(),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: 'Cancel',
                        funtion: () {
                          Navigator.pop(context);
                        },
                        isLoading: false,
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: 'Submit Review',
                        funtion: () {
                          _enviarassessment();
                        },
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );

      _alterarBotaoPrincipal(
        'Find a rider',
        Colors.black,
            () {
          _chamarUber();
        },
      );

      double passengerLat = data_request!['passenger']['latitude'];
      double passengerLon = data_request!['passenger']['longitude'];

      Position position = Position(
        longitude: passengerLon,
        latitude: passengerLat,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      _exibirmarkerpassenger(position);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16,
      );

      _movimentarCamera(cameraPosition);

      data_request!.clear();
      data_request = null;
    }
  }

  void _movimentarCamera(CameraPosition cameraPosition) async {
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  void _exibirmarker(Position local, String icone, String infoWindow) async {
    Marker marker = Marker(
      markerId: MarkerId(icone),
      position: LatLng(local.latitude, local.longitude),
      infoWindow: InfoWindow(title: infoWindow),
      icon: BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _exibirLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _esconderLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _movimentarCameraBounds(LatLngBounds latlngBounds) async {
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(CameraUpdate.newLatLngBounds(
      latlngBounds,
      100,
    ));
  }

  void _cancelarUber() async {
    setState(() {
      _isLoading = true;
    });

    User? firebaseUser = await FirebaseUser.getCurrentUser();
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection('requests').doc(_RequestD).update({
      'status': StatusRequisicao.cancelled,
    }).then((_) {
      db.collection('active-request').doc(firebaseUser?.uid).delete();
    });

    _statusUberNaoChamado();
    if (_streamSubscriptionrequests != null) {
      setState(() {
        _streamSubscriptionrequests!.cancel();
        _streamSubscriptionrequests = null;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _recuperarRequisicaoAtiva() async {
    User? firebaseUser = await FirebaseUser.getCurrentUser();
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot documentSnapshot =
    await db.collection('active-request').doc(firebaseUser!.uid).get();

    if (documentSnapshot.data() != null) {
      Map<String, dynamic>? dados =
      documentSnapshot.data() as Map<String, dynamic>?;
      _RequestD = await dados!['request_id'];
      _adicionarListenerRequisicao(_RequestD);
    } else {
      _statusUberNaoChamado();
    }
  }

  void _adicionarListenerRequisicao(String RequestD) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    _streamSubscriptionrequests = db
        .collection('requests')
        .doc(RequestD)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        Map<String, dynamic>? dados = snapshot.data();
        data_request = dados;
        String status = dados!['status'];
        _RequestD = dados['id'];

        switch (status) {
          case StatusRequisicao.waiting:
            _statusUberwaiting();
            break;
          case StatusRequisicao.THE_WAY:
            _statusUberACaminho();
            break;
          case StatusRequisicao.trip:
            _statusUberEmtrip();
            break;
          case StatusRequisicao.finished:
            _statusUberfinished();
            break;
          case StatusRequisicao.confirmed:
            _statusFinalizacaoconfirmed();
            break;
          default:
            _statusUberNaoChamado();
        }
      }
    });
  }

  Future<void> _exibirDoismarkeres(LatLng latlng1, LatLng latlng2) async {
    Set<Marker> listamarkeres = {};

    Marker marker1 = Marker(
      markerId: const MarkerId('marker-driver'),
      position: LatLng(latlng1.latitude, latlng1.longitude),
      infoWindow: const InfoWindow(title: 'Local driver'),
      icon: BitmapDescriptor.defaultMarker,
    );

    listamarkeres.add(marker1);

    Marker marker2 = Marker(
      markerId: const MarkerId('marker-passenger'),
      position: LatLng(latlng2.latitude, latlng2.longitude),
      infoWindow: const InfoWindow(title: 'Local passenger'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    listamarkeres.add(marker2);

    setState(() {
      _markers.clear();
      _markers = listamarkeres;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/initial',
                    (_) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _defaultPosition,
            onMapCreated: _onMapCreated,
            //myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
          ),
          Visibility(
            visible: _exibirCaixaEnderecodestination,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          decoration:
                          const BoxDecoration(color: Colors.white),
                          child: CustomInputText(
                            controller: _meuLocalController,
                            hintText: 'My Location - Automatic',
                            keyboardType: TextInputType.text,
                            preffixIcon: const Icon(Icons.location_on),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          decoration:
                          const BoxDecoration(color: Colors.white),
                          child: CustomInputText(
                            controller: _destinationController,
                            hintText: 'Enter destination',
                            cursorColor: AppColors.primaryColor,
                            textColor: AppColors.primaryColor,
                            keyboardType: TextInputType.text,
                            preffixIcon: const Icon(Icons.car_crash),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomButton(
                funtion: _functionBotao,
                text: _buttontext,
                backgroundColor: _corBotao,
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
