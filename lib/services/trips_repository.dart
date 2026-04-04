import '../models/trip.dart';
import '../models/attraction_suggestion.dart';
import '../models/place.dart';
import '../models/day.dart';
import '../models/itinerary_item.dart';
import '../models/trip_document.dart';
import '../models/trip_note.dart';
import 'trips_data_source.dart';

/// Repository pattern to manage trip data access
class TripsRepository {
  TripsRepository({TripsDataSource? dataSource})
      : _dataSource = dataSource ?? TripsDataSource();

  final TripsDataSource _dataSource;

  // Trip operations
  Future<List<Trip>> listTrips() => _dataSource.listTrips();

  Future<Trip?> getTripById(int tripId) => _dataSource.getTripById(tripId);

  Future<int> createTrip({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
  }) {
    return _dataSource.createTrip(
      name: name,
      startDate: startDate,
      endDate: endDate,
      coverPhotoPath: coverPhotoPath,
    );
  }

  Future<void> deleteTrip(int tripId) => _dataSource.deleteTrip(tripId);

  Future<void> updateTrip({
    required int tripId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
  }) {
    return _dataSource.updateTrip(
      tripId: tripId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      coverPhotoPath: coverPhotoPath,
    );
  }

  // Note operations
  Future<List<TripNote>> listNotes(int tripId) => _dataSource.listNotes(tripId);

  Future<void> addNote({
    required int tripId,
    required String content,
  }) {
    return _dataSource.addNote(tripId: tripId, content: content);
  }

  Future<void> updateNote({
    required int noteId,
    required String content,
  }) {
    return _dataSource.updateNote(noteId: noteId, content: content);
  }

  Future<void> deleteNote(int noteId) => _dataSource.deleteNote(noteId);

  // Place operations
  Future<List<Place>> listPlaces(int tripId) => _dataSource.listPlaces(tripId);

  Future<void> addPlace({
    required int tripId,
    required String name,
    required double latitude,
    required double longitude,
    String? note,
  }) {
    return _dataSource.addPlace(
      tripId: tripId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      note: note,
    );
  }

  Future<void> updatePlace({
    required int placeId,
    required String name,
    required double latitude,
    required double longitude,
    String? note,
  }) {
    return _dataSource.updatePlace(
      placeId: placeId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      note: note,
    );
  }

  Future<void> deletePlace(int placeId) => _dataSource.deletePlace(placeId);

  // Day operations
  Future<List<Day>> listDays(int tripId) => _dataSource.listDays(tripId);

  Future<void> createDay({
    required int tripId,
    required String name,
  }) {
    return _dataSource.createDay(tripId: tripId, name: name);
  }

  // Itinerary operations
  Future<List<ItineraryItem>> listItineraryItemsByDay(int dayId) =>
      _dataSource.listItineraryItemsByDay(dayId);

  Future<List<ItineraryItem>> listItineraryItemsByTrip(int tripId) =>
      _dataSource.listItineraryItemsByTrip(tripId);

  Future<void> addItineraryItem({
    required int tripId,
    required int dayId,
    required int placeId,
  }) {
    return _dataSource.addItineraryItem(
      tripId: tripId,
      dayId: dayId,
      placeId: placeId,
    );
  }

  Future<void> moveItineraryItemUp({
    required int dayId,
    required int itemId,
    required int currentPosition,
  }) {
    return _dataSource.moveItineraryItemUp(
      dayId: dayId,
      itemId: itemId,
      currentPosition: currentPosition,
    );
  }

  Future<void> moveItineraryItemDown({
    required int dayId,
    required int itemId,
    required int currentPosition,
  }) {
    return _dataSource.moveItineraryItemDown(
      dayId: dayId,
      itemId: itemId,
      currentPosition: currentPosition,
    );
  }

  // Document operations
  Future<List<TripDocument>> listDocuments(int tripId) =>
      _dataSource.listDocuments(tripId);

  Future<void> addDocument({
    required int tripId,
    required String filePath,
    required String type,
  }) {
    return _dataSource.addDocument(
      tripId: tripId,
      filePath: filePath,
      type: type,
    );
  }

  Future<void> deleteDocument(int documentId) =>
      _dataSource.deleteDocument(documentId);

  // Attraction suggestion operations
  Future<void> replaceAttractionSuggestions({
    required int tripId,
    required List<AttractionSuggestion> suggestions,
  }) {
    return _dataSource.replaceAttractionSuggestions(
      tripId: tripId,
      suggestions: suggestions,
    );
  }

  Future<List<AttractionSuggestion>> listAttractionSuggestions(int tripId) {
    return _dataSource.listAttractionSuggestions(tripId);
  }
}
