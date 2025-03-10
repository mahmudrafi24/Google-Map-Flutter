import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _fromLocation;
  LatLng? _toLocation;
  TextEditingController fromLocationController = TextEditingController();
  TextEditingController toLocationController = TextEditingController();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _distance = '';

  @override
  void initState() {
    super.initState();
  }

  Future<List<dynamic>> _fetchPlaceSuggestions(String query) async {
    final String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
    final String apiUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions'];
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<LatLng> _getPlaceDetails(String placeId) async {
    final String apiKey = 'AIzaSyDk7p1Vl9WOtcDztagS6yPsgUYaVu_bCro';
    final String apiUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } else {
      throw Exception('Failed to load place details');
    }
  }

  Future<void> _fetchRouteAndDistance(LatLng origin, LatLng destination) async {
    final String apiKey = 'AIzaSyDk7p1Vl9WOtcDztagS6yPsgUYaVu_bCro';
    final String apiUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        // Extract distance
        setState(() {
          _distance = data['routes'][0]['legs'][0]['distance']['text'];
        });

        // Decode polyline points
        List<PointLatLng> points = PolylinePoints()
            .decodePolyline(data['routes'][0]['overview_polyline']['points']);

        // Convert points to LatLng list
        List<LatLng> polylineCoordinates = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Add polyline to the map
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          );
        });
      }
    } else {
      throw Exception('Failed to load route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Route Finder'),
      ),
      body: Column(
        children: [
          // From location TextField with suggestions
          TypeAheadField(
            suggestionsCallback: (pattern) async {
              return await _fetchPlaceSuggestions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion['description']),
              );
            },
            onSelected: (suggestion) async {
              fromLocationController.text = suggestion['description'];
              LatLng location = await _getPlaceDetails(suggestion['place_id']);
              setState(() {
                _fromLocation = location;
              });

              if (_fromLocation != null && _toLocation != null) {
                await _fetchRouteAndDistance(_fromLocation!, _toLocation!);
              }
            },
          ),

          // To location TextField with suggestions
          TypeAheadField(
            suggestionsCallback: (pattern) async {
              return await _fetchPlaceSuggestions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion['description']),
              );
            },
            onSelected: (suggestion) async {
              toLocationController.text = suggestion['description'];
              LatLng location = await _getPlaceDetails(suggestion['place_id']);
              setState(() {
                _toLocation = location;
              });

              if (_fromLocation != null && _toLocation != null) {
                await _fetchRouteAndDistance(_fromLocation!, _toLocation!);
              }
            },
          ),

          if (_distance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Distance: $_distance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

          // Display the map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _fromLocation ?? LatLng(0, 0),
                zoom: 14.0,
              ),
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                });
              },
              markers: {
                if (_fromLocation != null)
                  Marker(
                    markerId: MarkerId('fromLocation'),
                    position: _fromLocation!,
                    infoWindow: InfoWindow(title: 'From Location'),
                  ),
                if (_toLocation != null)
                  Marker(
                    markerId: MarkerId('toLocation'),
                    position: _toLocation!,
                    infoWindow: InfoWindow(title: 'To Location'),
                  ),
              },
              polylines: _polylines,
            ),
          ),
        ],
      ),
    );
  }
}
