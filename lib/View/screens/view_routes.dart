import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for rootBundle
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:math';

// ALGORITHM 1: TRIE DATA STRUCTURE FOR EFFICIENT SEARCH
// Time Complexity: O(m) for insertion and search, where m is length of word
// Space Complexity: O(ALPHABET_SIZE * N * M) where N is number of words, M is average length
class TrieNode {
  Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  Set<String> routeIds = {}; // Store unique route IDs to avoid duplicates
}

class RouteTrie {
  TrieNode root = TrieNode();
  Map<String, Map<String, dynamic>> routeMap = {}; // Map to store routes by ID
  
  // Insert route into Trie for efficient searching
  void insert(String word, Map<String, dynamic> route) {
    if (word.isEmpty) return;
    
    String routeId = route['route_number'] ?? route['route_name'] ?? '';
    if (routeId.isEmpty) return;
    
    // Store route in map
    routeMap[routeId] = route;
    
    TrieNode current = root;
    String lowerWord = word.toLowerCase().trim();
    
    // Traverse/Create path in Trie
    for (int i = 0; i < lowerWord.length; i++) {
      String char = lowerWord[i];
      if (!current.children.containsKey(char)) {
        current.children[char] = TrieNode();
      }
      current = current.children[char]!;
      current.routeIds.add(routeId); // Add route ID to each node in path
    }
    current.isEndOfWord = true;
  }
  
  // Search for routes matching prefix
  List<Map<String, dynamic>> searchByPrefix(String prefix) {
    if (prefix.isEmpty) return [];
    
    TrieNode current = root;
    String lowerPrefix = prefix.toLowerCase().trim();
    
    // Navigate to prefix end
    for (int i = 0; i < lowerPrefix.length; i++) {
      String char = lowerPrefix[i];
      if (!current.children.containsKey(char)) {
        return []; // Prefix not found
      }
      current = current.children[char]!;
    }
    
    // Return unique routes that match this prefix
    List<Map<String, dynamic>> results = [];
    for (String routeId in current.routeIds) {
      if (routeMap.containsKey(routeId)) {
        results.add(routeMap[routeId]!);
      }
    }
    
    return results;
  }
}

// ALGORITHM 2: MODIFIED DIJKSTRA'S ALGORITHM FOR ROUTE OPTIMIZATION
// Time Complexity: O(V log V + E) where V is vertices(stops) and E is edges(connections)
// Space Complexity: O(V) for distance array and priority queue
class RouteOptimizer {
  // Calculate shortest path between two stops using Dijkstra's algorithm
  static Map<String, dynamic> findOptimalRoute(
    List<Map<String, dynamic>> routes,
    String startStop,
    String endStop
  ) {
    // Create graph representation
    Map<String, List<Map<String, dynamic>>> graph = {};
    Map<String, double> distances = {};
    Set<String> allStops = {};
    
    // Build graph from routes data
    for (var route in routes) {
      List<dynamic> stops = route['stops'] ?? [];
      
      for (int i = 0; i < stops.length - 1; i++) {
        String currentStop = stops[i]['name'];
        String nextStop = stops[i + 1]['name'];
        double distance = (stops[i]['distance_to_next'] ?? 0.0).toDouble();
        double fare = (stops[i]['fare_to_next'] ?? 0.0).toDouble();
        
        allStops.add(currentStop);
        allStops.add(nextStop);
        
        // Initialize graph adjacency list
        if (!graph.containsKey(currentStop)) {
          graph[currentStop] = [];
        }
        
        graph[currentStop]!.add({
          'stop': nextStop,
          'distance': distance,
          'fare': fare,
          'route': route
        });
      }
    }
    
    // Initialize distances to infinity
    for (String stop in allStops) {
      distances[stop] = double.infinity;
    }
    distances[startStop] = 0.0;
    
    // Priority queue for Dijkstra's algorithm
    List<Map<String, dynamic>> priorityQueue = [
      {'stop': startStop, 'distance': 0.0, 'path': [startStop], 'totalFare': 0.0}
    ];
    
    Set<String> visited = {};
    
    // Dijkstra's main algorithm loop
    while (priorityQueue.isNotEmpty) {
      // Find minimum distance node (Priority Queue simulation)
      priorityQueue.sort((a, b) => a['distance'].compareTo(b['distance']));
      var current = priorityQueue.removeAt(0);
      
      String currentStop = current['stop'];
      double currentDistance = current['distance'];
      List<String> currentPath = List<String>.from(current['path']);
      double currentFare = current['totalFare'];
      
      if (visited.contains(currentStop)) continue;
      visited.add(currentStop);
      
      // Found destination
      if (currentStop == endStop) {
        return {
          'found': true,
          'distance': currentDistance,
          'fare': currentFare,
          'path': currentPath,
          'stops': currentPath.length
        };
      }
      
      // Explore neighbors
      if (graph.containsKey(currentStop)) {
        for (var neighbor in graph[currentStop]!) {
          String neighborStop = neighbor['stop'];
          double edgeDistance = neighbor['distance'];
          double edgeFare = neighbor['fare'];
          
          if (!visited.contains(neighborStop)) {
            double newDistance = currentDistance + edgeDistance;
            double newFare = currentFare + edgeFare;
            
            if (newDistance < distances[neighborStop]!) {
              distances[neighborStop] = newDistance;
              
              List<String> newPath = List<String>.from(currentPath);
              newPath.add(neighborStop);
              
              priorityQueue.add({
                'stop': neighborStop,
                'distance': newDistance,
                'path': newPath,
                'totalFare': newFare
              });
            }
          }
        }
      }
    }
    
    return {'found': false, 'message': 'No route found'};
  }
}

