import 'package:flutter/material.dart';
import 'package:location/location.dart';

class GetLocation extends StatefulWidget {
  GetLocation({Key key}) : super(key: key);

  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<GetLocation> {
  final Location location = new Location();

  Stream<LocationData> locationStream() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield await location.getLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: locationStream(),
        builder: (_context, snapshot) {
          LocationData location = snapshot.data;

          return Text(
              'latitude ${location.latitude}, longitude ${location.longitude}');
        });
  }
}
