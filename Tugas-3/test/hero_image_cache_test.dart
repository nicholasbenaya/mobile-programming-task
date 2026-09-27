import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pahlawan_nasional/utils/hero_image.dart';

void main() {
  setUp(() {
    HeroImageSessionCache.instance.clear();
  });

  test('HeroImageSessionCache stores and retrieves image bytes for the session', () async {
    const testUrl = 'https://example.com/hero_test.jpg';
    final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    expect(HeroImageSessionCache.instance.isCached(testUrl), isFalse);
    expect(HeroImageSessionCache.instance.get(testUrl), isNull);

    // Save in session
    HeroImageSessionCache.instance.put(testUrl, sampleBytes);

    expect(HeroImageSessionCache.instance.isCached(testUrl), isTrue);
    expect(HeroImageSessionCache.instance.get(testUrl), equals(sampleBytes));

    // Clear session
    HeroImageSessionCache.instance.clear();
    expect(HeroImageSessionCache.instance.isCached(testUrl), isFalse);
    expect(HeroImageSessionCache.instance.get(testUrl), isNull);
  });

  test('proxyImageUrl properly handles image.ibb.co links', () {
    const legacyUrl = 'https://image.ibb.co/test1234/foto.jpg';
    final proxied = proxyImageUrl(legacyUrl);
    expect(proxied, startsWith('https://images.weserv.nl/?url='));

    const normalUrl = 'https://upload.wikimedia.org/test.jpg';
    expect(proxyImageUrl(normalUrl), equals(normalUrl));
  });
}
