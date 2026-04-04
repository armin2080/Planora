import 'package:flutter/material.dart';

enum QuickAddAction {
  spot,
  note,
  day,
  file,
}

class QuickAddSheet {
  const QuickAddSheet._();

  static Future<QuickAddAction?> show(BuildContext context) {
    return showModalBottomSheet<QuickAddAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Quick add'),
            ),
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: const Text('Add spot'),
              onTap: () => Navigator.of(context).pop(QuickAddAction.spot),
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Add note'),
              onTap: () => Navigator.of(context).pop(QuickAddAction.note),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Create day'),
              onTap: () => Navigator.of(context).pop(QuickAddAction.day),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Attach file'),
              onTap: () => Navigator.of(context).pop(QuickAddAction.file),
            ),
          ],
        ),
      ),
    );
  }
}
