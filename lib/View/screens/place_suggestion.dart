import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class PlaceSuggestionField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final Function(Map<String, dynamic>) onPlaceSelected;
  final Function(double, double)? onRouteCalculated;

  const PlaceSuggestionField({
    Key? key,
    required this.hint,
    required this.icon,
    required this.onPlaceSelected,
    this.onRouteCalculated,
  }) : super(key: key);

  @override
  PlaceSuggestionFieldState createState() => PlaceSuggestionFieldState();
}

class PlaceSuggestionFieldState extends State<PlaceSuggestionField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _places = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedPlace = '';
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // When focused, show overlay if there are filtered results
        if (_filteredPlaces.isNotEmpty && _controller.text.isNotEmpty) {
          _showOverlay();
        }
      } else {
        // When focus is lost, hide overlay
        _hideOverlay();
      }
    });
    
    _controller.addListener(() {
      final query = _controller.text.trim();
      print('DEBUG: Controller text changed: "$query"');
      
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        _filterPlaces(query);
      } else {
        setState(() {
          _isSearching = false;
          _filteredPlaces = [];
        });
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    try {
      print('DEBUG: Loading places from data.json');
      final String response = await rootBundle.loadString('lib/Model/service/data.json');
      final data = await json.decode(response);
      
      print('DEBUG: Data loaded successfully');
      print('DEBUG: Places count: ${data['places']?.length ?? 0}');
      print('DEBUG: Routes count: ${data['routes']?.length ?? 0}');
      
      setState(() {
        _places = List<Map<String, dynamic>>.from(data['places'] ?? []);
        _routes = List<Map<String, dynamic>>.from(data['routes'] ?? []);
        _isLoading = false;
      });
      
      // Print first few places for debugging
      if (_places.isNotEmpty) {
        print('DEBUG: First few places:');
        for (int i = 0; i < math.min(3, _places.length); i++) {
          print('  ${i + 1}. ${_places[i]['name']}');
        }
      }
    } catch (e) {
      print("ERROR: Error loading places: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPlaces(String query) {
    print('DEBUG: Filtering places with query: "$query"');
    
    if (query.isEmpty) {
      print('DEBUG: Query is empty, clearing filtered places');
      setState(() {
        _filteredPlaces = [];
      });
      _hideOverlay();
      return;
    }

    if (_places.isEmpty) {
      print('DEBUG: No places loaded yet');
      return;
    }

    final filteredList = _places.where((place) {
      final placeName = place['name']?.toString().toLowerCase() ?? '';
      final queryLower = query.toLowerCase();
      final matches = placeName.contains(queryLower);
      
      if (matches) {
        print('DEBUG: Found match: ${place['name']}');
      }
      
      return matches;
    }).toList();

    print('DEBUG: Found ${filteredList.length} matching places');

    setState(() {
      _filteredPlaces = filteredList;
    });

    // Show overlay if we have results and the field is focused
    if (_filteredPlaces.isNotEmpty && _focusNode.hasFocus) {
      print('DEBUG: Showing overlay with ${_filteredPlaces.length} results');
      _showOverlay();
    } else {
      print('DEBUG: Hiding overlay (no results or not focused)');
      _hideOverlay();
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    print('DEBUG: Place selected: ${place['name']}');
    
    setState(() {
      _selectedPlace = place['name'] ?? '';
      _controller.text = place['name'] ?? '';
      _isSearching = false;
      _filteredPlaces = [];
    });
    
    _hideOverlay();
    _focusNode.unfocus();
    widget.onPlaceSelected(place);
  }

  void _showOverlay() {
    if (_filteredPlaces.isEmpty) {
      print('DEBUG: Cannot show overlay - no filtered places');
      return;
    }
    
    print('DEBUG: Attempting to show overlay');
    _hideOverlay(); // Remove existing overlay first
    
    // Add a small delay to ensure the widget is properly rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _filteredPlaces.isNotEmpty) {
        _overlayEntry = _createOverlayEntry();
        if (_overlayEntry != null) {
          Overlay.of(context).insert(_overlayEntry!);
          print('DEBUG: Overlay inserted successfully');
        }
      }
    });
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      print('DEBUG: Hiding overlay');
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry? _createOverlayEntry() {
    if (_filteredPlaces.isEmpty) {
      print('DEBUG: Cannot create overlay - no filtered places');
      return null;
    }
    
    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        print('DEBUG: Cannot create overlay - render box is null');
        return null;
      }
      
      final size = renderBox.size;
      print('DEBUG: Creating overlay with ${_filteredPlaces.length} items');
      
      return OverlayEntry(
        builder: (context) => Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 5.0),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: math.min(5, _filteredPlaces.length),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = _filteredPlaces[index];
                    return ListTile(
                      dense: true,
                      title: Text(place['name'] ?? ''),
                      subtitle: Text(
                        "Lat: ${place['latitude']}, Lng: ${place['longitude']}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('DEBUG: Error creating overlay: $e');
      return null;
    }
  }

  // Method to find route between two places
  Map<String, dynamic>? _findRouteBetweenPlaces(String fromPlace, String toPlace) {
    for (var route in _routes) {
      String routeStart = route['start']?.toString().toLowerCase() ?? '';
      String routeEnd = route['end']?.toString().toLowerCase() ?? '';
      String from = fromPlace.toLowerCase();
      String to = toPlace.toLowerCase();

      if ((routeStart.contains(from) || from.contains(routeStart)) &&
          (routeEnd.contains(to) || to.contains(routeEnd))) {
        return route;
      } else if ((routeStart.contains(to) || to.contains(routeStart)) &&
                 (routeEnd.contains(from) || from.contains(routeEnd))) {
        return route;
      }
    }
    return null;
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _clearSelection() {
    print('DEBUG: Clearing selection');
    setState(() {
      _selectedPlace = '';
      _controller.text = '';
      _isSearching = false;
      _filteredPlaces = [];
    });
    _hideOverlay();
    widget.onPlaceSelected({});
  }

  // Public method to get route info between two places
  Map<String, dynamic> getRouteInfo(String fromPlace, String toPlace) {
    var route = _findRouteBetweenPlaces(fromPlace, toPlace);
    
    if (route != null) {
      return {
        'distance': route['total_distance']?.toDouble() ?? 0.0,
        'fare': route['total_fare']?.toDouble() ?? 0.0,
        'route': route,
      };
    } else {
      // Calculate approximate distance using coordinates
      var fromPlaceData = _places.firstWhere(
        (place) => place['name'].toString().toLowerCase().contains(fromPlace.toLowerCase()),
        orElse: () => {},
      );
      var toPlaceData = _places.firstWhere(
        (place) => place['name'].toString().toLowerCase().contains(toPlace.toLowerCase()),
        orElse: () => {},
      );
      
      if (fromPlaceData.isNotEmpty && toPlaceData.isNotEmpty) {
        double distance = _calculateDistance(
          fromPlaceData['latitude']?.toDouble() ?? 0.0,
          fromPlaceData['longitude']?.toDouble() ?? 0.0,
          toPlaceData['latitude']?.toDouble() ?? 0.0,
          toPlaceData['longitude']?.toDouble() ?? 0.0,
        );
        
        double approximateFare = distance * 5;
        
        return {
          'distance': distance,
          'fare': approximateFare,
          'route': null,
        };
      }
    }
    
    return {'distance': 0.0, 'fare': 0.0, 'route': null};
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: _selectedPlace.isNotEmpty
                ? GestureDetector(
                    onTap: _clearSelection,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPlace,
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.clear, size: 18, color: Colors.grey),
                      ],
                    ),
                  )
                : TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(fontSize: 16, color: Colors.black54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _isSearching = false;
                                _filteredPlaces = [];
                              });
                              _hideOverlay();
                            },
                          )
                        : null,
                    ),
                    onChanged: (query) {
                      // The filtering is handled in the controller listener
                      print('DEBUG: Text field onChanged: "$query"');
                    },
                    onTap: () {
                      print('DEBUG: Text field tapped');
                      // If there's already text, trigger filtering
                      if (_controller.text.isNotEmpty) {
                        _filterPlaces(_controller.text);
                      }
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}