import 'dart:async';
import 'package:easy_geofencing/easy_geofencing.dart';
import 'package:easy_geofencing/enums/geofence_status.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

import '../modals/landmark.dart';

class PlacesList extends StatefulWidget {
  const PlacesList({super.key});

  @override
  State<PlacesList> createState() => _PlacesListState();
}

class _PlacesListState extends State<PlacesList> {
  Geolocator geolocator = Geolocator();
  String geofenceStatus = '';
  bool isReady = false;
  Position? position;
  StreamSubscription<GeofenceStatus>? geofenceStatusStream;
  bool _ispopupShown = false;

  static const _nearbyLandmarks = [
    Landmark(title: 'Wakad', latitude: 18.598944, longitude: 73.765274),
    Landmark(
        title: 'Nitor Infotech', latitude: 18.593550, longitude: 73.702220),
    Landmark(title: 'Xion Mall', latitude: 40.623009, longitude: -89.579132),
    Landmark(title: 'Kasarsai Dam', latitude: 22.615170, longitude: 88.411510)
  ];

  _getPosition() async {
    var permission = await Geolocator.checkPermission();
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showAlertDialog('Location services are disabled');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showAlertDialog(
            'Please enable permission for access location to get alerts');
      }
    }
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _getNearbyLandmark();
  }

  _getNearbyLandmark() {
    final userLatitude = position!.latitude;
    final userLongitude = position!.longitude;

    EasyGeofencing.startGeofenceService(
        pointedLatitude: userLatitude.toString(),
        pointedLongitude: userLongitude.toString(),
        radiusMeter: '1000',
        eventPeriodInSeconds: 10);
    geofenceStatusStream ??=
        EasyGeofencing.getGeofenceStream()!.listen((GeofenceStatus status) {
      _nearbyLandmarks.forEach((element) {
        var p = 0.017453292519943295;
        var c = cos;
        var a = 0.5 -
            c((element.latitude - userLatitude) * p) / 2 +
            c(userLatitude * p) *
                c(element.latitude * p) *
                (1 - c((element.longitude - userLongitude) * p)) /
                2;
        var distance = 12742 * asin(sqrt(a));
        if (distance < 4) {
          setState(() {
            if (!_ispopupShown) {
              _showAlertDialog(element.title);
            }
          });
        }
      });
    });
  }

  _showAlertDialog(placeTitle) {
    _ispopupShown = true;
    Widget okButton = TextButton(
      child: const Text("OK"),
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
        return alert;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // _getPosition();
  }

  @override
  void didChangeDependencies() {
    _getPosition();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
