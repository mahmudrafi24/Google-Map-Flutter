import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? mapController;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Define initial coordinates for demonstration
  final LatLng _currentLocation =
      LatLng(23.015913, 91.397583); // Example: San Francisco
  final LatLng _destination = LatLng(22.3493, 91.8217); // Example: Los Angeles

  @override
  void initState() {
    super.initState();

    _markers.add(Marker(
      markerId: MarkerId('currentLocation'),
      position: _currentLocation,
      infoWindow:
          InfoWindow(title: 'Current Location', snippet: 'San Francisco'),
      onTap: () {
        String shareLink =
            "https://maps.google.com/?q=${_currentLocation.latitude},${_currentLocation.longitude}";

        // String shareLink =
        //     "https://github.com/axiftaj/Flutter-Google-Map-Tutorials/tree/main/images";
        Share.share(shareLink);
      },
    ));

    _markers.add(Marker(
      markerId: MarkerId('destination'),
      position: _destination,
      infoWindow: InfoWindow(title: 'Destination', snippet: 'Los Angeles'),
      onTap: () => _showLocationDetails('Destination', _destination),
    ));

    _polylines.add(Polyline(
      polylineId: PolylineId('route'),
      points: [_currentLocation, _destination],
      width: 5,
      color: Colors.blue,
    ));
  }

  // Show location details
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
                // Share location logic here (e.g., with URL)
                // String shareUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
                // print('Share this location: $shareUrl');
                // Navigator.pop(context);
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
        title: Text('Google Maps Flutter Example'),
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
      ),
    );
  }
}
