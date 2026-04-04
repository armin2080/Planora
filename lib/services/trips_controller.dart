import 'package:flutter/foundation.dart';

import '../models/trip.dart';
import 'trips_repository.dart';

/// Controller for managing trips list state and business logic
class TripsController extends ChangeNotifier {
  TripsController({TripsRepository? repository})
      : _repository = repository ?? TripsRepository();

  final TripsRepository _repository;

  bool isLoading = false;
  String? error;
  List<Trip> trips = [];

  Future<void> loadTrips() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      trips = await _repository.listTrips();
    } catch (_) {
      error = 'Failed to load trips.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<int> createTrip({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
  }) async {
    final createdTripId = await _repository.createTrip(
      name: name,
      startDate: startDate,
      endDate: endDate,
      coverPhotoPath: coverPhotoPath,
    );
    await loadTrips();
    return createdTripId;
  }

  Future<void> editTrip({
    required int tripId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
  }) async {
    await _repository.updateTrip(
      tripId: tripId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      coverPhotoPath: coverPhotoPath,
    );
    await loadTrips();
  }

  Future<void> deleteTrip(int tripId) async {
    await _repository.deleteTrip(tripId);
    await loadTrips();
  }

  Future<Trip?> getTripById(int tripId) {
    return _repository.getTripById(tripId);
  }
}
