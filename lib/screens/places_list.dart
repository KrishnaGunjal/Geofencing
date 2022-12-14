import 'dart:async';
import 'package:easy_geofencing/easy_geofencing.dart';
import 'package:easy_geofencing/enums/geofence_status.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:background_fetch/background_fetch.dart';

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

    await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      //fetch-event callback.
      _getNearbyLandmark();
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      // Task timeout handler.
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
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
        if (distance < 7) {
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
