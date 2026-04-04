import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/day.dart';
import '../models/place.dart';
import '../models/trip_document.dart';
import '../models/trip.dart';
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
  bool _handledInitialSharedText = false;

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
    );

    if (result == null) {
      return;
    }

    await _controller.addPlace(
      name: result.name,
      latitude: result.latitude,
      longitude: result.longitude,
      note: result.note,
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
      onImported: (placeData) => _controller.addPlace(
        name: placeData.name,
        latitude: placeData.latitude,
        longitude: placeData.longitude,
        note: placeData.note,
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
    );
  }

  Future<void> _deletePlace(int placeId) async {
    await _controller.deletePlace(placeId);
  }

  Future<void> _openPlaceInGoogleMaps(Place place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        TripSummaryCard(
          trip: _trip,
          dateFormat: _dateFormat,
        ),
        const SizedBox(height: 12),
        DocumentsSection(
          isLoading: _controller.isLoadingDocuments,
          documents: _controller.documents,
          dateFormat: _dateFormat,
          onAttach: _attachDocument,
          onOpen: _openDocument,
          onDelete: _deleteDocument,
        ),
        const SizedBox(height: 12),
        PlacesSection(
          isLoading: _controller.isLoadingPlaces,
          places: _controller.places,
          onAdd: _addPlace,
          onOpenInGoogleMaps: _openPlaceInGoogleMaps,
          onEdit: _editPlace,
          onDelete: _deletePlace,
        ),
        const SizedBox(height: 12),
        ItinerarySection(
          isLoading: _controller.isLoadingPlan,
          days: _controller.days,
          dayItems: _controller.dayItems,
          onCreateDay: _createDay,
          onAddPlaceToDay: _addPlaceToDay,
          onMoveUp: _controller.moveItemUp,
          onMoveDown: _controller.moveItemDown,
        ),
        const SizedBox(height: 12),
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

  Widget _buildThingsToDoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
      children: [
        AttractionSuggestionsSection(
          isLoading: _controller.isLoadingAttractions,
          attractions: _controller.attractions,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
              if (index == 1) {
                _controller.loadAttractions();
              }
            },
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Things to Do', icon: Icon(Icons.travel_explore)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildThingsToDoTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showQuickAdd,
          icon: const Icon(Icons.bolt_outlined),
          label: const Text('Quick add'),
        ),
      ),
    );
  }
}
