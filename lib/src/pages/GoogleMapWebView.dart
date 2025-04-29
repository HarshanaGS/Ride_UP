import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapWebView extends StatefulWidget {
  final String googleMapsUrl;

  const GoogleMapWebView({Key? key, required this.googleMapsUrl})
      : super(key: key);

  @override
  State<GoogleMapWebView> createState() => _GoogleMapWebViewState();
}

class _GoogleMapWebViewState extends State<GoogleMapWebView> {
  @override
  void initState() {
    super.initState();
    _launchExternalGoogleMap();
  }

  Uri _getDesktopViewUri(String originalUrl) {
    if (originalUrl.contains("www.google.com/maps")) {
      return Uri.parse(originalUrl);
    }

    final uri = Uri.parse(originalUrl);
    final query = uri.queryParameters;
    final destination = query['q'] ?? 'Colombo';
    final desktopUrl = 'https://www.google.com/maps/search/?api=1&query=$destination';

    return Uri.parse(desktopUrl);
  }

  Future<void> _launchExternalGoogleMap() async {
    Uri mapUrl = _getDesktopViewUri(widget.googleMapsUrl);

    if (await canLaunchUrl(mapUrl)) {
      await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch map URL.');
    }

    // Optionally pop the page since we’re not displaying anything
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // fallback loading
      ),
    );
  }
}
