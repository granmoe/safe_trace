import 'dart:math';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
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
    location = new Location();
    location.changeSettings(accuracy: LocationAccuracy.high);
    initDb();
    super.initState();
  }

  void initDb() async {
    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true); // ensure dir exists
    var dbPath = join(dir.path, 'safe_trace.db');
    db = await databaseFactoryIo.openDatabase(dbPath);

    store = StoreRef.main(); // TODO: Could also use multiple stores

    // Add if it doesn't exist
    await store.record('locationHistory').add(db, {});
    // var update = {};
    // update['2020-03-08'] = {
    //   'locations': [],
    // };
    // await store.record('locationHistory').update(db, update);

    isDbInitialized = true;
  }

  Stream<LocationData> locationStream() async* {
    while (true) {
      if (isDbInitialized == false) {
        yield null;
      }

      await Future.delayed(const Duration(milliseconds: 5000));

      var currentLocation = await location.getLocation();

      var record = store.record('locationHistory');
      var locationHistorySnapshot = await record.get(db);
      print(locationHistorySnapshot);

      var now = DateTime.now();
      String currentDate = now.toIso8601String().substring(0, 10);
      var oldestDate =
          now.subtract(Duration(days: 28)).toIso8601String().substring(0, 10);

      await db.transaction((txn) async {
        var locationHistory = await record.get(txn);
        var today = locationHistory[currentDate];

        if (today == null) {
          var update = {};
          update[currentDate] = {
            'locations': [
              {
                'latitude': currentLocation.latitude,
                'longitude': currentLocation.longitude,
                'altitude': currentLocation.altitude,
                'time': currentLocation.time,
                'accuracy': currentLocation.accuracy
              }
            ],
            'minLongitude': currentLocation.longitude,
            'maxLongitude': currentLocation.longitude,
            'minLatitude': currentLocation.latitude,
            'maxLatitude': currentLocation.latitude,
            'minAltitude': currentLocation.altitude,
            'maxAltitude': currentLocation.altitude,
          };

          await record.update(txn, update);

          if (locationHistory[oldestDate] != null) {
            var update = {};
            update[oldestDate] = FieldValue.delete;
            await record.update(txn, update);
          }

          // TODO: Recalc overall min/max
          // min(days.map(.minLongitude))
        } else {
          var update = {};
          update[currentDate] = {
            'locations': [
              ...today['locations'],
              {
                'latitude': currentLocation.latitude,
                'longitude': currentLocation.longitude,
                'altitude': currentLocation.altitude,
                'time': currentLocation.time,
                'accuracy': currentLocation.accuracy
              }
            ],
            'minLongitude':
                min(currentLocation.longitude, today['minLongitude'] as double),
            'maxLongitude':
                max(currentLocation.longitude, today['maxLongitude'] as double),
            'minLatitude':
                min(currentLocation.latitude, today['minLatitude'] as double),
            'maxLatitude':
                max(currentLocation.latitude, today['maxLatitude'] as double),
            'minAltitude':
                min(currentLocation.altitude, today['minAltitude'] as double),
            'maxAltitude':
                max(currentLocation.altitude, today['maxAltitude'] as double),
          };

          await record.update(txn, update);
          // TODO: Update overall min/max
        }
      }); // await db.transaction

      locationHistorySnapshot = await record.get(db);
      print(locationHistorySnapshot);
      yield currentLocation;
    } // while (true)
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: locationStream(),
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
