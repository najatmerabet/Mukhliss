// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukhliss/services/openrouteservice.dart';
// Import your OSRM service
// import 'package:mukhliss/services/osrm_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  OSRMRoute? _currentRoute;
  bool _isLoading = false;
  Shop? _selectedShop;

  // Shop locations near Mountain View, CA
 final List<Shop> shops = [
  Shop(
    name: "Whole Foods Market",
    location: LatLng(37.4274, -122.0807),
  ), // 0.7 miles away
  Shop(
    name: "Safeway",
    location: LatLng(37.4154, -122.0775),
  ), // 0.8 miles away
  Shop(
    name: "Target",
    location: LatLng(37.4147, -122.0796),
  ), // 0.9 miles away
  Shop(
    name: "Trader Joe's",
    location: LatLng(37.4254, -122.0975),
  ), // 1.0 miles away
  Shop(
    name: "Walmart",
    location: LatLng(37.4417, -122.0864),
  ), // 2.1 miles away
  Shop(
    name: "Costco",
    location: LatLng(37.4216, -122.1115),
  ), // 2.3 miles away
  // New shop in Tangier, Morocco

];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController.move(_userLocation!, 14);
    } catch (e) {
      // ignore: avoid_print
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error and use test location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using test location in Mountain View, CA'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );

      // Set test location in Mountain View, CA
      setState(() {
        _userLocation = LatLng(37.422, -122.084);
      });
      _mapController.move(_userLocation!, 14);
    }
  }

  Future<void> _onShopTapped(Shop shop) async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Getting your location...')));
      await _getCurrentLocation();
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedShop = shop;
    });

    try {
      // Get route from OSRM
      final route = await OSRMService.getRoute(_userLocation!, shop.location);

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _isLoading = false;
        });

        // Show route info
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${shop.name}: ${route.distanceText} (${route.durationText})',
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Fit map to show entire route
        if (route.coordinates.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints([
            _userLocation!,
            shop.location,
            ...route.coordinates,
          ]);

          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not find route')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _selectedShop = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Navigator'),
        actions: [
          if (_currentRoute != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearRoute,
              tooltip: 'Clear route',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(37.422, -122.084), // Mountain View, CA
              initialZoom: 14,
              maxZoom: 18,

            ),
            children: [
              // Map tiles
              TileLayer(
                urlTemplate:
                    'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.example.app',
                subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
              ),

              // Route polyline
              if (_currentRoute != null &&
                  _currentRoute!.coordinates.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Border/outline polyline (drawn first, wider)
                    Polyline(
                      points: _currentRoute!.coordinates,
                      color: Color(0xFF2D5F8B), // Dark blue border
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Main route polyline (drawn on top, narrower)
                    Polyline(
                      points: _currentRoute!.coordinates,
                      color: Color(0xFF4A90E2), // Bright blue fill
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Shop markers
                  ...shops
                      .map(
                        (shop) => Marker(
                          point: shop.location,
                          width: 120,
                          height: 80,
                          child: GestureDetector(
                            onTap: () => _onShopTapped(shop),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedShop == shop
                                            ? Colors.blue
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    shop.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _selectedShop == shop
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.store,
                                  color:
                                      _selectedShop == shop
                                          ? Colors.blue
                                          : Colors.red,
                                  size: 35,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),

                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Route info card
          if (_currentRoute != null && _selectedShop != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedShop!.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 20,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(_currentRoute!.distanceText),
                          SizedBox(width: 16),
                          Icon(Icons.access_time, size: 20, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(_currentRoute!.durationText),
                        ],
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement navigation
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Navigation'),
                                  content: Text(
                                    'Navigation would start here.\n\n'
                                    'Route: ${_currentRoute!.distanceText} '
                                    '(${_currentRoute!.durationText})',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        icon: Icon(Icons.navigation),
                        label: Text('Start Navigation'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Calculating route...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: Icon(Icons.my_location),
        tooltip: 'My location',
      ),
    );
  }
}

class Shop {
  final String name;
  final LatLng location;

  Shop({required this.name, required this.location});
}
