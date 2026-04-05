import 'package:sqflite/sqflite.dart';

import '../models/day.dart';
import '../models/attraction_suggestion.dart';
import '../models/place.dart';
import '../models/itinerary_item.dart';
import '../models/trip.dart';
import '../models/trip_note.dart';
import '../models/trip_document.dart';
import '../database/database_service.dart';

class TripsDataSource {
  TripsDataSource({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<Database> get _db async => _databaseService.database;

  // Trip operations
  Future<List<Trip>> listTrips() async {
    final db = await _db;
    final rows = await db.query('trips', orderBy: 'start_date ASC');
    return rows.map(Trip.fromMap).toList(growable: false);
  }

  Future<Trip?> getTripById(int tripId) async {
    final db = await _db;
    final rows = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [tripId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Trip.fromMap(rows.first);
  }

  Future<int> createTrip({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
  }) async {
    final db = await _db;
    final insertedId = await db.insert('trips', {
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'cover_photo_path': coverPhotoPath,
      'created_at': DateTime.now().toIso8601String(),
    });
    return insertedId;
  }

  Future<void> deleteTrip(int tripId) async {
    final db = await _db;
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }

  Future<void> updateTrip({
    required int tripId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? coverPhotoPath,
  }) async {
    final db = await _db;
    await db.update(
      'trips',
      {
        'name': name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'cover_photo_path': coverPhotoPath,
      },
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  // Note operations
  Future<List<TripNote>> listNotes(int tripId) async {
    final db = await _db;
    final rows = await db.query(
      'notes',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TripNote.fromMap).toList(growable: false);
  }

  Future<void> addNote({
    required int tripId,
    required String content,
  }) async {
    final db = await _db;
    await db.insert('notes', {
      'trip_id': tripId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateNote({
    required int noteId,
    required String content,
  }) async {
    final db = await _db;
    await db.update(
      'notes',
      {'content': content},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<void> deleteNote(int noteId) async {
    final db = await _db;
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  // Place operations
  Future<List<Place>> listPlaces(int tripId) async {
    final db = await _db;
    final rows = await db.query(
      'places',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Place.fromMap).toList(growable: false);
  }

  Future<void> addPlace({
    required int tripId,
    required String name,
    required double latitude,
    required double longitude,
    String? note,
    String? googleMapsUrl,
    String? tripadvisorUrl,
    String? category,
    String? photoUrl,
  }) async {
    final db = await _db;
    await db.insert('places', {
      'trip_id': tripId,
      'name': name,
      'lat': latitude,
      'lng': longitude,
      'note': note,
      'google_maps_url': googleMapsUrl,
      'tripadvisor_url': tripadvisorUrl,
      'category': category,
      'photo_url': photoUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updatePlace({
    required int placeId,
    required String name,
    required double latitude,
    required double longitude,
    String? note,
    String? googleMapsUrl,
    String? tripadvisorUrl,
    String? category,
    String? photoUrl,
  }) async {
    final db = await _db;
    await db.update(
      'places',
      {
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'note': note,
        'google_maps_url': googleMapsUrl,
        'tripadvisor_url': tripadvisorUrl,
        'category': category,
        'photo_url': photoUrl,
      },
      where: 'id = ?',
      whereArgs: [placeId],
    );
  }

  Future<void> deletePlace(int placeId) async {
    final db = await _db;
    await db.delete('places', where: 'id = ?', whereArgs: [placeId]);
  }

  // Day operations
  Future<List<Day>> listDays(int tripId) async {
    final db = await _db;
    final rows = await db.query(
      'days',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'day_order ASC',
    );
    return rows.map(Day.fromMap).toList(growable: false);
  }

  Future<void> createDay({
    required int tripId,
    required String name,
  }) async {
    final db = await _db;
    final maxRow = await db.rawQuery(
      'SELECT COALESCE(MAX(day_order), 0) AS max_order FROM days WHERE trip_id = ?',
      [tripId],
    );

    final nextOrder = ((maxRow.first['max_order'] as int?) ?? 0) + 1;

    await db.insert('days', {
      'trip_id': tripId,
      'name': name,
      'day_order': nextOrder,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Itinerary operations
  Future<List<ItineraryItem>> listItineraryItemsByDay(int dayId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT
        i.id,
        i.trip_id,
        i.day_id,
        i.place_id,
        i.position,
        i.created_at,
        p.name AS place_name
      FROM itinerary_items i
      INNER JOIN places p ON p.id = i.place_id
      WHERE i.day_id = ?
      ORDER BY i.position ASC
      ''',
      [dayId],
    );

    return rows.map(ItineraryItem.fromMap).toList(growable: false);
  }

  Future<List<ItineraryItem>> listItineraryItemsByTrip(int tripId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT
        i.id,
        i.trip_id,
        i.day_id,
        i.place_id,
        i.position,
        i.created_at,
        p.name AS place_name
      FROM itinerary_items i
      INNER JOIN places p ON p.id = i.place_id
      WHERE i.trip_id = ?
      ORDER BY i.day_id ASC, i.position ASC
      ''',
      [tripId],
    );

    return rows.map(ItineraryItem.fromMap).toList(growable: false);
  }

  Future<void> addItineraryItem({
    required int tripId,
    required int dayId,
    required int placeId,
  }) async {
    final db = await _db;

    final maxRow = await db.rawQuery(
      'SELECT COALESCE(MAX(position), 0) AS max_position FROM itinerary_items WHERE day_id = ?',
      [dayId],
    );

    final nextPosition = ((maxRow.first['max_position'] as int?) ?? 0) + 1;

    await db.insert('itinerary_items', {
      'trip_id': tripId,
      'day_id': dayId,
      'place_id': placeId,
      'position': nextPosition,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> moveItineraryItemUp({
    required int dayId,
    required int itemId,
    required int currentPosition,
  }) async {
    if (currentPosition <= 1) {
      return;
    }

    final db = await _db;

    final swapRows = await db.query(
      'itinerary_items',
      columns: ['id'],
      where: 'day_id = ? AND position = ?',
      whereArgs: [dayId, currentPosition - 1],
      limit: 1,
    );

    if (swapRows.isEmpty) {
      return;
    }

    final swapId = swapRows.first['id'] as int;

    await db.transaction((txn) async {
      await txn.update(
        'itinerary_items',
        {'position': currentPosition - 1},
        where: 'id = ?',
        whereArgs: [itemId],
      );
      await txn.update(
        'itinerary_items',
        {'position': currentPosition},
        where: 'id = ?',
        whereArgs: [swapId],
      );
    });
  }

  Future<void> moveItineraryItemDown({
    required int dayId,
    required int itemId,
    required int currentPosition,
  }) async {
    final db = await _db;

    final swapRows = await db.query(
      'itinerary_items',
      columns: ['id'],
      where: 'day_id = ? AND position = ?',
      whereArgs: [dayId, currentPosition + 1],
      limit: 1,
    );

    if (swapRows.isEmpty) {
      return;
    }

    final swapId = swapRows.first['id'] as int;

    await db.transaction((txn) async {
      await txn.update(
        'itinerary_items',
        {'position': currentPosition + 1},
        where: 'id = ?',
        whereArgs: [itemId],
      );
      await txn.update(
        'itinerary_items',
        {'position': currentPosition},
        where: 'id = ?',
        whereArgs: [swapId],
      );
    });
  }

  // Document operations
  Future<List<TripDocument>> listDocuments(int tripId) async {
    final db = await _db;
    final rows = await db.query(
      'documents',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TripDocument.fromMap).toList(growable: false);
  }

  Future<void> addDocument({
    required int tripId,
    required String filePath,
    required String type,
  }) async {
    final db = await _db;
    await db.insert('documents', {
      'trip_id': tripId,
      'file_path': filePath,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteDocument(int documentId) async {
    final db = await _db;
    await db.delete('documents', where: 'id = ?', whereArgs: [documentId]);
  }

  // Attraction suggestion operations
  Future<void> replaceAttractionSuggestions({
    required int tripId,
    required List<AttractionSuggestion> suggestions,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'attractions_suggestions',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );

      for (final suggestion in suggestions) {
        await txn.insert('attractions_suggestions', {
          ...suggestion.toMap(),
          'id': null,
          'trip_id': tripId,
        });
      }
    });
  }

  Future<List<AttractionSuggestion>> listAttractionSuggestions(
      int tripId) async {
    final db = await _db;
    final rows = await db.query(
      'attractions_suggestions',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'COALESCE(score, 0) DESC, id ASC',
    );

    return rows
        .map((row) => AttractionSuggestion.fromMap(row))
        .toList(growable: false);
  }

  Future<bool> hasAttractionSuggestions(int tripId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM attractions_suggestions WHERE trip_id = ?',
      [tripId],
    );

    final countValue = rows.first['count'];
    final count = countValue is int
        ? countValue
        : int.tryParse(countValue.toString()) ?? 0;

    return count > 0;
  }
}
