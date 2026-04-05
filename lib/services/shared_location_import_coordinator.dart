import 'package:flutter/material.dart';

import '../widgets/place_form_dialog.dart';
import 'shared_location_import_service.dart';

enum SharedLocationImportResult {
  skipped,
  noLocationDetected,
  cancelled,
  imported,
}

class SharedLocationImportCoordinator {
  SharedLocationImportCoordinator({SharedLocationImportService? validator})
      : _validator = validator ?? const SharedLocationImportService();

  final SharedLocationImportService _validator;

  Future<SharedLocationImportResult> importFromSharedText(
    BuildContext context, {
    required String? sharedText,
    String? contextHint,
    required Future<void> Function(PlaceFormData placeData) onImported,
  }) async {
    final normalized = sharedText?.trim();
    if (normalized == null || normalized.isEmpty) {
      return SharedLocationImportResult.skipped;
    }

    if (!_validator.canImportLocation(normalized)) {
      return SharedLocationImportResult.noLocationDetected;
    }

    final placeData = await PlaceFormDialog.show(
      context,
      title: 'Import shared location',
      initialGoogleMapsLink: normalized,
      contextHint: contextHint,
    );

    if (placeData == null) {
      return SharedLocationImportResult.cancelled;
    }

    await onImported(placeData);
    return SharedLocationImportResult.imported;
  }
}
