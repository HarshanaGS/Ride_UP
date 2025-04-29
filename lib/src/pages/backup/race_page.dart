import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/status_request.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

import 'GoogleMapWebView.dart';

class CorridaPage extends StatefulWidget {
  final String? RequestD;
  const CorridaPage(this.RequestD, {super.key});

  @override
  State<CorridaPage> createState() => _CorridaPageState();
}

class _CorridaPageState extends State<CorridaPage> {
  bool _isLoading = false;
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  Future<void> _getRequestData(String requestId) async {
    try {
      // 1. Reference the `requests` collection
      DocumentReference docRef =
      FirebaseFirestore.instance.collection('requests').doc(requestId);

      // 2. Get the document snapshot
      DocumentSnapshot snapshot = await docRef.get();

      if (snapshot.exists) {
        // 3. Access the data
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          // Access driver location
          if (data['driver'] != null) {
            driverLat = data['driver']['latitude'];
            driverLng = data['driver']['longitude'];
          }

          // Access destination location
          if (data['destination'] != null) {
            destinationLat = data['destination']['latitude'];
            destinationLng = data['destination']['longitude'];
          }

          // Update the UI if needed
          setState(() {});

          // Ensure both locations are available before proceeding
          if (driverLat != null &&
              driverLng != null &&
              destinationLat != null &&
              destinationLng != null) {
            // Create the Google Maps URL dynamically using the retrieved coordinates:
            String googleMapsUrl =
                "https://www.google.com/maps/dir/$driverLat,$driverLng/$destinationLat,$destinationLng/";

            // Navigate to the new WebView screen to show the route:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoogleMapWebView(googleMapsUrl: googleMapsUrl),
              ),
            );
          } else {
            debugPrint("Driver or destination coordinates are missing.");
          }
        }
      } else {
        debugPrint("Request with ID $requestId doesn't exist.");
      }
    } catch (e) {
      debugPrint("Error getting request data: $e");
    }
  }


  double? driverLat;
  double? driverLng;
  double? destinationLat;
  double? destinationLng;
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(-22.24773416549846, -49.92616103366711),
  );

  late StreamSubscription<Position> _positionStream;
  Set<Marker> _markers = {};
  Map<String, dynamic>? data_request;
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
  _requisicaoStream;
  LatLng? _ultimaPosicaoCamera;
  String _mensagemStatus = '';
  String _RequestD = '';
  Position? _localdriver;
  String _statusRequisicao = StatusRequisicao.waiting;
  double _assessmentnote = 0.0;

  @override
  void initState() {
    super.initState();
    _RequestD = widget.RequestD!;
    _adicionarListenerRequisicao();
    _locationListener();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _requisicaoStream.cancel();
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
              if (_statusRequisicao != StatusRequisicao.waiting) {
                FirebaseUser.atualizarDadosLocalizacao(
                  _RequestD,
                  position.latitude,
                  position.longitude,
                  'driver',
                );
              } else {
                setState(() {
                  _localdriver = position;
                });
                _statusUberwaiting();
              }
            }
          },
          onError: (error) {
            CustomSnackbar.show(
                context, 'locationScreeningError: $error');
          },
        );
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

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  String _buttontext = 'Accept';
  Color _corBotao = Colors.black;
  VoidCallback _functionBotao = () {};

  void _alterarBotaoPrincipal(String text, Color color, VoidCallback function) {
    setState(() {
      _buttontext = text;
      _corBotao = color;
      _functionBotao = function;
    });
  }

  void _adicionarListenerRequisicao() {
    FirebaseFirestore db = FirebaseFirestore.instance;

    _requisicaoStream = db
        .collection('requests')
        .doc(_RequestD)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        data_request = snapshot.data();

        Map<String, dynamic>? dados = snapshot.data();
        _statusRequisicao = dados?['status'];

        switch (_statusRequisicao) {
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
        }
      }
    }, onError: (error) {
      CustomSnackbar.show(context, 'errorInTheRequisitionListener: $error');
    });
  }

  void _statusUberwaiting() {

    _alterarBotaoPrincipal(
      'Approve',
      Colors.black,
          () {
        _aceitarCorrida();
      },
    );

    if (_localdriver != null) {
      double driverLat = _localdriver!.latitude;
      double driverLon = _localdriver!.longitude;

      Position position = Position(
        longitude: driverLon,
        latitude: driverLat,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      LatLng novaPosicao = LatLng(position.latitude, position.longitude);

      if (_ultimaPosicaoCamera == null || _ultimaPosicaoCamera != novaPosicao) {
        setState(() {
          _exibirmarker(
            position,
            'assets/images/driver.png',
            'driver',
          );
          CameraPosition cameraPosition = CameraPosition(
            target: novaPosicao,
            zoom: 16,
          );
          _movimentarCamera(cameraPosition);
        });
      }
    }
  }

  void _statusUberACaminho() async {
    _exibirLoading();

    while (data_request == null) {
      await Future.delayed(const Duration(seconds: 1));
    }

    _esconderLoading();

    setState(() {
      _mensagemStatus = '- On the way to the passenger';
    });
    String RequestD = data_request?['id'];
    FirebaseFirestore db = FirebaseFirestore.instance;
    print("get request");
    _getRequestData(RequestD);
    _alterarBotaoPrincipal(
      'Start',
      Colors.black,
          () {
        _iniciarCorrida();
      },
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

    setState(() {
      _mensagemStatus = '- Trip started';
    });

    _alterarBotaoPrincipal(
      'Finish',
      Colors.black,
          () {
        _finalizarCorrida();
      },
    );

    double latitudedestination = data_request!['destination']['latitude'];
    double longitudedestination = data_request!['destination']['longitude'];
    double latitudeorigin = data_request!['driver']['latitude'];
    double longitudeorigin = data_request!['driver']['longitude'];

    await _exibirDoismarkeres(
      LatLng(latitudeorigin, longitudeorigin),
      LatLng(latitudedestination, longitudedestination),
    );

    // 👉 Add second passenger marker if present
    if (data_request!.containsKey('second_passenger')) {
      var p2 = data_request!['second_passenger'];
      double lat = p2['latitude'];
      double lng = p2['longitude'];

      Marker secondPassengerMarker = Marker(
        markerId: const MarkerId('second-passenger'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Second Passenger'),
        onTap: () {
          double driverLat = data_request!['driver']['latitude'];
          double driverLng = data_request!['driver']['longitude'];

          String googleMapsUrl =
              "https://www.google.com/maps/dir/?api=1&origin=$driverLat,$driverLng&destination=$lat,$lng&travelmode=driving";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoogleMapWebView(googleMapsUrl: googleMapsUrl),
            ),
          );
        },
      );

      setState(() {
        _markers.add(secondPassengerMarker);
      });
    }

    double nLat = [latitudeorigin, latitudedestination].reduce((a, b) => a > b ? a : b);
    double sLat = [latitudeorigin, latitudedestination].reduce((a, b) => a < b ? a : b);
    double nLon = [longitudeorigin, longitudedestination].reduce((a, b) => a > b ? a : b);
    double sLon = [longitudeorigin, longitudedestination].reduce((a, b) => a < b ? a : b);

    _movimentarCameraBounds(
      LatLngBounds(
        northeast: LatLng(nLat, nLon),
        southwest: LatLng(sLat, sLon),
      ),
    );
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

  void _aceitarCorrida() async {
    setState(() {
      _isLoading = true;
    });

    try {






      Usuario? driver = await FirebaseUser.getLoggedUserData();
      driver?.latitude = _localdriver!.latitude;
      driver?.longitude = _localdriver!.longitude;

      String RequestD = data_request?['id'];
      FirebaseFirestore db = FirebaseFirestore.instance;


      await db.collection('requests').doc(RequestD).update({
        'driver': driver?.toMap(),
        'status': StatusRequisicao.THE_WAY,
        'start_date': DateTime.now().toIso8601String(),
      });

      String idpassenger = data_request?['passenger']['user_id'];
      String? iddriver = driver?.id;

      await db.collection('active-request').doc(idpassenger).update({
        'status': StatusRequisicao.THE_WAY,
      });

      await db.collection('active-request-driver').doc(iddriver).set({
        'request_id': RequestD,
        'id_driver': iddriver,
        'status': StatusRequisicao.THE_WAY,
      });
    } catch (e) {
      CustomSnackbar.show(context, 'Error accepting race: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _iniciarCorrida() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    await db.collection('requests').doc(_RequestD).update({
      'origin': {
        'latitude': data_request?['driver']['latitude'],
        'longitude': data_request?['driver']['longitude'],
      },
      'status': StatusRequisicao.trip,
    });

    String idpassenger = data_request?['passenger']['user_id'];
    await db.collection('active-request').doc(idpassenger).update({
      'status': StatusRequisicao.trip,
    });

    String iddriver = data_request?['driver']['user_id'];
    await db.collection('active-request-driver').doc(iddriver).update({
      'status': StatusRequisicao.trip,
    });
  }

  void _finalizarCorrida() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection('requests').doc(_RequestD).update({
      'status': StatusRequisicao.finished,
    });

    String idpassenger = data_request?['passenger']['user_id'];
    await db.collection('active-request').doc(idpassenger).update({
      'status': StatusRequisicao.finished,
    });

    String iddriver = data_request?['driver']['user_id'];
    await db.collection('active-request-driver').doc(iddriver).update({
      'status': StatusRequisicao.finished,
    });
  }

  void _confirmRacefinished() async {


    FirebaseFirestore db = FirebaseFirestore.instance;




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
    double valortrip = distanciaKM * 100;

    await db.collection('requests').doc(_RequestD).update({
      'status': StatusRequisicao.confirmed,
      'race_value': valortrip,
      'data_fim': DateTime.now().toIso8601String(),
    });

    String idpassenger = data_request?['passenger']['user_id'];
    await db.collection('active-request').doc(idpassenger).delete();

    String iddriver = data_request?['driver']['user_id'];
    await db.collection('active-request-driver').doc(iddriver).delete();

    DocumentReference driverRef = db.collection('usuarios').doc(iddriver);




    try {
      await db.runTransaction((transaction) async {
        DocumentSnapshot driverDoc = await transaction.get(driverRef);

        if (!driverDoc.exists) {
          throw Exception("driver not found!");
        }

        var data = driverDoc.data() as Map<String, dynamic>;
        double balanceWithdraw =
            (data['balance_withdraw'] as num?)?.toDouble() ?? 0.00;
        double totalBalance = (data['total_balance'] as num?)?.toDouble() ?? 0.00;

        transaction.update(driverRef, {
          'balance_withdraw': balanceWithdraw + valortrip,
          'total_balance': totalBalance + valortrip,
        });
      });

      print("Balance updated successfully.");
    } catch (e) {
      print("Error updating balance: $e");
    }
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

    double distanciaKM = distanciaEmMetros / 1000; // Convert meters to kilometers
    double valortrip = distanciaKM * 100; // Rs. 100 per km

// Format the fare to 2 decimal places with LKR locale
    var f = NumberFormat("#,##0.00", "pt_BR");
    var valortripFormatado = f.format(valortrip);

    setState(() {
      _mensagemStatus = '- Trip finished';
    });

    _alterarBotaoPrincipal(
      'Confirm - LKR $valortripFormatado',
      Colors.black,
          () {
        _confirmRacefinished();
      },
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
        'Please select a note before submitting..',
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

      if (!requestDate.containsKey('passenger') ||
          requestDate['passenger'] == null ||
          !requestDate['passenger'].containsKey('user_id')) {
        throw Exception("Incomplete or poorly formatted request data");
      }

      String userIdReviewed = requestDate['passenger']['user_id'];
      String campoassessment = 'assessment-passenger';

      await requestRef.update({
        campoassessment: _assessmentnote,
      });

      await _atualizarMediaassessment(userIdReviewed);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.pushNamedAndRemoveUntil(context, '/initial', (_) => false);

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
      print("Error updating average rating: $e");
    }
  }
// Hardcoded polyline for testing
  Set<Polyline> testPolylines = {
    Polyline(
      polylineId: PolylineId("testRoute"),
      points: [
        LatLng(6.958774406684664, 79.91912629455328), // Point A

      ],
      width: 6,
      color: Colors.blue,
    ),
  };

  void _statusFinalizacaoconfirmed() {
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
                  'Ride finished. Do you want to rate the passenger?',
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
                      text: 'Close',
                      funtion: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/initial', (_) => false);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip $_mensagemStatus'),
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
            trafficEnabled: true, // Show traffic overlay
            mapType: MapType.normal,
            initialCameraPosition: _defaultPosition,
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: testPolylines, // if you have routes
            compassEnabled: true,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // if you want to use your own location button
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            mapToolbarEnabled: true,
            buildingsEnabled: true,
            onTap: (LatLng position) {
              // Do something when the map is tapped
              print("Map tapped at: $position");
            },
            onCameraMove: (CameraPosition position) {
              // Update state or perform actions during camera movement
              print("Camera moving: $position");
            },
            onCameraIdle: () {
              // When camera stops moving
              print("Camera idle");
            },
            // Optionally apply custom styling:
            // mapStyle: _mapStyle,  // Define a JSON string for custom style
          ),
          Positioned(
            top: 20,
            right: 15,
            child: ElevatedButton.icon(
              icon: Icon(Icons.location_on),
              label: Text("2nd Passenger"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                var p2 = data_request!['second_passenger'];
                var driver = data_request!['driver'];

                // 1. Add marker for 2nd passenger
                Marker secondPassengerMarker = Marker(
                  markerId: const MarkerId('second-passenger'),
                  position: LatLng(p2['latitude'], p2['longitude']),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  infoWindow: const InfoWindow(title: '2nd Passenger'),
                );

                setState(() {
                  _markers.add(secondPassengerMarker);
                });

                // 2. Move camera to the 2nd passenger
                _movimentarCamera(
                  CameraPosition(
                    target: LatLng(p2['latitude'], p2['longitude']),
                    zoom: 16,
                  ),
                );

                // 3. Open map view
                String googleMapsUrl =
                    "https://www.google.com/maps/dir/${driver['latitude']},${driver['longitude']}/${p2['latitude']},${p2['longitude']}/";

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoogleMapWebView(googleMapsUrl: googleMapsUrl),
                  ),
                );
              },
            ),
          )
          ,
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
