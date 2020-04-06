import 'dart:math';
import 'package:location/location.dart';
import 'package:sembast/sembast.dart';

class LocationStream {
  static Stream<LocationData> locationStream(
      {Database db, Location location, StoreRef store}) async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 5000));

      LocationData currentLocation = await location.getLocation();

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
}
