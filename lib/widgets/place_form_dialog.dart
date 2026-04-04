import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../screens/location_picker_screen.dart';
import '../services/google_maps_link_parser.dart';

class PlaceFormData {
  PlaceFormData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.note,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? note;
}

class PlaceFormDialog extends StatefulWidget {
  const PlaceFormDialog({
    super.key,
    required this.title,
    this.initialPlace,
    this.initialGoogleMapsLink,
  });

  final String title;
  final Place? initialPlace;
  final String? initialGoogleMapsLink;

  static Future<PlaceFormData?> show(
    BuildContext context, {
    required String title,
    Place? initialPlace,
    String? initialGoogleMapsLink,
  }) {
    return showDialog<PlaceFormData>(
      context: context,
      builder: (context) => PlaceFormDialog(
        title: title,
        initialPlace: initialPlace,
        initialGoogleMapsLink: initialGoogleMapsLink,
      ),
    );
  }

  @override
  State<PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends State<PlaceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _googleMapsLinkController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _noteController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialPlace?.name ?? '');
    _googleMapsLinkController =
        TextEditingController(text: widget.initialGoogleMapsLink ?? '');
    _latitudeController = TextEditingController(
        text: widget.initialPlace?.latitude.toString() ?? '');
    _longitudeController = TextEditingController(
        text: widget.initialPlace?.longitude.toString() ?? '');
    _noteController =
        TextEditingController(text: widget.initialPlace?.note ?? '');

    if ((widget.initialGoogleMapsLink ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _extractFromGoogleMapsLink();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _googleMapsLinkController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<ParsedGoogleMapsLink?> _parseGoogleMapsInput(String rawInput) async {
    final direct = GoogleMapsLinkParser.parse(rawInput);
    if (direct != null) {
      return direct;
    }

    final resolved = await _resolvePotentialShortLink(rawInput);
    if (!mounted || resolved == rawInput) {
      return GoogleMapsLinkParser.parse(rawInput);
    }

    _googleMapsLinkController.text = resolved;
    return GoogleMapsLinkParser.parse(resolved);
  }

  Future<String> _resolvePotentialShortLink(String rawInput) async {
    final trimmed = rawInput.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return trimmed;
    }

    final host = uri.host.toLowerCase();
    final isShortGoogleMapsHost = host == 'maps.app.goo.gl' ||
        host == 'goo.gl' ||
        host.endsWith('.goo.gl');
    if (!isShortGoogleMapsHost) {
      return trimmed;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      var current = uri;
      for (var i = 0; i < 6; i++) {
        final request = await client.getUrl(current);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0');
        final response = await request.close();

        if (response.isRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          await response.drain<void>();
          if (location == null || location.trim().isEmpty) {
            return current.toString();
          }
          current = current.resolve(location);
          continue;
        }

        await response.drain<void>();
        return current.toString();
      }
      return current.toString();
    } catch (_) {
      return trimmed;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _extractFromGoogleMapsLink() async {
    final parsed = await _parseGoogleMapsInput(_googleMapsLinkController.text);
    if (!mounted) {
      return;
    }

    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not extract coordinates from this Google Maps link.')),
      );
      return;
    }

    setState(() {
      _latitudeController.text = parsed.latitude.toStringAsFixed(6);
      _longitudeController.text = parsed.longitude.toStringAsFixed(6);
      if (_nameController.text.trim().isEmpty &&
          parsed.name != null &&
          parsed.name!.trim().isNotEmpty) {
        _nameController.text = parsed.name!.trim();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Coordinates extracted from Google Maps link.')),
    );
  }

  Future<void> _autoExtractFromLinkIfNeeded() async {
    final needsName = _nameController.text.trim().isEmpty;
    final needsLatitude =
        double.tryParse(_latitudeController.text.trim()) == null;
    final needsLongitude =
        double.tryParse(_longitudeController.text.trim()) == null;

    if (!needsName && !needsLatitude && !needsLongitude) {
      return;
    }

    final link = _googleMapsLinkController.text.trim();
    if (link.isEmpty) {
      return;
    }

    final parsed = await _parseGoogleMapsInput(link);
    if (!mounted) {
      return;
    }

    if (parsed == null) {
      return;
    }

    setState(() {
      if (needsLatitude) {
        _latitudeController.text = parsed.latitude.toStringAsFixed(6);
      }
      if (needsLongitude) {
        _longitudeController.text = parsed.longitude.toStringAsFixed(6);
      }
      if (needsName) {
        final parsedName = parsed.name?.trim();
        _nameController.text = (parsedName != null && parsedName.isNotEmpty)
            ? parsedName
            : 'Pinned place';
      }
    });
  }

  Future<void> _save() async {
    await _autoExtractFromLinkIfNeeded();

    if (!mounted) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      PlaceFormData(
        name: _nameController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location service is disabled.')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is denied.')),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read current location.')),
      );
    }
  }

  Future<void> _pickOnMap() async {
    final existingLat = double.tryParse(_latitudeController.text.trim());
    final existingLng = double.tryParse(_longitudeController.text.trim());
    final initialPoint = existingLat != null && existingLng != null
        ? LatLng(existingLat, existingLng)
        : const LatLng(48.8566, 2.3522);

    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPoint: initialPoint),
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _latitudeController.text = picked.latitude.toStringAsFixed(6);
      _longitudeController.text = picked.longitude.toStringAsFixed(6);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _googleMapsLinkController,
                decoration: const InputDecoration(
                  labelText: 'Google Maps link (optional)',
                  hintText: 'https://maps.google.com/...',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _extractFromGoogleMapsLink,
                  icon: const Icon(Icons.link),
                  label: const Text('Extract from link'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Use current location'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Pick on map'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _latitudeController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Enter a valid latitude';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _longitudeController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Enter a valid longitude';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
