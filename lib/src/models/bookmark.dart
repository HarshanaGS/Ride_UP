import 'package:google_maps_flutter/google_maps_flutter.dart';

class Bookmark {
  LatLng local;
  BitmapDescriptor pathImage;
  String title;

  Bookmark({
    required this.local,
    required this.pathImage,
    required this.title,
  });
}
