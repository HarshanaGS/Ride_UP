import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleMapWebView extends StatefulWidget {
  final String googleMapsUrl;
  const GoogleMapWebView({Key? key, required this.googleMapsUrl})
      : super(key: key);

  @override
  State<GoogleMapWebView> createState() => _GoogleMapWebViewState();
}

class _GoogleMapWebViewState extends State<GoogleMapWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the WebViewController with the desired settings.
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.googleMapsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
