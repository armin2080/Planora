import 'package:flutter/material.dart';

class NoteFormDialog extends StatefulWidget {
  const NoteFormDialog({
    super.key,
    required this.title,
    this.initialContent,
  });

  final String title;
  final String? initialContent;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? initialContent,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => NoteFormDialog(
        title: title,
        initialContent: initialContent,
      ),
    );
  }

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      return;
    }

    Navigator.of(context).pop(content);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _contentController,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(
          hintText: 'Write a note',
          border: OutlineInputBorder(),
        ),
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
