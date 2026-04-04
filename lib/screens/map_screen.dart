import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart';
import '../services/trips_repository.dart';

enum _TravelMode { walking, driving }

class _RouteEndpoint {
  _RouteEndpoint({
    required this.key,
    required this.label,
    required this.point,
  });

  final String key;
  final String label;
  final LatLng point;
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  final int tripId;
  final String tripName;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TripsRepository _repository = TripsRepository();
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  bool _isLoading = true;
  bool _useLocalTiles = false;
  String? _localTilesPath;
  List<Place> _places = [];
  Position? _userLocation;
  _TravelMode _travelMode = _TravelMode.walking;
  String? _selectedStartKey;
  String? _selectedEndKey;
  List<LatLng> _offlineRoutePoints = [];
  String? _routeSummary;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
    });

    final places = await _repository.listPlaces(widget.tripId);
    final localPath = await _resolveLocalTilesPath();
    final userLocation = await _loadUserLocation();

    if (!mounted) return;

    setState(() {
      _places = places;
      _localTilesPath = localPath;
      _useLocalTiles = localPath != null;
      _userLocation = userLocation;
      _initializeRouteSelection();
      _rebuildOfflineRoute();
      _isLoading = false;
    });
  }

  void _initializeRouteSelection() {
    final endpoints = _routeEndpoints();
    if (endpoints.length < 2) {
      _selectedStartKey = null;
      _selectedEndKey = null;
      return;
    }

    _selectedStartKey ??= endpoints.first.key;
    _selectedEndKey ??= endpoints
        .firstWhere(
          (endpoint) => endpoint.key != _selectedStartKey,
          orElse: () => endpoints.first,
        )
        .key;

    if (_selectedStartKey == _selectedEndKey) {
      final alternative = endpoints.firstWhere(
        (endpoint) => endpoint.key != _selectedStartKey,
        orElse: () => endpoints.first,
      );
      _selectedEndKey = alternative.key;
    }
  }

  Future<String?> _resolveLocalTilesPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory(p.join(appDir.path, 'planora', 'osm_tiles'));

    if (!await tilesDir.exists()) {
      return null;
    }

    return tilesDir.path;
  }

  Future<Position?> _loadUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  LatLng _initialCenter() {
    if (_places.isNotEmpty) {
      return LatLng(_places.first.latitude, _places.first.longitude);
    }

    if (_userLocation != null) {
      return LatLng(_userLocation!.latitude, _userLocation!.longitude);
    }

    return const LatLng(48.8566, 2.3522);
  }

  void _centerOnUser() {
    if (_userLocation == null) {
      return;
    }

    _mapController.move(
      LatLng(_userLocation!.latitude, _userLocation!.longitude),
      14,
    );
  }

  List<_RouteEndpoint> _routeEndpoints() {
    final endpoints = <_RouteEndpoint>[];
    if (_userLocation != null) {
      endpoints.add(
        _RouteEndpoint(
          key: 'user',
          label: 'My location',
          point: LatLng(_userLocation!.latitude, _userLocation!.longitude),
        ),
      );
    }

    for (final place in _places) {
      endpoints.add(
        _RouteEndpoint(
          key: 'place_${place.id}',
          label: place.name,
          point: LatLng(place.latitude, place.longitude),
        ),
      );
    }

    return endpoints;
  }

  _RouteEndpoint? _endpointByKey(String? key) {
    if (key == null) {
      return null;
    }

    final endpoints = _routeEndpoints();
    for (final endpoint in endpoints) {
      if (endpoint.key == key) {
        return endpoint;
      }
    }
    return null;
  }

  void _rebuildOfflineRoute() {
    final start = _endpointByKey(_selectedStartKey);
    final end = _endpointByKey(_selectedEndKey);

    if (start == null || end == null || start.key == end.key) {
      _offlineRoutePoints = [];
      _routeSummary = null;
      return;
    }

    final kilometers =
        _distance.as(LengthUnit.Kilometer, start.point, end.point);
    final speed = _travelMode == _TravelMode.walking ? 5.0 : 45.0;
    final minutes = (kilometers / speed) * 60;

    _offlineRoutePoints = _interpolateRoute(start.point, end.point);
    final modeText = _travelMode == _TravelMode.walking ? 'Walking' : 'Driving';
    _routeSummary =
        '$modeText route: ${kilometers.toStringAsFixed(2)} km, ${minutes.toStringAsFixed(0)} min (offline estimate)';
  }

  List<LatLng> _interpolateRoute(LatLng start, LatLng end) {
    final kilometers = _distance.as(LengthUnit.Kilometer, start, end);
    final steps = math.max(2, math.min(40, (kilometers * 2).round()));
    final points = <LatLng>[];

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(
        LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          start.longitude + (end.longitude - start.longitude) * t,
        ),
      );
    }

    return points;
  }

  Future<void> _openGoogleMapsPlace(Place place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openGoogleMapsRoute() async {
    final start = _endpointByKey(_selectedStartKey);
    final end = _endpointByKey(_selectedEndKey);
    if (start == null || end == null || start.key == end.key) {
      return;
    }

    final travelMode =
        _travelMode == _TravelMode.walking ? 'walking' : 'driving';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${start.point.latitude},${start.point.longitude}'
      '&destination=${end.point.latitude},${end.point.longitude}'
      '&travelmode=$travelMode',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onPlaceMarkerTapped(Place place) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: Text(place.name),
              subtitle: Text(
                  '${place.latitude.toStringAsFixed(6)}, ${place.longitude.toStringAsFixed(6)}'),
            ),
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: const Text('Set as destination'),
              onTap: () {
                setState(() {
                  _selectedEndKey = 'place_${place.id}';
                  _rebuildOfflineRoute();
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open in Google Maps'),
              onTap: () async {
                Navigator.of(context).pop();
                await _openGoogleMapsPlace(place);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[
      ..._places.map(
        (place) => Marker(
          point: LatLng(place.latitude, place.longitude),
          width: 44,
          height: 44,
          child: Tooltip(
            message: place.name,
            child: GestureDetector(
              onTap: () => _onPlaceMarkerTapped(place),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 34,
              ),
            ),
          ),
        ),
      ),
    ];

    if (_userLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tripName} Map'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _loadMapData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Center on me',
            onPressed: _centerOnUser,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: _useLocalTiles
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    _useLocalTiles
                        ? 'Offline tiles: ON (${_localTilesPath!})'
                        : 'Offline tiles not found. Using online OSM tiles.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter(),
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _useLocalTiles
                            ? 'file:///${_localTilesPath!}/{z}/{x}/{y}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.planora',
                      ),
                      if (_offlineRoutePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _offlineRoutePoints,
                              color: _travelMode == _TravelMode.walking
                                  ? Colors.blue
                                  : Colors.deepOrange,
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SegmentedButton<_TravelMode>(
                            segments: const [
                              ButtonSegment<_TravelMode>(
                                value: _TravelMode.walking,
                                icon: Icon(Icons.directions_walk),
                                label: Text('On foot'),
                              ),
                              ButtonSegment<_TravelMode>(
                                value: _TravelMode.driving,
                                icon: Icon(Icons.directions_car),
                                label: Text('Car'),
                              ),
                            ],
                            selected: {_travelMode},
                            onSelectionChanged: (selected) {
                              setState(() {
                                _travelMode = selected.first;
                                _rebuildOfflineRoute();
                              });
                            },
                          ),
                          OutlinedButton.icon(
                            onPressed: _offlineRoutePoints.length < 2
                                ? null
                                : _openGoogleMapsRoute,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open route in Google Maps'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration(labelText: 'From'),
                              initialValue:
                                _endpointByKey(_selectedStartKey) == null
                                  ? null
                                  : _selectedStartKey,
                              items: _routeEndpoints()
                                  .map(
                                    (endpoint) => DropdownMenuItem<String>(
                                      value: endpoint.key,
                                      child: Text(endpoint.label),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStartKey = value;
                                  _rebuildOfflineRoute();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration(labelText: 'To'),
                              initialValue:
                                _endpointByKey(_selectedEndKey) == null
                                  ? null
                                  : _selectedEndKey,
                              items: _routeEndpoints()
                                  .map(
                                    (endpoint) => DropdownMenuItem<String>(
                                      value: endpoint.key,
                                      child: Text(endpoint.label),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                setState(() {
                                  _selectedEndKey = value;
                                  _rebuildOfflineRoute();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_routeSummary != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _routeSummary!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
