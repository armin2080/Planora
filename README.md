# Planora

Offline-first personal travel planning app for Android.

Plan your trips, organize your spots, and keep everything accessible — even without internet.

## Features

- **Trips**: Create, edit, and delete trips with dates
- **Spots**: Manage places with coordinates and optional notes
- **Quick Add**: Fast entry for spot, note, day, or file from one action
- **Section Tabs**: Trip details split into dedicated tabs for Places, Files, Notes, and Itinerary
- **Share Into Planora**: Share Google Maps or Tripadvisor links/text from Android apps directly into a trip
- **External Link Parsing**: Extract location details from Google Maps links and Tripadvisor URLs
- **Tripadvisor Link Import**: Resolve Tripadvisor activity links into spot coordinates and auto-add a Google Maps reference link in notes
- **Place Details**: Tap a place to view photo, category, Google Maps link, and Tripadvisor link when available
- **Map + Routing**: OSM map with markers, estimated offline routing (foot/car), and open in Google Maps
- **Itinerary**: Organize places by day and reorder items
- **Documents**: Attach local files per trip and open/delete them offline
- **Today View**: Quick snapshot of current-day planning
- **Offline-First**: SQLite + local storage, works without network

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── trip.dart
│   ├── place.dart
│   ├── day.dart
│   ├── itinerary_item.dart
│   ├── trip_note.dart
│   └── trip_document.dart
├── database/
│   └── database_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── trip_details_screen.dart
│   ├── map_screen.dart
│   ├── location_picker_screen.dart
│   └── today_view_screen.dart
├── services/
│   ├── trips_data_source.dart
│   ├── trips_repository.dart
│   ├── trips_controller.dart
│   ├── trip_details_controller.dart
│   ├── document_storage_service.dart
│   ├── shared_text_intent_service.dart
│   ├── shared_location_import_service.dart
│   ├── shared_location_import_coordinator.dart
│   ├── google_maps_link_parser.dart
│   ├── tripadvisor_link_parser.dart
│   └── external_location_link_import_service.dart
└── widgets/
   ├── trip_form_dialog.dart
   ├── place_form_dialog.dart
   ├── note_form_dialog.dart
   └── quick_add_sheet.dart
```

## Database Schema

**trips**
- id (INTEGER PRIMARY KEY)
- name (TEXT) — journey name
- start_date (TEXT) — ISO 8601 datetime
- end_date (TEXT) — ISO 8601 datetime
- created_at (TEXT) — ISO 8601 datetime

**notes**
- id (INTEGER PRIMARY KEY)
- trip_id (INTEGER FOREIGN KEY)
- content (TEXT)
- created_at (TEXT)

**places**
- id (INTEGER PRIMARY KEY)
- trip_id (INTEGER FOREIGN KEY)
- name (TEXT)
- lat (REAL)
- lng (REAL)
- note (TEXT, optional)
- created_at (TEXT)

**days**
- id (INTEGER PRIMARY KEY)
- trip_id (INTEGER FOREIGN KEY)
- name (TEXT)
- day_order (INTEGER)
- created_at (TEXT)

**itinerary_items**
- id (INTEGER PRIMARY KEY)
- trip_id (INTEGER FOREIGN KEY)
- day_id (INTEGER FOREIGN KEY)
- place_id (INTEGER FOREIGN KEY)
- position (INTEGER)
- created_at (TEXT)

**documents**
- id (INTEGER PRIMARY KEY)
- trip_id (INTEGER FOREIGN KEY)
- file_path (TEXT)
- type (TEXT)
- created_at (TEXT)

## Tech Stack

- **Flutter 3.41.6** — Cross-platform mobile UI
- **Dart 3.11.4** — Programming language
- **SQLite (sqflite)** — Local persistence
- **ChangeNotifier controllers** — Simple state management
- **flutter_map + OSM** — Map rendering
- **geolocator** — Device location
- **receive_sharing_intent** — Android share-in flow
- **url_launcher** — Open routes/places in Google Maps
- **Tripadvisor Content API** — Optional attraction categories, ratings, and photos when built with a TripAdvisor API key

## Getting Started

### Prerequisites

- Flutter SDK 3.41.6 or later
- Android SDK 36+
- Java JDK 17+

### Installation

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repo-url>
   cd Planora
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on Android emulator**:
   ```bash
   flutter devices  # List available devices
   flutter run -d emulator-5554
   ```

   Or run on physical device:
   ```bash
   flutter run -d <device-id>
   ```

## Architecture Decisions

### Separation of Concerns
- **Models**: Pure data classes with serialization (toMap/fromMap)
- **Data Source**: SQL queries and persistence operations
- **Repository**: App-level data access abstraction
- **Controllers**: UI-facing business logic and state
- **Screens/Widgets**: Presentation and user interaction

### Offline-First
- All data stored locally in SQLite
- Core planning works without internet
- Full functionality without internet
- Foreign keys enabled for data integrity

### Practical UX Layer
- Quick add workflow to reduce manual input
- Link import + extraction from shared Google Maps and Tripadvisor URLs
- Map-based location picking and current-location autofill

## Running the App

### On Android Emulator
```bash
flutter run -d emulator-5554
```

### On Physical Device
```bash
flutter run -d <your-device-id>
```

### Debug Mode
```bash
flutter run --debug
```

### Release Build
```bash
flutter build apk --release
flutter build appbundle --release
```

## Development Notes

- The app initializes SQLite database on first run
- All trips are stored in the device's app-specific directory
- Documents are copied and referenced by local file path
- Dates are stored as ISO 8601 strings for consistency
- To enable TripAdvisor-backed suggestions, build with `--dart-define=TRIPADVISOR_API_KEY=your_key_here`

## Share Into Planora (Android)

You can share text/links from other apps into Planora:

1. In Google Maps, Tripadvisor, or another app, tap **Share** on a location/activity
2. Choose **Planora**
3. Select a trip
4. Confirm/import in the spot form

This supports Google Maps and Tripadvisor link parsing and pre-fills spot data.

## Map Setup (OpenStreetMap + Offline)

Planora includes a trip map screen with:
- Saved trip spots as markers
- Current GPS position marker
- Offline route planning between saved points (on foot and car modes)
- One-tap open in Google Maps for places and routes

Place creation also supports external link parsing:
- Paste a Google Maps or Tripadvisor URL in the place form
- Tap **Extract from link** to auto-fill coordinates (and name when available)
- Tripadvisor imports add source details and a generated Google Maps link to the note
- You can also use **Use current location** or **Pick on map**

### Open map

1. Open a trip
2. Tap the map icon in the top app bar

### Offline tiles folder layout

Planora can load local OSM tiles from:

Android app documents directory:

`planora/osm_tiles/{z}/{x}/{y}.png`

Example:

`planora/osm_tiles/12/2200/1340.png`

If this folder exists with tiles, the map uses offline tiles.
If not, it falls back to online OpenStreetMap tiles.

### Preparing offline tiles

You can generate or export raster OSM tiles (PNG) with tools such as:
- MOBAC (Mobile Atlas Creator)
- Any tile exporter that outputs `z/x/y.png`

Then copy them into the app folder structure above.

### Notes

- Offline route mode in Planora is an estimate based on coordinates (distance + ETA).
- For turn-by-turn navigation, open the route in Google Maps from the map screen.
- Offline access is guaranteed when local tiles are present.

## Next Steps

- Add real graph-based offline routing (replace estimate mode)
- Add JSON export/import backup
- Add search and filtering across trips/spots
- Add trip templates
- Expand test coverage for parser, controllers, and migrations
