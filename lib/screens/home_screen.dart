import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';
import '../services/attractions_service.dart';
import '../services/shared_text_intent_service.dart';
import '../services/trips_controller.dart';
import '../services/trips_repository.dart';
import '../widgets/trip_form_dialog.dart';
import 'today_view_screen.dart';
import 'trip_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TripsController _controller = TripsController();
  final SharedTextIntentService _sharedTextIntentService =
      const SharedTextIntentService();
  final AttractionsService _attractionsService = AttractionsService();
  final TripsRepository _tripsRepository = TripsRepository();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  StreamSubscription<String>? _sharedTextSubscription;
  String? _lastHandledSharedText;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.loadTrips();
    _listenForSharedText();
  }

  @override
  void dispose() {
    _sharedTextSubscription?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _listenForSharedText() {
    _sharedTextSubscription = _sharedTextIntentService.textStream().listen(
          _handleSharedText,
        );

    _sharedTextIntentService.getInitialText().then((text) {
      if (text != null) {
        _handleSharedText(text);
      }
    });
  }

  Future<void> _handleSharedText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _lastHandledSharedText == trimmed || !mounted) {
      return;
    }

    _lastHandledSharedText = trimmed;

    if (_controller.trips.isEmpty) {
      await _controller.loadTrips();
    }

    if (!mounted) {
      return;
    }

    if (_controller.trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a trip first to import shared location.'),
        ),
      );
      return;
    }

    final trip = await showModalBottomSheet<Trip>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            const ListTile(title: Text('Import into trip')),
            ..._controller.trips.map(
              (item) => ListTile(
                leading: const Icon(Icons.luggage_outlined),
                title: Text(item.name),
                subtitle: Text(
                  '${_dateFormat.format(item.startDate)} - ${_dateFormat.format(item.endDate)}',
                ),
                onTap: () => Navigator.of(context).pop(item),
              ),
            ),
          ],
        ),
      ),
    );

    if (trip == null || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailsScreen(
          trip: trip,
          initialSharedText: trimmed,
        ),
      ),
    );

    await _controller.loadTrips();
    await _sharedTextIntentService.reset();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createTrip() async {
    final result = await TripFormDialog.show(
      context,
      title: 'New Trip',
    );

    if (result == null) {
      return;
    }

    developer.log('[HomeScreen] Creating trip: ${result.name}');

    final createdTripId = await _controller.createTrip(
      name: result.name,
      startDate: result.startDate,
      endDate: result.endDate,
      coverPhotoPath: result.coverPhotoPath,
    );

    // Fetch suggestions for the created trip so they are ready when details open.
    await _tryFetchAttractionsForTrip(result.name, createdTripId);
  }

  Future<void> _tryFetchAttractionsForTrip(String cityName, int tripId) async {
    developer
        .log('[HomeScreen] Attempting to fetch attractions for: $cityName');

    try {
      final isOnline = await _attractionsService.hasInternetConnection();
      developer.log('[HomeScreen] Is online: $isOnline');
      if (!isOnline) {
        developer.log('[HomeScreen] Offline - skipping attractions fetch');
        return;
      }

      final attractions =
          await _attractionsService.fetchAttractions(cityName, tripId);
      developer.log('[HomeScreen] Got ${attractions.length} attractions');

      if (attractions.isNotEmpty) {
        await _tripsRepository.replaceAttractionSuggestions(
          tripId: tripId,
          suggestions: attractions,
        );
      }

      if (!mounted || attractions.isEmpty) {
        return;
      }

      developer.log('[HomeScreen] Attractions saved to DB for trip $tripId');
    } catch (e) {
      developer.log('[HomeScreen] Error fetching attractions: $e');
      // Silently fail
    }
  }

  Future<void> _editTrip(Trip trip) async {
    final result = await TripFormDialog.show(
      context,
      title: 'Edit Trip',
      initialTrip: trip,
    );

    if (result == null) {
      return;
    }

    await _controller.editTrip(
      tripId: trip.id,
      name: result.name,
      startDate: result.startDate,
      endDate: result.endDate,
      coverPhotoPath: result.coverPhotoPath,
    );
  }

  Future<void> _deleteTrip(Trip trip) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('Delete "${trip.name}" from Planora?'),
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
      await _controller.deleteTrip(trip.id);
    }
  }

  Future<void> _openTrip(Trip trip) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripDetailsScreen(trip: trip)),
    );
    await _controller.loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _filteredTrips();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTrip,
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
      body: Column(
        children: [
          _buildHeroHeader(colorScheme),
          Expanded(child: _buildBody(filteredTrips)),
        ],
      ),
    );
  }

  List<Trip> _filteredTrips() {
    final now = DateTime.now();
    if (_activeFilter == 'upcoming') {
      return _controller.trips
          .where((trip) => DateTime(
                  trip.startDate.year, trip.startDate.month, trip.startDate.day)
              .isAfter(DateTime(now.year, now.month, now.day)
                  .subtract(const Duration(days: 1))))
          .toList();
    }
    return _controller.trips;
  }

  Widget _buildHeroHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.explore_outlined, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Planora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Theme',
                onPressed: _toggleTheme,
                icon: Icon(
                  widget.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: Colors.white,
                ),
              ),
              IconButton(
                tooltip: 'Today',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TodayViewScreen()),
                  );
                },
                icon: const Icon(Icons.today_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterChip(
                selected: _activeFilter == 'all',
                label: 'All Journeys',
                onTap: () => setState(() => _activeFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                selected: _activeFilter == 'upcoming',
                label: 'Upcoming',
                onTap: () => setState(() => _activeFilter = 'upcoming'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    final newMode =
        widget.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    widget.onThemeModeChanged(newMode);
  }

  Widget _buildBody(List<Trip> filteredTrips) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return Center(child: Text(_controller.error!));
    }

    if (_controller.trips.isEmpty) {
      return const Center(
        child: Text('No trips yet. Create your first trip.'),
      );
    }

    if (filteredTrips.isEmpty) {
      return const Center(
        child: Text('No upcoming trips yet.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: filteredTrips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final trip = filteredTrips[index];
        final tripDays = trip.endDate.difference(trip.startDate).inDays + 1;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openTrip(trip),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 68,
                          height: 68,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: trip.coverPhotoPath == null
                              ? const Icon(Icons.landscape_outlined)
                              : Image.file(
                                  File(trip.coverPhotoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_dateFormat.format(trip.startDate)} - ${_dateFormat.format(trip.endDate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editTrip(trip),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTrip(trip),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$tripDays day${tripDays == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withAlpha(40),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
