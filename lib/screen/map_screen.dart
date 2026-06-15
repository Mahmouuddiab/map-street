import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(24.7136, 46.6753); // Riyadh fallback
  LatLng? _marker;

  List<dynamic> _results = [];

  bool _loading = true;
  double _currentZoom = 15;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _loading = false);
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _center = currentLocation;
        _marker = currentLocation;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentLocation, _currentZoom);
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 500),
          () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'com.yourcompany.yourapp',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _results = json.decode(response.body);
        });
      }
    } catch (_) {}
  }

  void _selectResult(dynamic result) {
    final point = LatLng(
      double.parse(result['lat']),
      double.parse(result['lon']),
    );

    setState(() {
      _marker = point;
      _results = [];
      _searchController.text = result['display_name'];
    });

    _mapController.move(point, _currentZoom);
  }

  void _zoomIn() {
    _currentZoom++;
    _mapController.move(
      _mapController.camera.center,
      _currentZoom,
    );
  }

  void _zoomOut() {
    _currentZoom--;
    _mapController.move(
      _mapController.camera.center,
      _currentZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _currentZoom,
              minZoom: 3,
              maxZoom: 19,
              onTap: (_, point) {
                setState(() {
                  _marker = point;
                });
              },
              onPositionChanged: (position, hasGesture) {
                _currentZoom = position.zoom ?? _currentZoom;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yourcompany.yourapp',
              ),

              MarkerLayer(
                markers: [
                  if (_marker != null)
                    Marker(
                      point: _marker!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),

          /// Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  if (_results.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      constraints:
                      const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              _results[index]['display_name'],
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                            onTap: () =>
                                _selectResult(_results[index]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// Zoom & Location Buttons
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: "zoomIn",
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),

                const SizedBox(height: 8),

                FloatingActionButton.small(
                  heroTag: "zoomOut",
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),

                const SizedBox(height: 12),

                FloatingActionButton(
                  heroTag: "myLocation",
                  onPressed: _useCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}