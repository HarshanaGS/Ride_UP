import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:SharedJourney/src/components/custom_button.dart';
import 'package:SharedJourney/src/models/user.dart';
import 'package:SharedJourney/src/utils/colors.dart';
import 'package:SharedJourney/src/utils/status_request.dart';
import 'package:SharedJourney/src/utils/firebase_user.dart';

class ActivityPage extends StatefulWidget {
  final String? userType;
  const ActivityPage(this.userType, {super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  String userType = '';

  @override
  void initState() {
    userType = widget.userType!;
    super.initState();
  }

  Map<String, String?> _filtrosSelecionados = {
    'Profile': null,
    'Options': null,
  };

  void _showFilters() {
    _filtrosSelecionados["Profile"] ??= "Guys";
    _filtrosSelecionados["Options"] ??= "All";
    Map<String, String?> filtrosTemp = Map.from(_filtrosSelecionados);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secundaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 25,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'filterBy...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _filtros((categoria, valor) {
                      setModalState(() => filtrosTemp[categoria] = valor);
                    }, filtrosTemp),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: _botaoAplicar(filtrosTemp),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Divider(thickness: 1, color: AppColors.textColor),
      );

  Widget _botaoAplicar(Map<String, String?> filtrosTemp) => CustomButton(
        text: 'apply',
        funtion: () {
          setState(() => _filtrosSelecionados = Map.from(filtrosTemp));
          Navigator.pop(context);
        },
        isLoading: false,
        enabled: true,
      );

  Widget _filtros(Function(String, String?) onSelectFiltro,
      Map<String, String?> filtrosTemp) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoria(
              onSelectFiltro,
              "profile",
              {
                "personal": Icons.person,
                "establishment": Icons.store,
                "family": Icons.family_restroom,
              },
              filtrosTemp),
          const SizedBox(height: 10),
          _buildCategoria(
              onSelectFiltro,
              "option",
              {
                "all": null,
                "finalize": null,
                "canceled": null,
              },
              filtrosTemp),
        ],
      ),
    );
  }

  Widget _buildCategoria(
    Function(String, String?) onSelectFiltro,
    String title,
    Map<String, IconData?> opcoes,
    Map<String, String?> filtrosTemp,
  ) {
    filtrosTemp.putIfAbsent(title, () => opcoes.keys.first);

    Map<String, String> descricoes = {
      "Profile": "Choose a profile to filter the results.",
      "Options": "Select the desired status.",
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: descricoes[title] ?? "",
              child:
                  Icon(Icons.info_outline_rounded, color: AppColors.textColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: opcoes.length,
            itemBuilder: (context, index) {
              String key = opcoes.keys.elementAt(index);
              return _itemFiltro(
                categoria: title,
                title: key,
                icon: opcoes[key],
                selecionado: filtrosTemp[title] == key,
                onTap: () => onSelectFiltro(title, key),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _itemFiltro({
    required String categoria,
    required String title,
    IconData? icon,
    required bool selecionado,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Container(
          decoration: BoxDecoration(
            color: selecionado
                ? AppColors.primaryColor
                : AppColors.secundarytextColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    color: selecionado ? Colors.white : AppColors.textColor),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  color: selecionado ? Colors.white : AppColors.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _filtrosAplicados() {
    switch (_filtrosSelecionados['Options']) {
      case 'finished':
        return [StatusRequisicao.confirmed];
      case 'cancelled':
        return [StatusRequisicao.cancelled];
      case 'All':
      default:
        return [StatusRequisicao.confirmed, StatusRequisicao.cancelled];
    }
  }

  Widget _corridas() {
    return FutureBuilder<Usuario?>(
      future: FirebaseUser.getLoggedUserData(),
      builder: (context, usuarioSnapshot) {
        if (usuarioSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!usuarioSnapshot.hasData || usuarioSnapshot.data == null) {
          return const Center(child: Text("You haven't run any races yet"));
        }

        String? userId = usuarioSnapshot.data!.id;
        List<String> filtros = _filtrosAplicados();

        return _searchRaces(userId, filtros);
      },
    );
  }

  Widget _searchRaces(String? userId, List<String> filtros) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('requests')
          .where('$userType.user_id', isEqualTo: userId)
          .where('status',
              whereIn: filtros.isNotEmpty
                  ? filtros
                  : [
                      StatusRequisicao.confirmed,
                      StatusRequisicao.cancelled,
                    ])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("You haven't run any races yet"));
        }

        List<QueryDocumentSnapshot> corridas =
            _sortRaces(snapshot.data!.docs);
        return _buildRaceList(context, corridas, userId);
      },
    );
  }

  List<QueryDocumentSnapshot> _sortRaces(
      List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      try {
        DateTime dataA =
            DateTime.parse((a.data() as Map<String, dynamic>)['start_date']);
        DateTime dataB =
            DateTime.parse((b.data() as Map<String, dynamic>)['start_date']);
        return dataB.compareTo(dataA);
      } catch (e) {
        print("errorConverterData: $e");
        return 0;
      }
    });
    return docs;
  }

  Widget _buildRaceList(BuildContext context,
      List<QueryDocumentSnapshot> corridas, String? userId) {
    return Column(
      children: corridas.map((doc) {
        var dados = doc.data() as Map<String, dynamic>;
        return _buildRaceItem(context, dados, userId);
      }).toList(),
    );
  }

  Widget _buildRaceItem(
      BuildContext context, Map<String, dynamic> dados, String? userId) {
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
          side: BorderSide(color: AppColors.secundaryColor, width: 2),
        ),
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIcon(),
              _buildInformationRace(dados),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.secundarytextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.secundaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.access_time_sharp,
        color: AppColors.secundarytextColor,
      ),
    );
  }

  Widget _buildInformationRace(Map<String, dynamic> dados) {
    return Column(
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
          child: dados['status'] == StatusRequisicao.cancelled
              ? Text(
                  'canceled',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.secundarytextColor,
                    fontSize: 11,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatarPeriodoCorrida(
                          dados['start_date'], dados['data_fim']),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          color: AppColors.secundarytextColor, fontSize: 11),
                    ),
                    Text(
                      _formatarValor(dados['race_value']),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          color: AppColors.secundarytextColor, fontSize: 11),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  String _formatarPeriodoCorrida(String? dataInicio, String? dataFim) {
    if (dataInicio == null || dataFim == null) return 'N/A';

    DateTime inicio = DateTime.parse(dataInicio);

    String dataFormatada = DateFormat('dd/MM/yyyy').format(inicio);
    String horaInicio = DateFormat('HH:mm').format(inicio);

    return '$dataFormatada • $horaInicio';
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'N/A';

    var formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'previous',
                  style: TextStyle(fontSize: 16),
                ),
                GestureDetector(
                  onTap: _showFilters,
                  child: Container(
                    decoration: BoxDecoration(
                        color: AppColors.secundaryColor,
                        borderRadius: BorderRadius.circular(50)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.filter_alt_outlined,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            _corridas()
          ],
        ),
      ),
    );
  }
}