// ALGORITHM 3: MERGE SORT FOR EFFICIENT ROUTE SORTING
// Time Complexity: O(n log n) - optimal for comparison-based sorting
// Space Complexity: O(n) for temporary arrays
class RouteSorter {
  static List<Map<String, dynamic>> mergeSort(
    List<Map<String, dynamic>> routes,
    String sortBy
  ) {
    if (routes.length <= 1) return routes;
    
    int mid = routes.length ~/ 2;
    List<Map<String, dynamic>> left = routes.sublist(0, mid);
    List<Map<String, dynamic>> right = routes.sublist(mid);
    
    // Recursive divide
    left = mergeSort(left, sortBy);
    right = mergeSort(right, sortBy);
    
    // Merge sorted halves
    return merge(left, right, sortBy);
  }
  
  static List<Map<String, dynamic>> merge(
    List<Map<String, dynamic>> left,
    List<Map<String, dynamic>> right,
    String sortBy
  ) {
    List<Map<String, dynamic>> result = [];
    int i = 0, j = 0;
    
    // Merge process
    while (i < left.length && j < right.length) {
      dynamic leftValue = _getSortValue(left[i], sortBy);
      dynamic rightValue = _getSortValue(right[j], sortBy);
      
      if (leftValue.compareTo(rightValue) <= 0) {
        result.add(left[i]);
        i++;
      } else {
        result.add(right[j]);
        j++;
      }
    }
    
    // Add remaining elements
    while (i < left.length) {
      result.add(left[i]);
      i++;
    }
    while (j < right.length) {
      result.add(right[j]);
      j++;
    }
    
    return result;
  }
  
  static dynamic _getSortValue(Map<String, dynamic> route, String sortBy) {
    switch (sortBy) {
      case 'distance':
        return route['total_distance'] ?? 0.0;
      case 'fare':
        return route['total_fare'] ?? 0.0;
      case 'time':
        return route['estimated_time'] ?? 0;
      case 'route_number':
        return route['route_number'] ?? '';
      default:
        return route['route_name'] ?? '';
    }
  }
}

class ViewRoutesScreen extends StatefulWidget {
  @override
  _ViewRoutesScreenState createState() => _ViewRoutesScreenState();
}

class _ViewRoutesScreenState extends State<ViewRoutesScreen> {
  List<Map<String, dynamic>> allRoutes = [];
  List<Map<String, dynamic>> filteredRoutes = [];
  List<Map<String, dynamic>> places = [];
  
  // Algorithm instances
  RouteTrie routeTrie = RouteTrie();
  
