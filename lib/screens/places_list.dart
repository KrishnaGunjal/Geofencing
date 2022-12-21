import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

import '../modals/landmark.dart';

class PlacesList extends StatefulWidget {
  const PlacesList({super.key});

  @override
  State<PlacesList> createState() => _PlacesListState();
}

class _PlacesListState extends State<PlacesList> {
  bool _ispopupShown = false;
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  static const _nearbyLandmarks = [
    Landmark(title: 'Wakad', latitude: 18.598944, longitude: 73.765274),
    Landmark(
        title: 'Nitor Infotech', latitude: 18.593550, longitude: 73.702220),
    Landmark(title: 'Xion Mall', latitude: 40.623009, longitude: -89.579132),
    Landmark(title: 'Kasarsai Dam', latitude: 22.615170, longitude: 88.411510)
  ];

  bool _didUserMoved(originalLat, originalLong, currentLat, currentLong) {
    bool isUserMoved = false;
    //returns distance in meters
    final distance = Geolocator.distanceBetween(
        originalLat, originalLong, currentLat, currentLong);
    if (distance >= 1000) {
      isUserMoved = true;
    } else {
      isUserMoved = false;
    }
    return isUserMoved;
  }

  _checkTimer() {
    //TODO: need to change startShift to desired time for now it has been hardcoded.
    final startShift = DateTime.now();
    final endShift = DateTime.now().add(Duration(hours: 1));
    final currentTime = DateTime.now();

    //Calculation for whether user is in between start and end service.
    if (currentTime.isBefore(endShift) && currentTime.isAfter(startShift)) {
      _getNearbyLandmark();
    }
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getCurrentPosition();
    print('**************$position*********');
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.

      _showAlertDialog('Please enable the Location services');
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _showAlertDialog('Please enable the Location services');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _showAlertDialog(
          'Location permissions are denied, Please enable to continue.');
      return false;
    }
    _checkTimer();
    LocationPermission permissionType = await Geolocator.checkPermission();
    print('**********permissions enabled********$permissionType');
    _getNearbyLandmark();
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    return true;
  }

  _getNearbyLandmark() async {
    double? userStartLat;
    double? userStartLong;

    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    userStartLat = lastKnownPosition!.latitude;
    userStartLong = lastKnownPosition.longitude;

    //assign current location to vars for further comparison
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      print(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');

      final userCurrentLatitude = position!.latitude;
      final userCurrentLongitude = position.longitude;

      final isUserMoved = _didUserMoved(userStartLat, userStartLong,
          userCurrentLatitude, userCurrentLongitude);

//calculating nearby landmark only if user has been  moved
      if (isUserMoved) {
        double previousDistance = double.infinity;
        Landmark previousLandmark = const Landmark(
            title: 'No nearby Landmarks', latitude: 10.12, longitude: 12.10);
        _nearbyLandmarks.forEach((element) {
          final distance = Geolocator.distanceBetween(userCurrentLatitude,
              userCurrentLongitude, element.latitude, element.longitude);
          print('Distance is: $distance');

          if (distance < previousDistance) {
            previousDistance = distance;
            previousLandmark = Landmark(
                title: element.title,
                latitude: element.latitude,
                longitude: element.longitude);
          }
        });
        if (previousDistance < 7000) {
          if (!_ispopupShown) {
            setState(() {
              _showAlertDialog(previousLandmark.title);
            });
          }
        }
      }
    });
  }

  _showAlertDialog(placeTitle) {
    _ispopupShown = true;
    _positionStreamSubscription!.cancel();
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
  }

  @override
  void didChangeDependencies() {
    // _getPosition();
    // _getNearbyLandmark();
    _getCurrentPosition();

    // _checkTimer();
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
