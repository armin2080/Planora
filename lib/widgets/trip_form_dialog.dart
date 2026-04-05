import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/trip.dart';

class TripFormData {
  TripFormData({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.coverPhotoPath,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverPhotoPath;
}

class TripFormDialog extends StatefulWidget {
  const TripFormDialog({
    super.key,
    required this.title,
    this.initialTrip,
  });

  final String title;
  final Trip? initialTrip;

  static Future<TripFormData?> show(
    BuildContext context, {
    required String title,
    Trip? initialTrip,
  }) {
    return showDialog<TripFormData>(
      context: context,
      builder: (context) => TripFormDialog(
        title: title,
        initialTrip: initialTrip,
      ),
    );
  }

  @override
  State<TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends State<TripFormDialog> {
  late final TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _coverPhotoPath;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialTrip?.name ?? '');
    _startDate = widget.initialTrip?.startDate ?? DateTime.now();
    _endDate = widget.initialTrip?.endDate ??
        DateTime.now().add(const Duration(days: 1));
    _coverPhotoPath = widget.initialTrip?.coverPhotoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endDate = picked;
    });
  }

  Future<void> _pickCoverPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.single.path == null) {
      return;
    }

    final source = File(result.files.single.path!);
    if (!await source.exists()) {
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(appDir.path, 'planora', 'covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final extension = p.extension(source.path).toLowerCase();
    final safeBaseName = p
        .basenameWithoutExtension(source.path)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName =
        'cover_${DateTime.now().millisecondsSinceEpoch}_$safeBaseName$extension';
    final destinationPath = p.join(coversDir.path, fileName);

    await source.copy(destinationPath);
    if (!mounted) {
      return;
    }

    setState(() {
      _coverPhotoPath = destinationPath;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      TripFormData(
        name: name,
        startDate: _startDate,
        endDate: _endDate,
        coverPhotoPath: _coverPhotoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Trip name',
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start date'),
            subtitle: Text(_dateFormat.format(_startDate)),
            onTap: _pickStartDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End date'),
            subtitle: Text(_dateFormat.format(_endDate)),
            onTap: _pickEndDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 84,
                  height: 56,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: _coverPhotoPath == null
                      ? const Icon(Icons.image_outlined)
                      : Image.file(
                          File(_coverPhotoPath!),
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
                    const Text('Cover photo'),
                    TextButton.icon(
                      onPressed: _pickCoverPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(_coverPhotoPath == null
                          ? 'Choose image'
                          : 'Change image'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
