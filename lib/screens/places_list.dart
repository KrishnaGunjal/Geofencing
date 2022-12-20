import 'dart:async';
import 'package:easy_geofencing/enums/geofence_status.dart';
import 'package:flutter/material.dart';

import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin, pow, sin, pi;
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

import '../modals/landmark.dart';

class PlacesList extends StatefulWidget {
  const PlacesList({super.key});

  @override
  State<PlacesList> createState() => _PlacesListState();
}

class _PlacesListState extends State<PlacesList> {
  Location location = new Location();
  String geofenceStatus = '';
  bool isReady = false;
  StreamSubscription<GeofenceStatus>? geofenceStatusStream;
  bool _ispopupShown = false;

  static const _nearbyLandmarks = [
    Landmark(title: 'Wakad', latitude: 18.598944, longitude: 73.765274),
    Landmark(
        title: 'Nitor Infotech', latitude: 18.593550, longitude: 73.702220),
    Landmark(title: 'Xion Mall', latitude: 40.623009, longitude: -89.579132),
    Landmark(title: 'Kasarsai Dam', latitude: 22.615170, longitude: 88.411510)
  ];

  _getNearbyLandmark() {
    location.onLocationChanged.listen((LocationData currentLocation) {
      final userLatitude = currentLocation.latitude;
      final userLongitude = currentLocation.longitude;

      _nearbyLandmarks.forEach((element) {
        final lon1 = userLongitude! * pi / 180;
        final lon2 = element.longitude * pi / 180;
        final lat1 = userLatitude! * pi / 180;
        final lat2 = element.latitude * pi / 180;

        // Haversine formula
        final dlon = lon2 - lon1;
        final dlat = lat2 - lat1;
        final a = pow(sin(dlat / 2), 2) +
            cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);

        final c = 2 * asin(sqrt(a));
        const r = 6371;
        // calculate the result
        final distance = (c * r);
        print('Distance is: $distance');

        if (distance < 7) {
          if (!_ispopupShown) {
            setState(() {
              _showAlertDialog(element.title);
            });
          }
        }
      });
    });
  }

  _showAlertDialog(placeTitle) {
    _ispopupShown = true;
    Widget okButton = TextButton(
      child: const Text("Okay"),
      onPressed: () {
        Navigator.pop(context);
        _ispopupShown = false;
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text('You are near $placeTitle'),
      actions: [
        okButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: const Text('Geofencing Alert!'),
                content: Text(('You are near $placeTitle')),
                actions: <CupertinoDialogAction>[
                  CupertinoDialogAction(
                    child: const Text('Okay'),
                    onPressed: () {
                      Navigator.pop(context);
                      _ispopupShown = false;
                    },
                  )
                ],
              )
            : alert;
      },
    );
  }

  @override
  void initState() {
    location.enableBackgroundMode(enable: true);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // _getPosition();
    _getNearbyLandmark();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? Material(
            child: CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Geofencing'),
              ),
              child: ListView.builder(
                  itemCount: _nearbyLandmarks.length,
                  itemBuilder: (context, index) => ListTile(
                        title: Text(_nearbyLandmarks[index].title),
                      )),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Geofencing'),
            ),
            body: ListView.builder(
                itemCount: _nearbyLandmarks.length,
                itemBuilder: (context, index) => ListTile(
                      title: Text(_nearbyLandmarks[index].title),
                    )),
          );
  }
}
