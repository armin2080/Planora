import 'package:flutter_test/flutter_test.dart';
import 'package:planora/services/shared_text_intent_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  const service = SharedTextIntentService();

  test('extractText returns null for empty or non-text/url items', () {
    final empty = <SharedMediaFile>[];
    final imageOnly = <SharedMediaFile>[
      SharedMediaFile(path: '/tmp/image.png', type: SharedMediaType.image),
    ];

    expect(service.extractText(empty), isNull);
    expect(service.extractText(imageOnly), isNull);
  });

  test('extractText returns first valid text item', () {
    final items = <SharedMediaFile>[
      SharedMediaFile(path: '/tmp/file.pdf', type: SharedMediaType.file),
      SharedMediaFile(path: '  ', type: SharedMediaType.text),
      SharedMediaFile(
        path: 'https://maps.google.com/?q=48.858370,2.294481',
        type: SharedMediaType.url,
      ),
      SharedMediaFile(path: 'second text', type: SharedMediaType.text),
    ];

    expect(
      service.extractText(items),
      'https://maps.google.com/?q=48.858370,2.294481',
    );
  });
}
