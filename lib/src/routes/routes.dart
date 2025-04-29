// ignore_for_file: avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:SharedJourney/src/pages/auth/registration_page.dart';
import 'package:SharedJourney/src/pages/auth/reset_password_page.dart';
import 'package:SharedJourney/src/pages/settings/help_page.dart';
import 'package:SharedJourney/src/pages/settings/wallet_page.dart';
import 'package:SharedJourney/src/pages/settings/page_settings.dart';
import 'package:SharedJourney/src/pages/settings/management/change_page_information.dart';
import 'package:SharedJourney/src/pages/settings/management/page_management.dart';
import 'package:SharedJourney/src/pages/race_page.dart';
import 'package:SharedJourney/src/pages/menu_pages/activity_page.dart';
import 'package:SharedJourney/src/pages/menu_pages/account_page.dart';
import 'package:SharedJourney/src/pages/menu_pages/race_detail_page.dart';
import 'package:SharedJourney/src/pages/menu_pages/home_page.dart';
import 'package:SharedJourney/src/pages/menu_pages/initial_page.dart';
import 'package:SharedJourney/src/pages/auth/login_page.dart';
import 'package:SharedJourney/src/pages/driver_panel.dart';
import 'package:SharedJourney/src/pages/passenger_panel.dart';
import 'package:SharedJourney/src/pages/splash_screen_page.dart';

import '../pages/SharedTripListPage.dart';
import '../pages/settings/DropLocationScreen.dart';

class Routes {
  static Route<dynamic> generateRoutes(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreenPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegistrationPage());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());
      case '/initial':
        return MaterialPageRoute(builder: (_) => const InitialPage());
      case '/home':
        return MaterialPageRoute(
          builder: (_) =>
              HomePage(args as String? ?? '', updateIndex: (int) {}),
        );
      case '/activity':
        return MaterialPageRoute(
          builder: (_) => ActivityPage(args as String? ?? ''),
        );
      case '/conta':
        return MaterialPageRoute(
          builder: (_) =>
              AccountPage(args as String? ?? '', updateIndex: (int) {}),
        );
      case '/driver-panel':
        return MaterialPageRoute(builder: (_) => const Paneldriver());
      case '/passenger-panel':
        return MaterialPageRoute(builder: (_) => const Panelpassenger());
      case '/corrida':
        return MaterialPageRoute(
          builder: (_) => CorridaPage(args as String? ?? ''),
        );
      case '/race-details':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => RaceDetailPage(
              args['idCorrida'] ?? '',
              args['userType'] ?? '',
              args['userId'] ?? '',
            ),
          );
        } else {
          return _routeError();
        }
      case '/settings':
        return MaterialPageRoute(builder: (_) => const ConfiguracoesPage());
      case '/management':
        return MaterialPageRoute(builder: (_) => const GerenciamentoPage());
      case '/Portfolio':
        return MaterialPageRoute(builder: (_) => const PortfolioPage());
      case '/Help':
        return MaterialPageRoute(builder: (_) => const HelpPage());


      case '/shared-trip':
        return MaterialPageRoute(builder: (_) => const SharedTripListPage());
      case '/set-drop-location':
        return MaterialPageRoute(builder: (_) => const DropLocationScreen());
      case '/change-info':
        return MaterialPageRoute(
          builder: (_) => AlterarInformacaoPage(args as String? ?? ''),
        );
      default:
        return _routeError();
    }
  }

  static Route<dynamic> _routeError() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Screen not found'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Screen not found! '),
        ),
      ),
    );
  }
}
