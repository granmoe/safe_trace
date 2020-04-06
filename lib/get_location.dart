import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:safe_trace/location_stream.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GetLocation extends StatefulWidget {
  GetLocation({Key key}) : super(key: key);

  @override
  _GetLocationState createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocation> {
  Location location;
  Database db;
  StoreRef store;
  bool isDbInitialized = false;

  @override
  void initState() {
    initDb();
    super.initState();
  }

  void initDb() async {
    location = new Location();
    location.changeSettings(accuracy: LocationAccuracy.high);

    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true); // ensure dir exists
    var dbPath = join(dir.path, 'safe_trace.db');
    db = await databaseFactoryIo.openDatabase(dbPath);

    store = StoreRef.main();

    // Add if it doesn't exist
    await store.record('locationHistory').add(db, {});

    // var update = {};
    // update['2020-03-08'] = {
    //   'locations': [],
    // };
    // await store.record('locationHistory').update(db, update);

    setState(() {
      isDbInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isDbInitialized) {
      return Text('Loading...');
    }

    return StreamBuilder(
        stream: LocationStream.locationStream(
            db: db, store: store, location: location),
        builder: (_context, snapshot) {
          if (!snapshot.hasData) {
            return Text('No location yet');
          }

          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }

          LocationData location = snapshot.data;

          return Column(children: <Widget>[
            Text('latitude: ${location.latitude.toStringAsFixed(6)}'),
            Text('longitude: ${location.longitude.toStringAsFixed(6)}'),
            Text('altitude: ${location.altitude.toStringAsFixed(6)}'),
            Text('accuracy (meters): ${location.accuracy.toStringAsFixed(6)}')
          ]);
        });
  }
}

class LocationHistoryDay {}
