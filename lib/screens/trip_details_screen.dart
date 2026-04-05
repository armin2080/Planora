import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/day.dart';
import '../models/place.dart';
import '../models/trip_document.dart';
import '../models/trip.dart';
import '../services/place_photo_lookup_service.dart';
import '../services/shared_location_import_coordinator.dart';
import '../services/shared_location_import_service.dart';
import '../services/trip_details_controller.dart';
import 'map_screen.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/trip_details_sections.dart';
import '../widgets/place_form_dialog.dart';
import '../widgets/note_form_dialog.dart';
import '../widgets/trip_form_dialog.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({
    super.key,
    required this.trip,
    this.initialSharedText,
  });

  final Trip trip;
  final String? initialSharedText;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late final TripDetailsController _controller;
  late Trip _trip;
  final SharedLocationImportService _sharedLocationImportService =
      const SharedLocationImportService();
  late final SharedLocationImportCoordinator _sharedLocationImportCoordinator;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final PlacePhotoLookupService _placePhotoLookupService =
      PlacePhotoLookupService();
  final Map<int, String?> _placePhotoCache = <int, String?>{};
  bool _handledInitialSharedText = false;
  int _selectedRootTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _controller = TripDetailsController(trip: widget.trip);
    _sharedLocationImportCoordinator = SharedLocationImportCoordinator(
      validator: _sharedLocationImportService,
    );
    _controller.addListener(_onControllerChanged);
    _controller.loadContent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialSharedText();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editTrip() async {
    final result = await TripFormDialog.show(
      context,
      title: 'Edit Trip',
      initialTrip: _trip,
    );

    if (result == null) {
      return;
    }

    await _controller.editTrip(
      name: result.name,
      startDate: result.startDate,
      endDate: result.endDate,
      coverPhotoPath: result.coverPhotoPath,
    );

    setState(() {
      _trip = _trip.copyWith(
        name: result.name,
        startDate: result.startDate,
        endDate: result.endDate,
        coverPhotoPath: result.coverPhotoPath,
      );
    });
  }

  Future<void> _deleteTrip() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('Delete "${_trip.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _controller.deleteTrip();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _addNote() async {
    final content = await NoteFormDialog.show(
      context,
      title: 'Add note',
    );

    if (content == null) {
      return;
    }

    await _controller.addNote(content);
  }

  Future<void> _addPlace() async {
    final result = await PlaceFormDialog.show(
      context,
      title: 'Add spot',
      contextHint: _trip.name,
    );

    if (result == null) {
      return;
    }

    await _controller.addPlace(
      name: result.name,
      latitude: result.latitude,
      longitude: result.longitude,
      note: result.note,
      googleMapsUrl: result.googleMapsUrl,
      tripadvisorUrl: result.tripadvisorUrl,
      category: result.category,
      photoUrl: result.photoUrl,
    );
  }

  Future<void> _handleInitialSharedText() async {
    if (_handledInitialSharedText) {
      return;
    }
    _handledInitialSharedText = true;

    final sharedText = widget.initialSharedText;
    if (!mounted) {
      return;
    }

    final result = await _sharedLocationImportCoordinator.importFromSharedText(
      context,
      sharedText: sharedText,
      contextHint: _trip.name,
      onImported: (placeData) => _controller.addPlace(
        name: placeData.name,
        latitude: placeData.latitude,
        longitude: placeData.longitude,
        note: placeData.note,
        googleMapsUrl: placeData.googleMapsUrl,
        tripadvisorUrl: placeData.tripadvisorUrl,
        category: placeData.category,
        photoUrl: placeData.photoUrl,
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == SharedLocationImportResult.noLocationDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Shared content was opened, but no map location was detected.'),
        ),
      );
    }
  }

  Future<void> _showQuickAdd() async {
    final action = await QuickAddSheet.show(context);

    switch (action) {
      case QuickAddAction.spot:
        await _addPlace();
        break;
      case QuickAddAction.note:
        await _addNote();
        break;
      case QuickAddAction.day:
        await _createDay();
        break;
      case QuickAddAction.file:
        await _attachDocument();
        break;
      default:
        break;
    }
  }

  Future<void> _editPlace(Place place) async {
    final result = await PlaceFormDialog.show(
      context,
      title: 'Edit spot',
      initialPlace: place,
      contextHint: _trip.name,
    );

    if (result == null) {
      return;
    }

    await _controller.editPlace(
      placeId: place.id,
      name: result.name,
      latitude: result.latitude,
      longitude: result.longitude,
      note: result.note,
      googleMapsUrl: result.googleMapsUrl,
      tripadvisorUrl: result.tripadvisorUrl,
      category: result.category,
      photoUrl: result.photoUrl,
    );
  }

  Future<void> _deletePlace(int placeId) async {
    await _controller.deletePlace(placeId);
  }

  Future<void> _openPlaceInGoogleMaps(Place place) async {
    final fallbackGoogleUrl = _extractLabeledUrl(place.note, 'Google Maps:');
    final uri = Uri.parse(place.googleMapsUrl ??
        fallbackGoogleUrl ??
        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _extractLabeledUrl(String? note, String label) {
    if (note == null || note.trim().isEmpty) {
      return null;
    }

    for (final line in note.split('\n')) {
      if (!line.toLowerCase().startsWith(label.toLowerCase())) {
        continue;
      }
      final value = line.substring(label.length).trim();
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
    }
    return null;
  }

  String? _extractLabeledValue(String? note, String label) {
    if (note == null || note.trim().isEmpty) {
      return null;
    }

    for (final line in note.split('\n')) {
      if (!line.toLowerCase().startsWith(label.toLowerCase())) {
        continue;
      }
      final value = line.substring(label.length).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<String?> _resolvePlacePhotoUrl(Place place) async {
    final existing = _placePhotoCache[place.id];
    if (existing != null) {
      return existing;
    }

    if (place.photoUrl != null && place.photoUrl!.trim().isNotEmpty) {
      _placePhotoCache[place.id] = place.photoUrl;
      return place.photoUrl;
    }

    final photo = await _placePhotoLookupService.findPhotoUrl(
      placeName: place.name,
      contextHint: _trip.name,
    );
    _placePhotoCache[place.id] = photo;
    return photo;
  }

  Future<void> _showPlaceDetails(Place place) async {
    final effectiveGoogleUrl = place.googleMapsUrl ??
      _extractLabeledUrl(place.note, 'Google Maps:') ??
        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
    final effectiveTripadvisorUrl =
      place.tripadvisorUrl ?? _extractLabeledUrl(place.note, 'Source:');
    final effectiveCategory =
      place.category ?? _extractLabeledValue(place.note, 'Category:');
    final effectivePhotoUrl = await _resolvePlacePhotoUrl(place);

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (effectivePhotoUrl != null && effectivePhotoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Image.network(
                        effectivePhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                if (effectivePhotoUrl != null && effectivePhotoUrl.isNotEmpty)
                  const SizedBox(height: 14),
                Text(
                  place.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  '${place.latitude.toStringAsFixed(6)}, ${place.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (effectiveCategory != null &&
                    effectiveCategory.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text(effectiveCategory.trim()),
                    ),
                  ),
                if (place.note != null && place.note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(place.note!.trim()),
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(effectiveGoogleUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Google Maps'),
                    ),
                    if (effectiveTripadvisorUrl != null &&
                        effectiveTripadvisorUrl.trim().isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(effectiveTripadvisorUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.travel_explore),
                        label: const Text('Tripadvisor'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createDay() async {
    final controller = TextEditingController(
      text: 'Day ${_controller.days.length + 1}',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create day'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Day name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await _controller.createDay(name.trim());
  }

  Future<void> _addPlaceToDay(Day day) async {
    if (_controller.places.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a spot first.')),
      );
      return;
    }

    final placeId = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Assign spot'),
            ),
            ..._controller.places.map(
              (place) => ListTile(
                title: Text(place.name),
                subtitle: Text(
                  '${place.latitude.toStringAsFixed(6)}, ${place.longitude.toStringAsFixed(6)}',
                ),
                onTap: () => Navigator.of(context).pop(place.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (placeId == null) {
      return;
    }

    await _controller.addPlaceToDay(dayId: day.id, placeId: placeId);
  }

  Future<void> _editNote(int noteId, String currentContent) async {
    final content = await NoteFormDialog.show(
      context,
      title: 'Edit note',
      initialContent: currentContent,
    );

    if (content == null) {
      return;
    }

    await _controller.editNote(noteId: noteId, content: content);
  }

  Future<void> _deleteNote(int noteId) async {
    await _controller.deleteNote(noteId);
  }

  Future<void> _attachDocument() async {
    await _controller.attachDocument();
  }

  Future<void> _openDocument(TripDocument document) async {
    await _controller.openDocument(document);
  }

  Future<void> _deleteDocument(TripDocument document) async {
    await _controller.deleteDocument(document);
  }

  Widget _buildPlacesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        TripSummaryCard(
          trip: _trip,
          dateFormat: _dateFormat,
        ),
        const SizedBox(height: 12),
        PlacesSection(
          isLoading: _controller.isLoadingPlaces,
          places: _controller.places,
          onAdd: _addPlace,
          onTapPlace: _showPlaceDetails,
          resolvePhotoUrl: _resolvePlacePhotoUrl,
          onOpenInGoogleMaps: _openPlaceInGoogleMaps,
          onEdit: _editPlace,
          onDelete: _deletePlace,
        ),
      ],
    );
  }

  Widget _buildFilesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        DocumentsSection(
          isLoading: _controller.isLoadingDocuments,
          documents: _controller.documents,
          dateFormat: _dateFormat,
          onAttach: _attachDocument,
          onOpen: _openDocument,
          onDelete: _deleteDocument,
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        NotesSection(
          isLoading: _controller.isLoadingNotes,
          notes: _controller.notes,
          dateFormat: _dateFormat,
          onAdd: _addNote,
          onEdit: _editNote,
          onDelete: _deleteNote,
        ),
      ],
    );
  }

  Widget _buildItineraryTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        ItinerarySection(
          isLoading: _controller.isLoadingPlan,
          days: _controller.days,
          dayItems: _controller.dayItems,
          onCreateDay: _createDay,
          onAddPlaceToDay: _addPlaceToDay,
          onMoveUp: _controller.moveItemUp,
          onMoveDown: _controller.moveItemDown,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_trip.name),
          actions: [
            IconButton(
              tooltip: 'Map',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MapScreen(
                      tripId: _trip.id,
                      tripName: _trip.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: _editTrip,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: _deleteTrip,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedRootTabIndex = index;
              });
            },
            tabs: const [
              Tab(text: 'Places', icon: Icon(Icons.place_outlined)),
              Tab(text: 'Files', icon: Icon(Icons.attach_file)),
              Tab(text: 'Notes', icon: Icon(Icons.sticky_note_2_outlined)),
              Tab(text: 'Itinerary', icon: Icon(Icons.view_timeline_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlacesTab(),
            _buildFilesTab(),
            _buildNotesTab(),
            _buildItineraryTab(),
          ],
        ),
        floatingActionButton: _selectedRootTabIndex != 3
            ? FloatingActionButton.extended(
                onPressed: _showQuickAdd,
                icon: const Icon(Icons.bolt_outlined),
                label: const Text('Quick add'),
              )
            : null,
      ),
    );
  }
}
