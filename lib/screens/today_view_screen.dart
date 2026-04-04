import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/day.dart';
import '../models/itinerary_item.dart';
import '../models/trip.dart';
import '../services/trips_repository.dart';

class TodayViewScreen extends StatefulWidget {
  const TodayViewScreen({super.key});

  @override
  State<TodayViewScreen> createState() => _TodayViewScreenState();
}

class _TodayViewScreenState extends State<TodayViewScreen> {
  final TripsRepository _repository = TripsRepository();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  bool _isLoading = true;
  Trip? _activeTrip;
  Day? _todayDay;
  List<ItineraryItem> _todayItems = [];

  @override
  void initState() {
    super.initState();
    _loadTodayView();
  }

  Future<void> _loadTodayView() async {
    setState(() {
      _isLoading = true;
    });

    final trips = await _repository.listTrips();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Trip? activeTrip;
    for (final trip in trips) {
      final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
      final end = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
      if ((today.isAtSameMomentAs(start) || today.isAfter(start)) &&
          (today.isAtSameMomentAs(end) || today.isBefore(end))) {
        activeTrip = trip;
        break;
      }
    }

    Day? todayDay;
    List<ItineraryItem> todayItems = [];

    if (activeTrip != null) {
      final days = await _repository.listDays(activeTrip.id);
      final dayNumber = today
              .difference(
                DateTime(
                  activeTrip.startDate.year,
                  activeTrip.startDate.month,
                  activeTrip.startDate.day,
                ),
              )
              .inDays +
          1;

      for (final day in days) {
        if (day.dayOrder == dayNumber) {
          todayDay = day;
          break;
        }
      }

      if (todayDay != null) {
        todayItems = await _repository.listItineraryItemsByDay(todayDay.id);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _activeTrip = activeTrip;
      _todayDay = todayDay;
      _todayItems = todayItems;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadTodayView,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_activeTrip == null) {
      return const Center(
        child: Text('No active trip for today.'),
      );
    }

    final nextPlace = _todayItems.isNotEmpty ? _todayItems.first.placeName : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeTrip!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_dateFormat.format(_activeTrip!.startDate)} - ${_dateFormat.format(_activeTrip!.endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayDay == null ? 'Today plan' : _todayDay!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  nextPlace == null ? 'Next place: none' : 'Next place: $nextPlace',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_todayDay == null)
          const Text('No day is scheduled for today.')
        else if (_todayItems.isEmpty)
          const Text('No places planned for today.')
        else
          ..._todayItems.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.placeName),
              ),
            ),
          ),
      ],
    );
  }
}
