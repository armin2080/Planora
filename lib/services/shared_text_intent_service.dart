import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class SharedTextIntentService {
  const SharedTextIntentService();

  Stream<String> textStream() {
    return ReceiveSharingIntent.instance
        .getMediaStream()
        .map(extractText)
        .where((value) => value != null)
        .cast<String>();
  }

  Future<String?> getInitialText() async {
    final sharedItems = await ReceiveSharingIntent.instance.getInitialMedia();
    return extractText(sharedItems);
  }

  Future<void> reset() {
    return ReceiveSharingIntent.instance.reset();
  }

  String? extractText(List<SharedMediaFile> sharedItems) {
    for (final item in sharedItems) {
      if ((item.type == SharedMediaType.text ||
              item.type == SharedMediaType.url) &&
          item.path.trim().isNotEmpty) {
        return item.path;
      }
    }
    return null;
  }
}
