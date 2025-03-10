import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final LatLng _currentLocation = LatLng(23.015913, 91.397583); // Example: Feni
  final LatLng _destination = LatLng(22.3493, 91.8217); // Example: Chittagong

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _fetchRouteAndDrawPolyline();
  }

  void _setMarkers() {
    _markers.add(Marker(
      markerId: MarkerId('currentLocation'),
      position: _currentLocation,
      infoWindow: InfoWindow(title: 'Current Location', snippet: 'Feni'),
      onTap: () {
        String shareLink =
            "https://maps.google.com/?q=${_currentLocation.latitude},${_currentLocation.longitude}";
        Share.share(shareLink);
      },
    ));

    _markers.add(Marker(
      markerId: MarkerId('destination'),
      position: _destination,
      infoWindow: InfoWindow(title: 'Destination', snippet: 'Chittagong'),
      onTap: () => _showLocationDetails('Destination', _destination),
    ));
  }

  Future<void> _fetchRouteAndDrawPolyline() async {
    const String apiKey = 'AIzaSyAszXC1be8aJ37eHuNcBm_-O1clWkPUwV4';
    final String apiUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation.latitude},${_currentLocation.longitude}&destination=${_destination.latitude},${_destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        List<PointLatLng> points = PolylinePoints()
            .decodePolyline(data['routes'][0]['overview_polyline']['points']);

        List<LatLng> polylineCoordinates = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              points: polylineCoordinates,
              color: Colors.redAccent,
              width: 6,
            ),
          );
        });
      }
    } else {
      throw Exception('Failed to load route');
    }
  }

  void _showLocationDetails(String title, LatLng location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
              'Latitude: ${location.latitude}, Longitude: ${location.longitude}'),
          actions: [
            TextButton(
              onPressed: () {
                String shareLink =
                    "https://www.google.com/maps?q=${location.latitude},${location.longitude}";
                Share.share(shareLink);
              },
              child: Text('Share Location'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Directions'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 10.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: _markers,
        polylines: _polylines,
        mapType: MapType.normal,
      ),
    );
  }
}
