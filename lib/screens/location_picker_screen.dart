import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initialPoint,
  });

  final LatLng initialPoint;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: _selectedPoint == null
                ? null
                : () => Navigator.of(context).pop(_selectedPoint),
            child: const Text('Use point'),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _selectedPoint ?? widget.initialPoint,
          initialZoom: 13,
          onLongPress: (_, point) {
            setState(() {
              _selectedPoint = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.planora',
          ),
          if (_selectedPoint != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedPoint!,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(12),
        child: Text(
          _selectedPoint == null
              ? 'Long press on map to choose a location.'
              : 'Selected: ${_selectedPoint!.latitude.toStringAsFixed(6)}, ${_selectedPoint!.longitude.toStringAsFixed(6)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
