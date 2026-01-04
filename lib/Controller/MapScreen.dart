import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:polyline_animation_v1/polyline_animation_v1.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import TTS package

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? fromPlace;
  final Map<String, dynamic>? toPlace;

  const MapScreen({
    Key? key,
    this.fromPlace,
    this.toPlace,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final PolylineAnimator _animator = PolylineAnimator();
  final Set<Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  bool _isLoading = true;
  Map<String, dynamic>? _routeData;
  MapType _currentMapType = MapType.normal; // Default map type
  
  // TTS related variables
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  int _currentStopIndex = 0;
  List<Map<String, dynamic>> _stops = [];
  bool _isSimulating = false;
  
  // Controller for bus simulation
  int _simulationDuration = 0; // Total duration in seconds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts();
    if (widget.fromPlace != null && widget.toPlace != null) {
      _loadRouteData();
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speak(String text) async {
    if (!_isSpeaking) {
      setState(() {
        _isSpeaking = true;
      });
      await _flutterTts.speak(text);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _flutterTts.stop();
    }
  }

  Future<void> _loadRouteData() async {
    try {
      final String response = await rootBundle.loadString('lib/Model/service/data.json');
      final data = await json.decode(response);
      final routes = List<Map<String, dynamic>>.from(data['routes']);
      
      // Find route matching from and to places
      final fromName = widget.fromPlace!['name'];
      final toName = widget.toPlace!['name'];
      
      for (var route in routes) {
        if ((route['start'] == fromName && route['end'] == toName) ||
            (route['start'] == toName && route['end'] == fromName)) {
          setState(() {
            _routeData = Map<String, dynamic>.from(route);
            _stops = List<Map<String, dynamic>>.from(_routeData!['stops']);
          });
          break;
        }
      }
      
      // If no exact route found, use the first route for demo
      if (_routeData == null && routes.isNotEmpty) {
        setState(() {
          _routeData = Map<String, dynamic>.from(routes[0]);
          _stops = List<Map<String, dynamic>>.from(_routeData!['stops']);
        });
      }
      
      _createMarkersAndPolyline();
      
      // Announce the route with route number and name
      Future.delayed(Duration(seconds: 1), () {
        _speak("Route ${_routeData!['route_number']}: ${_routeData!['route_name']} from ${_routeData!['start']} to ${_routeData!['end']} loaded. ${_stops.length} stops found.");
      });
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading route data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createMarkersAndPolyline() {
    if (_routeData == null) return;
    
    final List<LatLng> polylinePoints = [];
    
    // Add markers for each stop
    for (var i = 0; i < _stops.length; i++) {
      final stop = _stops[i];
      final marker = Marker(
        markerId: MarkerId('stop_$i'),
        position: LatLng(stop['latitude'], stop['longitude']),
        infoWindow: InfoWindow(
          title: stop['name'],
          snippet: i == 0 ? 'Start' : i == _stops.length - 1 ? 'End' : 'Stop',
        ),
        icon: i == 0 || i == _stops.length - 1 
            ? BitmapDescriptor.defaultMarkerWithHue(
                i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          // Enhanced speech feedback when marker is tapped
          String speechText = "This is ${stop['name']}";
          
          // Add route information if in simulation mode or always
          speechText += ", part of route ${_routeData!['route_number']}: ${_routeData!['route_name']}";
          
          _speak(speechText);
        },
      );
      _markers.add(marker); // Add marker to the Set
      polylinePoints.add(LatLng(stop['latitude'], stop['longitude']));
    }
    
    // Start polyline animation
    _startPolylineAnimation(polylinePoints);
    _centerMapOnRoute(polylinePoints); // Center the map on the route
  }

  void _startPolylineAnimation(List<LatLng> points) {
    _animator.animatePolyline(
      points,
      'polyline_id',
      Colors.blue,
      const Color.fromARGB(255, 164, 207, 240),
      _polylines,
      () {
        setState(() {});
      },
    );
  }

  void _centerMapOnRoute(List<LatLng> routeCoordinates) {
    if (routeCoordinates.isNotEmpty) {
      LatLngBounds bounds = _boundsFromLatLngList(routeCoordinates);
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (final latLng in list) {
      if (minLat == null || latLng.latitude < minLat) minLat = latLng.latitude;
      if (maxLat == null || latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (minLng == null || latLng.longitude < minLng) minLng = latLng.longitude;
      if (maxLng == null || latLng.longitude > maxLng) maxLng = latLng.longitude;
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_routeData != null) {
      _createMarkersAndPolyline();
    }
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  // Start the bus journey simulation
  void _startBusJourneySimulation() {
    if (_isSimulating) {
      _stopSimulation();
      return;
    }
    
    setState(() {
      _isSimulating = true;
      _currentStopIndex = 0;
    });
    
    // Calculate total duration based on estimated time
    _simulationDuration = _routeData!['estimated_time'] * 60; // Convert minutes to seconds
    
    // Announce start of journey with route information
    _speak("Starting journey on route ${_routeData!['route_number']}: ${_routeData!['route_name']} from ${_stops[0]['name']}");
    
    // Schedule announcements for each stop
    for (int i = 0; i < _stops.length; i++) {
      // Calculate when to announce this stop (proportionally divide the journey)
      final delayInSeconds = (i * _simulationDuration) ~/ (_stops.length - 1);
      
      Future.delayed(Duration(seconds: delayInSeconds), () {
        if (_isSimulating) {
          setState(() {
            _currentStopIndex = i;
          });
          
          // Move camera to current stop
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_stops[i]['latitude'], _stops[i]['longitude']),
              16,
            ),
          );
          
          // Enhanced stop announcement
          String announcement = "This is ${_stops[i]['name']}";
          
          // Add more context if it's not the first or last stop
          if (i > 0 && i < _stops.length - 1) {
            announcement += ", stop ${i + 1} of ${_stops.length} on route ${_routeData!['route_number']}: ${_routeData!['route_name']}";
          } else if (i == 0) {
            announcement += ", the starting point of your journey on route ${_routeData!['route_number']}: ${_routeData!['route_name']}";
          } else {
            announcement += ", the final destination of route ${_routeData!['route_number']}: ${_routeData!['route_name']}";
          }
          
          _speak(announcement);
        }
      });
    }
    
    // End simulation after full duration
    Future.delayed(Duration(seconds: _simulationDuration), () {
      if (_isSimulating) {
        _stopSimulation();
        _speak("You have reached your destination, ${_stops.last['name']} on route ${_routeData!['route_number']}: ${_routeData!['route_name']}");
      }
    });
  }
  
  void _stopSimulation() {
    setState(() {
      _isSimulating = false;
    });
    _speak("Journey simulation stopped on route ${_routeData!['route_number']}: ${_routeData!['route_name']}");
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animator.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent.withOpacity(0.2),
            elevation: 1,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Map',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.map, color: Colors.white),
                onPressed: _onMapTypeButtonPressed,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView( // Wrap the Column in a SingleChildScrollView
          child: Column(
            children: [
              // Map Container
              Container(
                height: 450, // Adjusted height to fit the new UI elements
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  myLocationEnabled: true,
                  markers: _markers,
                  polylines: _polylines.values.toSet(),
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(18.5308, 73.8473), // Default to Shivaji Nagar
                    zoom: 14,
                  ),
                  mapType: _currentMapType,
                ),
              ),
              
              // Voice assistance status bar
              Container(
                color: Colors.blue.shade100,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      _isSpeaking ? Icons.volume_up : Icons.volume_off,
                      color: _isSpeaking ? Colors.blue : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isSpeaking 
                          ? "Speaking..." 
                          : "Voice assistance ready",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _startBusJourneySimulation,
                      icon: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
                      label: Text(_isSimulating ? "Stop Simulation" : "Simulate Journey"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSimulating ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Route details information
              if (_routeData != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route Title with Speak Button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Route ${_routeData!['route_number']}: ${_routeData!['route_name']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        IconButton(
  icon: Icon(Icons.volume_up, color: Colors.blue),
  onPressed: () {
    _speak("Route ${_routeData!['route_number']}: ${_routeData!['route_name']} from ${_routeData!['start']} to ${_routeData!['end']}");
  },
  tooltip: "Speak Route Name",
),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Distance: ${_routeData!['total_distance']} km',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Estimated Time: ${_routeData!['estimated_time']} minutes',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Fare: ₹${_routeData!['total_fare']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Frequency: Every ${_routeData!['frequency']} minutes',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Operating Hours: ${_routeData!['start_time']} - ${_routeData!['end_time']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Current stop:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _isSimulating 
                        ? ListTile(
                            leading: Icon(Icons.location_on, color: Colors.red),
                            title: Text(
                              _stops[_currentStopIndex]['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Stop ${_currentStopIndex + 1} of ${_stops.length}',
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.volume_up, color: Colors.blue),
                              onPressed: () {
                                _speak("${_stops[_currentStopIndex]['name']}, stop ${_currentStopIndex + 1} of ${_stops.length} on route ${_routeData!['route_number']}: ${_routeData!['route_name']}");
                              },
                            ),
                            tileColor: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )
                        : Text(
                            'Tap "Simulate Journey" to start voice guidance',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    );
  }
}