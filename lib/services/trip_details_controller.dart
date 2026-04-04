import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

import '../models/day.dart';
import '../models/attraction_suggestion.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../models/itinerary_item.dart';
import '../models/trip_document.dart';
import '../models/trip_note.dart';
import 'document_storage_service.dart';
import 'trips_repository.dart';

class TripDetailsController extends ChangeNotifier {
  TripDetailsController({
    required this.trip,
    TripsRepository? repository,
    DocumentStorageService? documentStorageService,
  })  : _repository = repository ?? TripsRepository(),
        _documentStorageService =
            documentStorageService ?? DocumentStorageService();

  Trip trip;
  final TripsRepository _repository;
  final DocumentStorageService _documentStorageService;

  bool isLoadingNotes = false;
  bool isLoadingPlaces = false;
  bool isLoadingPlan = false;
  bool isLoadingDocuments = false;
  bool isLoadingAttractions = false;
  List<Place> places = [];
  List<TripNote> notes = [];
  List<TripDocument> documents = [];
  List<AttractionSuggestion> attractions = [];
  List<Day> days = [];
  Map<int, List<ItineraryItem>> dayItems = {};

  Map<int, List<ItineraryItem>> _groupItemsByDay(List<ItineraryItem> items) {
    final grouped = <int, List<ItineraryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.dayId, () => []).add(item);
    }
    return grouped;
  }

  Future<void> editTrip({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
  }) async {
    await _repository.updateTrip(
      tripId: trip.id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      coverPhotoPath: coverPhotoPath,
    );
    trip = trip.copyWith(
      name: name,
      startDate: startDate,
      endDate: endDate,
      coverPhotoPath: coverPhotoPath,
    );
    notifyListeners();
  }

  Future<void> loadNotes() async {
    isLoadingNotes = true;
    notifyListeners();

    try {
      notes = await _repository.listNotes(trip.id);
    } finally {
      isLoadingNotes = false;
      notifyListeners();
    }
  }

  Future<void> loadPlaces() async {
    isLoadingPlaces = true;
    notifyListeners();

    try {
      places = await _repository.listPlaces(trip.id);
    } finally {
      isLoadingPlaces = false;
      notifyListeners();
    }
  }

  Future<void> loadContent() async {
    isLoadingNotes = true;
    isLoadingPlaces = true;
    isLoadingPlan = true;
    isLoadingDocuments = true;
    isLoadingAttractions = true;
    notifyListeners();

    try {
      final placesFuture = _repository.listPlaces(trip.id);
      final notesFuture = _repository.listNotes(trip.id);
      final daysFuture = _repository.listDays(trip.id);
      final documentsFuture = _repository.listDocuments(trip.id);
      final attractionsFuture = _repository.listAttractionSuggestions(trip.id);
      final itineraryItemsFuture =
          _repository.listItineraryItemsByTrip(trip.id);

      places = await placesFuture;
      notes = await notesFuture;
      days = await daysFuture;
      documents = await documentsFuture;
      attractions = await attractionsFuture;
      final itineraryItems = await itineraryItemsFuture;

      dayItems = _groupItemsByDay(itineraryItems);
    } finally {
      isLoadingNotes = false;
      isLoadingPlaces = false;
      isLoadingPlan = false;
      isLoadingDocuments = false;
      isLoadingAttractions = false;
      notifyListeners();
    }
  }

  Future<void> loadAttractions() async {
    isLoadingAttractions = true;
    notifyListeners();

    try {
      attractions = await _repository.listAttractionSuggestions(trip.id);
    } finally {
      isLoadingAttractions = false;
      notifyListeners();
    }
  }

  Future<void> loadDocuments() async {
    isLoadingDocuments = true;
    notifyListeners();

    try {
      documents = await _repository.listDocuments(trip.id);
    } finally {
      isLoadingDocuments = false;
      notifyListeners();
    }
  }

  Future<void> loadPlan() async {
    isLoadingPlan = true;
    notifyListeners();

    try {
      days = await _repository.listDays(trip.id);
      final itineraryItems =
          await _repository.listItineraryItemsByTrip(trip.id);
      dayItems = _groupItemsByDay(itineraryItems);
    } finally {
      isLoadingPlan = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String content) async {
    await _repository.addNote(tripId: trip.id, content: content);
    await loadNotes();
  }

  Future<void> editNote({
    required int noteId,
    required String content,
  }) async {
    await _repository.updateNote(noteId: noteId, content: content);
    await loadNotes();
  }

  Future<void> deleteNote(int noteId) async {
    await _repository.deleteNote(noteId);
    await loadNotes();
  }

  Future<void> addPlace({
    required String name,
    required double latitude,
    required double longitude,
    String? note,
  }) async {
    await _repository.addPlace(
      tripId: trip.id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      note: note,
    );
    await loadPlaces();
  }

  Future<void> editPlace({
    required int placeId,
    required String name,
    required double latitude,
    required double longitude,
    String? note,
  }) async {
    await _repository.updatePlace(
      placeId: placeId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      note: note,
    );
    await loadPlaces();
  }

  Future<void> deletePlace(int placeId) async {
    await _repository.deletePlace(placeId);
    await loadPlaces();
    await loadPlan();
  }

  Future<void> createDay(String name) async {
    await _repository.createDay(tripId: trip.id, name: name);
    await loadPlan();
  }

  Future<void> addPlaceToDay({
    required int dayId,
    required int placeId,
  }) async {
    await _repository.addItineraryItem(
      tripId: trip.id,
      dayId: dayId,
      placeId: placeId,
    );
    await loadPlan();
  }

  Future<void> moveItemUp(ItineraryItem item) async {
    await _repository.moveItineraryItemUp(
      dayId: item.dayId,
      itemId: item.id,
      currentPosition: item.position,
    );
    await loadPlan();
  }

  Future<void> moveItemDown(ItineraryItem item) async {
    await _repository.moveItineraryItemDown(
      dayId: item.dayId,
      itemId: item.id,
      currentPosition: item.position,
    );
    await loadPlan();
  }

  Future<void> attachDocument() async {
    final stored = await _documentStorageService.pickAndStoreDocument(trip.id);
    if (stored == null) {
      return;
    }

    await _repository.addDocument(
      tripId: trip.id,
      filePath: stored.filePath,
      type: stored.type,
    );
    await loadDocuments();
  }

  Future<void> openDocument(TripDocument document) {
    return OpenFilex.open(document.filePath);
  }

  Future<void> deleteDocument(TripDocument document) async {
    await _repository.deleteDocument(document.id);
    await _documentStorageService.deleteStoredDocument(document.filePath);
    await loadDocuments();
  }

  Future<void> deleteTrip() {
    return _repository.deleteTrip(trip.id);
  }
}