  // UI State
  String searchQuery = '';
  String selectedSortOption = 'route_name';
  bool isLoading = true;
  String selectedStartStop = '';
  String selectedEndStop = '';
  Map<String, dynamic>? optimizedRoute;
  
  TextEditingController searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadRoutesData();
  }
  
  // Load and initialize routes data from JSON file
  Future<void> _loadRoutesData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Load JSON data from assets
      String jsonString = await rootBundle.loadString('lib/Model/service/data.json');
      Map<String, dynamic> data = json.decode(jsonString);
      
      // Extract places and routes from JSON
      places = List<Map<String, dynamic>>.from(data['places'] ?? []);
      allRoutes = List<Map<String, dynamic>>.from(data['routes'] ?? []);
      
      // ALGORITHM APPLICATION: Build Trie for efficient searching
      _buildSearchTrie();
      
      // ALGORITHM APPLICATION: Initial sorting using Merge Sort
      filteredRoutes = RouteSorter.mergeSort(List.from(allRoutes), selectedSortOption);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading routes data: $e');
      setState(() {
        isLoading = false;
      });
      
      // Show error message to user
      Get.snackbar(
        'Error',
        'Failed to load routes data. Please check if data.json file exists.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // ALGORITHM APPLICATION: Build Trie data structure for efficient search
  void _buildSearchTrie() {
    routeTrie = RouteTrie(); // Reset trie
    
    for (var route in allRoutes) {
      // Insert by route name
      if (route['route_name'] != null && route['route_name'].toString().isNotEmpty) {
        routeTrie.insert(route['route_name'].toString(), route);
      }
      
      // Insert by route number
      if (route['route_number'] != null && route['route_number'].toString().isNotEmpty) {
        routeTrie.insert(route['route_number'].toString(), route);
      }
      
      // Insert by start and end locations
      if (route['start'] != null && route['start'].toString().isNotEmpty) {
        routeTrie.insert(route['start'].toString(), route);
      }
      if (route['end'] != null && route['end'].toString().isNotEmpty) {
        routeTrie.insert(route['end'].toString(), route);
      }
      
      // Insert by all stop names for comprehensive search
      List<dynamic> stops = route['stops'] ?? [];
      for (var stop in stops) {
        if (stop['name'] != null && stop['name'].toString().isNotEmpty) {
          routeTrie.insert(stop['name'].toString(), route);
        }
      }
    }
  }
  
  // ALGORITHM APPLICATION: Search using Trie for O(m) complexity
  void _searchRoutes(String query) {
    setState(() {
      searchQuery = query.trim();
      
      if (searchQuery.isEmpty) {
        filteredRoutes = RouteSorter.mergeSort(List.from(allRoutes), selectedSortOption);
      } else {
        // Use Trie for efficient prefix search
        List<Map<String, dynamic>> searchResults = routeTrie.searchByPrefix(searchQuery);
        filteredRoutes = RouteSorter.mergeSort(searchResults, selectedSortOption);
      }
    });
  }
  
  // ALGORITHM APPLICATION: Sort routes using Merge Sort
  void _sortRoutes(String sortBy) {
    setState(() {
      selectedSortOption = sortBy;
      filteredRoutes = RouteSorter.mergeSort(List.from(filteredRoutes), sortBy);
    });
  }
  
  // ALGORITHM APPLICATION: Find optimal route using Dijkstra's algorithm
  void _findOptimalRoute() {
    if (selectedStartStop.isEmpty || selectedEndStop.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select both start and end stops',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Apply Dijkstra's algorithm to find optimal route
    Map<String, dynamic> result = RouteOptimizer.findOptimalRoute(
      allRoutes,
      selectedStartStop,
      selectedEndStop
    );
    
    setState(() {
      optimizedRoute = result;
    });
    
    if (result['found'] == true) {
      _showOptimalRouteDialog(result);
    } else {
      Get.snackbar(
        'No Route Found',
        'No direct route available between selected stops',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
  
  void _showOptimalRouteDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Optimal Route Found'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: ${result['distance'].toStringAsFixed(2)} km'),
                Text('Fare: ₹${result['fare'].toStringAsFixed(2)}'),
                Text('Stops: ${result['stops']}'),
                SizedBox(height: 10),
                Text('Route Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...List<String>.from(result['path']).map((stop) => 
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text('• $stop'),
                  )
                ).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
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
              backgroundColor: Colors.transparent.withOpacity(0.20),
              elevation: 50,
              title: const Text(
                'City Routes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ),
        ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Search and Filter Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Search Bar with Trie Algorithm
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search routes, stops, or numbers...',
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                      _searchRoutes('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onChanged: _searchRoutes,
                        ),
                        SizedBox(height: 16),
                        
                        // Sort Options using Merge Sort
                        Row(
                          children: [
                            Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedSortOption,
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _sortRoutes(newValue);
                                  }
                                },
                                items: [
                                  DropdownMenuItem(value: 'route_name', child: Text('Route Name')),
                                  DropdownMenuItem(value: 'route_number', child: Text('Route Number')),
                                  DropdownMenuItem(value: 'distance', child: Text('Distance')),
                                  DropdownMenuItem(value: 'fare', child: Text('Fare')),
                                  DropdownMenuItem(value: 'time', child: Text('Estimated Time')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Route Optimization Section using Dijkstra's Algorithm
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: ExpansionTile(
                        title: Text('Find Optimal Route (Dijkstra\'s Algorithm)', 
                                   style: TextStyle(fontSize: 14)),
                        leading: Icon(Icons.route, color: Colors.green),
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Start Stop Dropdown
                                Container(
                                  width: double.infinity,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Start Stop',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    value: selectedStartStop.isEmpty ? null : selectedStartStop,
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedStartStop = newValue ?? '';
                                      });
                                    },
                                    items: _getAllStops().map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                SizedBox(height: 12),
                                
                                // End Stop Dropdown
                                Container(
                                  width: double.infinity,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'End Stop',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    value: selectedEndStop.isEmpty ? null : selectedEndStop,
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedEndStop = newValue ?? '';
                                      });
                                    },
                                    items: _getAllStops().map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                SizedBox(height: 16),
                                
                                // Find Route Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _findOptimalRoute,
                                    child: Text('Find Optimal Route'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Results Counter
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filteredRoutes.length} routes found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  
                  // Routes List
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6, // Fixed height
                    child: filteredRoutes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty 
                                      ? 'No routes available' 
                                      : 'No routes found for "$searchQuery"',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      searchController.clear();
                                      _searchRoutes('');
                                    },
                                    child: Text('Clear Search'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredRoutes.length,
                            itemBuilder: (context, index) {
                              return _buildRouteCard(filteredRoutes[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
  
  List<String> _getAllStops() {
    Set<String> allStops = {};
    for (var route in allRoutes) {
      List<dynamic> stops = route['stops'] ?? [];
      for (var stop in stops) {
        String stopName = stop['name']?.toString() ?? '';
        if (stopName.isNotEmpty) {
          allStops.add(stopName);
        }
      }
    }
    return allStops.toList()..sort();
  }
  
  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          radius: 20,
          child: Text(
            route['route_number']?.toString() ?? '',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(
          route['route_name']?.toString() ?? '',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 4),
            Text('${route['start']} → ${route['end']}', 
                 style: TextStyle(fontSize: 14)),
            SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.straighten, size: 14, color: Colors.grey),
                  Text(' ${route['total_distance']} km', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 12),
                  Icon(Icons.currency_rupee, size: 14, color: Colors.grey),
                  Text(' ${route['total_fare']}', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 12),
                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                  Text(' ${route['estimated_time']} min', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Route Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('Frequency: Every ${route['frequency']} minutes', 
                     style: TextStyle(fontSize: 14)),
                Text('Operating Hours: ${route['start_time']} - ${route['end_time']}', 
                     style: TextStyle(fontSize: 14)),
                SizedBox(height: 12),
                Text(
                  'Stops:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: List<dynamic>.from(route['stops'] ?? []).map((stop) => 
                        Container(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stop['name']?.toString() ?? '',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              if ((stop['distance_to_next'] ?? 0) > 0)
                                Text(
                                  '${stop['distance_to_next']} km | ₹${stop['fare_to_next']}',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}