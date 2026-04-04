import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StoredDocument {
  StoredDocument({
    required this.filePath,
    required this.type,
  });

  final String filePath;
  final String type;
}

class DocumentStorageService {
  Future<StoredDocument?> pickAndStoreDocument(int tripId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.single;
    if (picked.path == null) {
      return null;
    }

    final source = File(picked.path!);
    if (!await source.exists()) {
      return null;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final recordsDir = Directory(
      p.join(appDir.path, 'planora', 'trips', '$tripId', 'records'),
    );
    if (!await recordsDir.exists()) {
      await recordsDir.create(recursive: true);
    }

    final extension = p.extension(source.path).toLowerCase();
    final baseName = p.basenameWithoutExtension(source.path);
    final safeBaseName = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeBaseName$extension';
    final destinationPath = p.join(recordsDir.path, fileName);

    await source.copy(destinationPath);

    return StoredDocument(
      filePath: destinationPath,
      type: _detectType(extension),
    );
  }

  Future<void> deleteStoredDocument(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _detectType(String extension) {
    if (extension == '.pdf') {
      return 'pdf';
    }
    return 'image';
  }
}
