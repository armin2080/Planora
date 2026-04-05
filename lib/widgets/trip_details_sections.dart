import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../models/day.dart';
import '../models/attraction_suggestion.dart';
import '../models/itinerary_item.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../models/trip_document.dart';
import '../models/trip_note.dart';

class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({
    super.key,
    required this.trip,
    required this.dateFormat,
  });

  final Trip trip;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (trip.coverPhotoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: double.infinity,
                  height: 152,
                  child: Image.file(
                    File(trip.coverPhotoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              trip.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _InfoRow(
                label: 'Start date', value: dateFormat.format(trip.startDate)),
            const SizedBox(height: 8),
            _InfoRow(label: 'End date', value: dateFormat.format(trip.endDate)),
            const SizedBox(height: 8),
            _InfoRow(
                label: 'Created', value: dateFormat.format(trip.createdAt)),
          ],
        ),
      ),
    );
  }
}

class DocumentsSection extends StatelessWidget {
  const DocumentsSection({
    super.key,
    required this.isLoading,
    required this.documents,
    required this.dateFormat,
    required this.onAttach,
    required this.onOpen,
    required this.onDelete,
  });

  final bool isLoading;
  final List<TripDocument> documents;
  final DateFormat dateFormat;
  final VoidCallback onAttach;
  final ValueChanged<TripDocument> onOpen;
  final ValueChanged<TripDocument> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Files',
          actionLabel: 'Attach file',
          actionIcon: Icons.attach_file,
          onAction: onAttach,
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (documents.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No files yet.'),
          )
        else
          ...documents.map(
            (document) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => onOpen(document),
                leading: _DocumentPreview(document: document),
                title: Text(p.basename(document.filePath)),
                subtitle: Text(
                  '${document.type.toUpperCase()} • ${dateFormat.format(document.createdAt)}',
                ),
                trailing: IconButton(
                  tooltip: 'Delete record',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(document),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PlacesSection extends StatelessWidget {
  const PlacesSection({
    super.key,
    required this.isLoading,
    required this.places,
    required this.onAdd,
    required this.onTapPlace,
    required this.onOpenInGoogleMaps,
    required this.onEdit,
    required this.onDelete,
    required this.resolvePhotoUrl,
  });

  final bool isLoading;
  final List<Place> places;
  final VoidCallback onAdd;
  final ValueChanged<Place> onTapPlace;
  final ValueChanged<Place> onOpenInGoogleMaps;
  final ValueChanged<Place> onEdit;
  final ValueChanged<int> onDelete;
  final Future<String?> Function(Place place) resolvePhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Places',
          actionLabel: 'Add place',
          actionIcon: Icons.add,
          onAction: onAdd,
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (places.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No places yet.'),
          )
        else
          ...places.map(
            (place) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTapPlace(place),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PlacePhotoPreview(
                        place: place,
                        resolvePhotoUrl: resolvePhotoUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    place.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Open in Google Maps',
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => onOpenInGoogleMaps(place),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Edit spot',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => onEdit(place),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Delete spot',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => onDelete(place.id),
                                ),
                              ],
                            ),
                            if (place.category != null &&
                                place.category!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Chip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  label: Text(place.category!.trim()),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.place_outlined,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (place.note != null &&
                                place.note!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  place.note!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlacePhotoPreview extends StatelessWidget {
  const _PlacePhotoPreview({
    required this.place,
    required this.resolvePhotoUrl,
  });

  final Place place;
  final Future<String?> Function(Place place) resolvePhotoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: place.photoUrl != null && place.photoUrl!.trim().isNotEmpty
            ? Image.network(
                place.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              )
            : FutureBuilder<String?>(
                future: resolvePhotoUrl(place),
                builder: (context, snapshot) {
                  final url = snapshot.data;
                  if (url == null || url.trim().isEmpty) {
                    return _placeholder(context);
                  }
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(context),
                  );
                },
              ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.photo_outlined, size: 20),
    );
  }
}

class ItinerarySection extends StatelessWidget {
  const ItinerarySection({
    super.key,
    required this.isLoading,
    required this.days,
    required this.dayItems,
    required this.onCreateDay,
    required this.onAddPlaceToDay,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final bool isLoading;
  final List<Day> days;
  final Map<int, List<ItineraryItem>> dayItems;
  final VoidCallback onCreateDay;
  final ValueChanged<Day> onAddPlaceToDay;
  final ValueChanged<ItineraryItem> onMoveUp;
  final ValueChanged<ItineraryItem> onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Itinerary',
          actionLabel: 'Create day',
          actionIcon: Icons.add,
          onAction: onCreateDay,
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (days.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No days yet.'),
          )
        else
          ...days.map((day) {
            final items = dayItems[day.id] ?? <ItineraryItem>[];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextButton.icon(
                          onPressed: () => onAddPlaceToDay(day),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Add place'),
                        ),
                      ],
                    ),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('No places assigned.'),
                      )
                    else
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isFirst = index == 0;
                        final isLast = index == items.length - 1;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.placeName),
                          trailing: Wrap(
                            spacing: 0,
                            children: [
                              IconButton(
                                tooltip: 'Move up',
                                icon: const Icon(Icons.arrow_upward),
                                onPressed:
                                    isFirst ? null : () => onMoveUp(item),
                              ),
                              IconButton(
                                tooltip: 'Move down',
                                icon: const Icon(Icons.arrow_downward),
                                onPressed:
                                    isLast ? null : () => onMoveDown(item),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class NotesSection extends StatelessWidget {
  const NotesSection({
    super.key,
    required this.isLoading,
    required this.notes,
    required this.dateFormat,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isLoading;
  final List<TripNote> notes;
  final DateFormat dateFormat;
  final VoidCallback onAdd;
  final void Function(int noteId, String content) onEdit;
  final ValueChanged<int> onDelete;

  static String _stripLinksFromNote(String content) {
    final lines = content.split('\n');
    final visibleLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final lower = trimmed.toLowerCase();
      final containsMapOrTripadvisorLink = RegExp(
        r'https?://(?:maps\.google\.com|google\.com/maps|tripadvisor\.[a-z.]+)',
        caseSensitive: false,
      ).hasMatch(trimmed);
      final isImportedLinkLine = lower.startsWith('source:') ||
          lower.startsWith('google maps:') ||
          lower.startsWith('tripadvisor:') ||
          lower.startsWith('trip advisor:') ||
          lower.startsWith('tripadvisor link:') ||
          lower.startsWith('maps:');

      if (containsMapOrTripadvisorLink || isImportedLinkLine) {
        continue;
      }

      visibleLines.add(trimmed);
    }

    return visibleLines.join('\n').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Notes',
          actionLabel: 'Add note',
          actionIcon: Icons.add,
          onAction: onAdd,
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (notes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No notes yet.'),
          )
        else
          ...notes.map(
            (note) {
              final displayContent = _stripLinksFromNote(note.content);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    displayContent.isEmpty ? '(empty note)' : displayContent,
                  ),
                  subtitle: Text(dateFormat.format(note.createdAt)),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit note',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(note.id, note.content),
                      ),
                      IconButton(
                        tooltip: 'Delete note',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(note.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class AttractionSuggestionsSection extends StatelessWidget {
  const AttractionSuggestionsSection({
    super.key,
    required this.isLoading,
    required this.attractions,
    required this.onRefresh,
  });

  final bool isLoading;
  final List<AttractionSuggestion> attractions;
  final Future<void> Function() onRefresh;

  List<String> _buildCategories() {
    final categories = <String>[];
    for (final category in AttractionSuggestion.categoryOrder) {
      if (attractions.any((item) => item.category == category)) {
        categories.add(category);
      }
    }

    if (categories.isEmpty) {
      categories.add('other');
    }
    return categories;
  }

  List<AttractionSuggestion> _byCategory(String category) {
    final filtered = attractions
        .where((item) => item.category == category)
        .toList(growable: false);

    filtered.sort((left, right) {
      final leftScore = left.score ?? -1;
      final rightScore = right.score ?? -1;
      final scoreComparison = rightScore.compareTo(leftScore);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return left.name.compareTo(right.name);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Things to Do',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: isLoading ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh suggestions'),
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (attractions.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No suggestions yet. Add a city trip while online.'),
            ),
          )
        else
          DefaultTabController(
            length: categories.length,
            child: Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: [
                      for (final category in categories)
                        Tab(
                          text: AttractionSuggestion.categoryLabel(category),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final category in categories)
                          _CategoryAttractionsList(
                            attractions: _byCategory(category),
                            emptyLabel:
                                'No ${AttractionSuggestion.categoryLabel(category).toLowerCase()} found.',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryAttractionsList extends StatelessWidget {
  const _CategoryAttractionsList({
    required this.attractions,
    required this.emptyLabel,
  });

  final List<AttractionSuggestion> attractions;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (attractions.isEmpty) {
      return Center(
        child: Text(emptyLabel),
      );
    }

    final preview = attractions.first;
    final remaining = attractions.skip(1).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        _CategoryPreviewCard(attraction: preview),
        const SizedBox(height: 8),
        ...remaining.map(
          (attraction) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: Text(attraction.name),
              subtitle: Text(
                [
                  if (attraction.type != null &&
                      attraction.type!.trim().isNotEmpty)
                    attraction.type!,
                  if (attraction.description != null &&
                      attraction.description!.trim().isNotEmpty)
                    attraction.description!,
                  if (attraction.lat != null && attraction.lng != null)
                    '${attraction.lat!.toStringAsFixed(5)}, ${attraction.lng!.toStringAsFixed(5)}',
                ].join(' • '),
              ),
              trailing: attraction.score == null
                  ? null
                  : _ScorePill(score: attraction.score!),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryPreviewCard extends StatelessWidget {
  const _CategoryPreviewCard({required this.attraction});

  final AttractionSuggestion attraction;

  @override
  Widget build(BuildContext context) {
    final imageUrl = attraction.imageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.trim().isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PreviewPlaceholder(
                  label: attraction.name,
                ),
              ),
            )
          else
            _PreviewPlaceholder(label: attraction.name),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        attraction.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (attraction.score != null)
                      _ScorePill(score: attraction.score!),
                  ],
                ),
                if (attraction.description != null &&
                    attraction.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(attraction.description!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16),
            const SizedBox(width: 4),
            Text(score.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: Icon(actionIcon),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.document});

  final TripDocument document;

  @override
  Widget build(BuildContext context) {
    if (document.type != 'image') {
      return const Icon(Icons.picture_as_pdf);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Image.file(
          File(document.filePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image_outlined, size: 20),
        ),
      ),
    );
  }
}
