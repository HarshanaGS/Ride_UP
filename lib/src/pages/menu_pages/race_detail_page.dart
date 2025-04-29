// ignore_for_file: unused_field
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/components/custom_show_dialog.dart';
import 'package:SharedJourney/src/components/custom_snackbar.dart';
import 'package:SharedJourney/src/components/custom_text_area.dart';
import 'package:SharedJourney/src/utils/colors.dart';

class RaceDetailPage extends StatefulWidget {
  final String? idCorrida;
  final String? userType;
  final String? userId;
  const RaceDetailPage(this.idCorrida, this.userType, this.userId,
      {super.key});

  @override
  State<RaceDetailPage> createState() => _RaceDetailPageState();
}

class _RaceDetailPageState extends State<RaceDetailPage> {
  Map<String, dynamic>? _dataRace;
  Map<String, dynamic>? _complaintdata;
  bool _isLoading = true;
  late final Completer<GoogleMapController> _controller;
  final TextEditingController _complaintController = TextEditingController();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? origin;
  LatLng? destination;
  String _buttontext = 'Make a Complaint';
  String _buttontextassessment = 'Avaliar';
  String _titleassessment = "Don't forget to rate the";
  bool _reclamacaoFeita = false;
  bool _assessmentFeita = false;
  double _assessmentnote = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = Completer<GoogleMapController>();
    _titleassessment =
        'Dont forget to rate the ${widget.userType == 'passenger' ? 'driver' : 'passenger'}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarDados();
    _checkComplaint();
    _verificarassessment();
  }

  Future<void> _carregarDados() async {
    final String? idCorrida = widget.idCorrida;
    if (idCorrida == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(idCorrida)
          .get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final dados = doc.data() as Map<String, dynamic>;

      if (!dados.containsKey('origin') ||
          !dados.containsKey('destination') ||
          !dados.containsKey('driver')) {
        setState(() => _isLoading = false);
        return;
      }

      origin =
          LatLng(dados['origin']['latitude'], dados['origin']['longitude']);
      destination =
          LatLng(dados['destination']['latitude'], dados['destination']['longitude']);

      String driverId = dados['driver']['user_id'];
      String dataFimAtual = dados['data_fim'];

      // Buscar a contagem de viagens do driver
      int viagensAnteriores =
          await _contarViagensAnteriores(driverId, dataFimAtual);

      setState(() {
        _dataRace = {
          ...dados,
          'driver': {
            ...dados['driver'],
            'trips-made': viagensAnteriores,
          }
        };
      });

      await _exibirDoismarkeres(origin!, destination!);
      _movimentarCameraBounds();
    } catch (e) {
      print('Error fetching data: $e');
      CustomSnackbar.show(context, 'Error loading race data.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _contarViagensAnteriores(
      String driverId, String dataFimAtual) async {
    try {
      DateTime dataFimConvertida = DateTime.parse(dataFimAtual);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('driver.user_id', isEqualTo: driverId)
          .get();

      int count = querySnapshot.docs.where((doc) {
        if (doc['data_fim'] != null) {
          DateTime dataCorrida = DateTime.parse(doc['data_fim']);
          return dataCorrida.isBefore(dataFimConvertida);
        }
        return false;
      }).length;

      return count;
    } catch (e) {
      print('Error counting trips: $e');
      return 0;
    }
  }

  Future<void> _exibirDoismarkeres(LatLng latlng1, LatLng latlng2) async {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('start-marker'),
          position: latlng1,
          infoWindow: const InfoWindow(title: 'Start location'),
          icon: BitmapDescriptor.defaultMarker,
        ),
        Marker(
          markerId: const MarkerId('end-marker'),
          position: latlng2,
          infoWindow: const InfoWindow(title: 'Local Final'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  void _movimentarCameraBounds() async {
    if (origin == null || destination == null) return;

    final GoogleMapController? mapController = await _controller.future;
    if (mapController == null) return;

    try {
      LatLngBounds bounds = LatLngBounds(
        northeast: LatLng(max(origin!.latitude, destination!.latitude),
            max(origin!.longitude, destination!.longitude)),
        southwest: LatLng(min(origin!.latitude, destination!.latitude),
            min(origin!.longitude, destination!.longitude)),
      );
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } catch (e) {
      print('Error moving camera: $e');
    }
  }

  Widget _buildMapa() {
    if (origin == null || destination == null) {
      return const Center(child: Text('Location not available'));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: origin!, zoom: 20),
      markers: _markers,
      onMapCreated: (controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
        }
        setState(() => _mapController = controller);
      },
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildDetalhes(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  String _formatarPeriodoCorrida(String? dataInicio, String? dataFim) {
    if (dataInicio == null || dataFim == null) return 'N/A';

    DateTime inicio = DateTime.parse(dataInicio);
    DateTime fim = DateTime.parse(dataFim);

    String dataFormatada = DateFormat('dd/MM/yyyy').format(inicio);
    String horaInicio = DateFormat('HH:mm').format(inicio);
    String horaFim = DateFormat('HH:mm').format(fim);

    return '$dataFormatada • $horaInicio - $horaFim';
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'N/A';

    var formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'RS');
    return formatador.format(valor);
  }

  String _formatardestination(Map<String, dynamic>? destination) {
    if (destination == null) return 'N/A';

    return '${destination['road'] ?? 'N/A'}, ${destination['number'] ?? 'N/A'} - '
        '${destination['neighborhood'] ?? 'N/A'} - ${destination['cep'] ?? 'N/A'}';
  }

  String _capitalizarPrimeiraLetra(String? texto) {
    if (texto == null || texto.isEmpty) return 'N/A';
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Widget _fazerReclamacao() {
    return CustomTextArea(
      controller: _complaintController,
      hintText: 'Tell us what happened...',
      hintStyle: TextStyle(color: AppColors.textColor, fontSize: 12),
      isLoading: _isLoading,
      textColor: AppColors.textColor,
      cursorColor: AppColors.textColor,
      maxLength: 500,
    );
  }

  void _exibirFazerReclamacao() {
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
                  'Make a Complaint',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _fazerReclamacao(),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Submit Complaint',
                funtion: () {
                  _enviarReclamacao();
                },
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enviarReclamacao() async {
    if (_complaintController.text.isEmpty) {
      CustomSnackbar.show(
          context, 'Please write your complaint before submitting.');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      String descricaoKey = widget.userType == 'passenger'
          ? 'passenger_description'
          : 'driver_description';
      String dataKey = widget.userType == 'passenger'
          ? 'passenger_complaint_data'
          : 'data_complaint_driver';

      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.idCorrida)
          .set({
        descricaoKey: _complaintController.text,
        dataKey: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      CustomSnackbar.show(context, 'Complaint sent successfully!',
          backgroundColor: Colors.green);

      Navigator.pop(context);
      _complaintController.clear();

      await _checkComplaint();
    } catch (e) {
      CustomSnackbar.show(context, 'Error sending complaint: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkComplaint() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.idCorrida)
          .get();

      if (snapshot.exists) {
        String descricaoKey = widget.userType == 'passenger'
            ? 'passenger_description'
            : 'driver_description';

        if (snapshot.data()![descricaoKey] != null) {
          if (mounted) {
            setState(() {
              _buttontext = 'View Complaint';
              _reclamacaoFeita = true;
              _complaintdata = {
                ...snapshot.data()!,
                'docId': snapshot.id,
              };
            });
          }
        }
      }
    } catch (e) {
      print("Error searching for complaint: $e");
    }
  }

  void _onButtonPressed() {
    if (_reclamacaoFeita) {
      _showComplaint();
    } else {
      _exibirFazerReclamacao();
    }
  }

  void _showComplaint() async {
    String descricaoKey = widget.userType == 'passenger'
        ? 'passenger_description'
        : 'driver_description';

    String Complainttext = _complaintdata![descricaoKey] ?? '';

    if (Complainttext.isEmpty) {
      CustomSnackbar.show(context, 'No complaints found.');
      return;
    }

    int CalculatedLines = (Complainttext.length / 30).ceil().clamp(1, 15);
    int minLines = CalculatedLines;
    int maxLines = CalculatedLines >= minLines ? CalculatedLines : minLines;

    customShowDialog(
      context: context,
      title: 'Complaint',
      content: CustomTextArea(
        controller: _complaintController,
        readOnly: true,
        hintText: Complainttext,
        hintStyle: TextStyle(color: AppColors.textColor, fontSize: 12),
        maxLines: maxLines,
        minLines: minLines,
      ),
      cancelText: 'Sair',
      onCancel: () => Navigator.pop(context),
      confirmText: 'Delete Complaint',
      confirmTextColor: Colors.red,
      onConfirm: _deleteComplaint,
    );
  }

  void _deleteComplaint() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    customShowDialog(
      context: context,
      title: 'Delete Complaint',
      content: const Text(
        'Are you sure you want to delete the complaint? You will not be able to revert it later.',
      ),
      cancelText: 'Cancel',
      onCancel: () => Navigator.pop(context),
      confirmTextColor: Colors.red,
      confirmText: 'Delete',
      onConfirm: () async {
        try {
          String descricaoKey = widget.userType == 'passenger'
              ? 'passenger_description'
              : 'driver_description';
          String dataKey = widget.userType == 'passenger'
              ? 'passenger_complaint_data'
              : 'data_complaint_driver';

          DocumentReference docRef =
              db.collection('complaints').doc(widget.idCorrida);
          DocumentSnapshot docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            return;
          }

          Map<String, dynamic>? data =
              docSnapshot.data() as Map<String, dynamic>?;
          if (data == null) {
            return;
          }

          await docRef.update({
            descricaoKey: FieldValue.delete(),
            dataKey: FieldValue.delete(),
          });


          bool isAnotherComplaint = data.containsKey(
              widget.userType == 'passenger'
                  ? 'driver_description'
                  : 'passenger_description');


          if (!isAnotherComplaint) {
            await docRef.delete();
          }

          setState(() {
            _buttontext = 'Make a Complaint';
            _reclamacaoFeita = false;
          });

          Navigator.pop(context);
          Navigator.pop(context);

          CustomSnackbar.show(
            context,
            'Complaint successfully deleted!',
            backgroundColor: Colors.green,
          );
        } catch (e) {
          CustomSnackbar.show(
            context,
            'Error deleting complaint: $e',
          );
        }
      },
    );
  }

  void _assessment() {
    if (_assessmentFeita) {
      _mostrarassessment(
        _assessmentnote,
        widget.userType == 'passenger' ? 'driver' : 'passenger',
      );
    } else {
      _displayDoassessment();
    }
  }

  Future<void> _verificarassessment() async {
    try {
      String? userType = widget.userType;
      String campoassessment = userType == 'passenger'
          ? 'assessment-driver'
          : 'assessment-passenger';

      var requestRef = FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.idCorrida);

      var snapshotRequest = await requestRef.get();

      if (!snapshotRequest.exists) {
        throw Exception("Request not found");
      }

      var requestDate = snapshotRequest.data();

      if (!(requestDate!.containsKey(userType) &&
          requestDate[userType] is Map &&
          requestDate[userType]['user_id'] == widget.userId)) {
        throw Exception("User is not part of this race");
      }

      if (requestDate.containsKey(campoassessment)) {
        double nota = (requestDate[campoassessment] as num).toDouble();

        if (mounted) {
          setState(() {
            _buttontextassessment = 'View Review';
            _assessmentFeita = true;
            _assessmentnote = nota;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _buttontextassessment = 'Avaliar';
            _assessmentFeita = false;
          });
        }
      }
    } catch (e) {
      CustomSnackbar.show(context, 'Error fetching review: $e');
    }
  }

  void _mostrarassessment(double assessmentnote, String typeEvaluated) {
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
                  'Your review left for the $typeEvaluated',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _displayassessment(assessmentnote),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _displayassessment(double nota) {
    return RatingBarIndicator(
      rating: nota,
      itemCount: 5,
      itemSize: 40.0,
      direction: Axis.horizontal,
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
    );
  }

  void _displayDoassessment() {
    String typeEvaluated =
        widget.userType == 'passenger' ? 'driver' : 'passenger';

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
                  'Avaliar $typeEvaluated',
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
              CustomButton(
                text: 'Submit Review',
                funtion: () {
                  _enviarassessment();
                },
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
        'Por favor, selecione uma nota antes de enviar.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String userIdReviewed = widget.userType == 'passenger'
          ? _dataRace!['driver']['user_id']
          : _dataRace!['passenger']['user_id'];

      await _atualizarMediaassessment(userIdReviewed);

      if (mounted) {
        setState(() {
          _assessmentFeita = true;
          _buttontextassessment = 'View Review';
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

      double assessmentAtual = usuarioSnapshot.exists &&
              usuarioSnapshot.data()!.containsKey('assessment')
          ? (usuarioSnapshot.data()!['assessment'] as num).toDouble()
          : 0;
      int quantidadeAvaliacoes = usuarioSnapshot.exists &&
              usuarioSnapshot.data()!.containsKey('quantity_reviews')
          ? usuarioSnapshot.data()!['quantity_reviews'] as int
          : 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dataRace == null
              ? const Center(child: Text('Trip not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 250, child: _buildMapa()),
                            const SizedBox(height: 10),
                            Text(_formatarPeriodoCorrida(
                                _dataRace!['start_date'],
                                _dataRace!['data_fim'])),
                            Text(
                                '${_formatarValor(_dataRace!['race_value'])} • ${_capitalizarPrimeiraLetra(_dataRace!['status'])}'),
                          ],
                        ),
                      ),
                      _buildDetalhes('Trip Data', [
                        Text(
                            'destination: ${_formatardestination(_dataRace!['destination'])}'),
                      ]),
                      _buildDetalhes('Passenger data', [
                        Text(
                            'name: ${_dataRace!['passenger']['name'] ?? 'N/A'}'),
                        Text(
                            'Email: ${_dataRace!['passenger']['email'] ?? 'N/A'}'),
                      ]),
                      _buildDetalhes('Driver data', [
                        Text(
                            'name: ${_dataRace!['driver']['name'] ?? 'N/A'}'),
                        Text(
                            'Email: ${_dataRace!['driver']['email'] ?? 'N/A'}'),
                        Text(
                          _dataRace!['driver']['trips-made'] == 0
                              ? 'This was the first trip of ${_dataRace!['driver']['name']}'
                              : 'Trips Completed: ${_dataRace!['driver']['trips-made']}',
                        ),
                      ]),
                      _buildDetalhes('Did something happen?', [
                        Center(
                          child: CustomButton(
                            text: _buttontext,
                            funtion: _onButtonPressed,
                            isLoading: _isLoading,
                            enabled: !_isLoading,
                            backgroundColor: AppColors.secundaryColor,
                          ),
                        ),
                      ]),
                      _buildDetalhes(_titleassessment, [
                        Center(
                          child: CustomButton(
                            text: _buttontextassessment,
                            funtion: _assessment,
                            isLoading: _isLoading,
                            enabled: !_isLoading,
                            backgroundColor: AppColors.secundaryColor,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
    );
  }
}
