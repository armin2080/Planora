import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../screens/location_picker_screen.dart';
import '../services/external_location_link_import_service.dart';
import '../services/google_maps_link_parser.dart';

class PlaceFormData {
  PlaceFormData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.note,
    this.googleMapsUrl,
    this.tripadvisorUrl,
    this.category,
    this.photoUrl,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? note;
  final String? googleMapsUrl;
  final String? tripadvisorUrl;
  final String? category;
  final String? photoUrl;
}

class PlaceFormDialog extends StatefulWidget {
  const PlaceFormDialog({
    super.key,
    required this.title,
    this.initialPlace,
    this.initialGoogleMapsLink,
    this.contextHint,
  });

  final String title;
  final Place? initialPlace;
  final String? initialGoogleMapsLink;
  final String? contextHint;

  static Future<PlaceFormData?> show(
    BuildContext context, {
    required String title,
    Place? initialPlace,
    String? initialGoogleMapsLink,
    String? contextHint,
  }) {
    return showDialog<PlaceFormData>(
      context: context,
      builder: (context) => PlaceFormDialog(
        title: title,
        initialPlace: initialPlace,
        initialGoogleMapsLink: initialGoogleMapsLink,
        contextHint: contextHint,
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
  final ExternalLocationLinkImportService _externalImportService =
      ExternalLocationLinkImportService();
  String? _importGoogleMapsUrl;
  String? _importTripadvisorUrl;
  String? _importCategory;
  String? _importPhotoUrl;

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
    _importGoogleMapsUrl = widget.initialPlace?.googleMapsUrl;
    _importTripadvisorUrl = widget.initialPlace?.tripadvisorUrl;
    _importCategory = widget.initialPlace?.category;
    _importPhotoUrl = widget.initialPlace?.photoUrl;

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
    final parsed =
        await _externalImportService.parseAndResolve(
      _googleMapsLinkController.text,
      contextHint: widget.contextHint,
    );

    if (!mounted) {
      return;
    }

    if (parsed == null) {
      final fallback =
          await _parseGoogleMapsInput(_googleMapsLinkController.text);
      if (!mounted) {
        return;
      }

      if (fallback == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not extract location from this link.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _latitudeController.text = fallback.latitude.toStringAsFixed(6);
        _longitudeController.text = fallback.longitude.toStringAsFixed(6);
        _importGoogleMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=${fallback.latitude},${fallback.longitude}';
        _importTripadvisorUrl = null;
        _importCategory = null;
        if (_nameController.text.trim().isEmpty &&
            fallback.name != null &&
            fallback.name!.trim().isNotEmpty) {
          _nameController.text = fallback.name!.trim();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinates extracted from Google Maps link.'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _latitudeController.text = parsed.latitude.toStringAsFixed(6);
      _longitudeController.text = parsed.longitude.toStringAsFixed(6);
      _importGoogleMapsUrl = parsed.googleMapsUrl;
      _importTripadvisorUrl = parsed.source == 'Tripadvisor'
          ? parsed.sourceUrl
          : null;
      _importCategory = parsed.category ?? _importCategory;
      _importPhotoUrl = parsed.photoUrl ?? _importPhotoUrl;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = parsed.name;
      }

      final importNote = parsed.note?.trim();
      if (importNote != null && importNote.isNotEmpty) {
        if (_noteController.text.trim().isEmpty) {
          _noteController.text = importNote;
        } else if (!_noteController.text.contains(importNote)) {
          _noteController.text = '${_noteController.text.trim()}\n\n$importNote';
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          parsed.resolutionHint != null && parsed.resolutionHint!.isNotEmpty
              ? 'Imported from ${parsed.source ?? 'link'} (${parsed.resolutionHint!}).'
              : 'Imported from ${parsed.source ?? 'link'} and generated Google Maps link.',
        ),
      ),
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

    final parsed = await _externalImportService.parseAndResolve(
      link,
      contextHint: widget.contextHint,
    );

    if (!mounted) {
      return;
    }

    if (parsed != null) {
      setState(() {
        if (needsLatitude) {
          _latitudeController.text = parsed.latitude.toStringAsFixed(6);
        }
        if (needsLongitude) {
          _longitudeController.text = parsed.longitude.toStringAsFixed(6);
        }
        if (needsName) {
          _nameController.text = parsed.name;
        }
        _importGoogleMapsUrl = parsed.googleMapsUrl;
        _importTripadvisorUrl = parsed.source == 'Tripadvisor'
            ? parsed.sourceUrl
          : null;
        _importCategory = parsed.category ?? _importCategory;
        _importPhotoUrl = parsed.photoUrl ?? _importPhotoUrl;

        final importNote = parsed.note?.trim();
        if (importNote != null && importNote.isNotEmpty) {
          if (_noteController.text.trim().isEmpty) {
            _noteController.text = importNote;
          } else if (!_noteController.text.contains(importNote)) {
            _noteController.text =
                '${_noteController.text.trim()}\n\n$importNote';
          }
        }
      });
      return;
    }

    final fallback = await _parseGoogleMapsInput(link);
    if (!mounted) {
      return;
    }

    if (fallback == null) {
      return;
    }

    setState(() {
      if (needsLatitude) {
        _latitudeController.text = fallback.latitude.toStringAsFixed(6);
      }
      if (needsLongitude) {
        _longitudeController.text = fallback.longitude.toStringAsFixed(6);
      }
      if (needsName) {
        final parsedName = fallback.name?.trim();
        _nameController.text = (parsedName != null && parsedName.isNotEmpty)
            ? parsedName
            : 'Pinned place';
      }
      _importGoogleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${fallback.latitude},${fallback.longitude}';
      _importTripadvisorUrl = null;
      _importCategory = null;
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
        googleMapsUrl: _importGoogleMapsUrl,
        tripadvisorUrl: _importTripadvisorUrl,
        category: _importCategory,
        photoUrl: _importPhotoUrl,
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
                  labelText: 'Maps or Tripadvisor link (optional)',
                  hintText: 'https://maps.google.com/... or tripadvisor link',
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
