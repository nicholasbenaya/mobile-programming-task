import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Cache gambar dalam memori (RAM) untuk seluruh sesi aplikasi.
/// Gambar yang sudah diunduh satu kali akan tersimpan di sesi sehingga
/// perpindahan tab, pergantian tampilan katalog/list, maupun scroll tidak akan
/// mengunduh ulang gambar dari jaringan.
class HeroImageSessionCache {
  HeroImageSessionCache._();
  static final HeroImageSessionCache instance = HeroImageSessionCache._();

  final Map<String, Uint8List> _cache = {};
  final Map<String, Future<Uint8List?>> _inFlight = {};
  final Set<String> _failed = {};

  bool isCached(String url) => _cache.containsKey(url);

  Uint8List? get(String url) => _cache[url];

  bool isFailed(String url) => _failed.contains(url);

  void put(String url, Uint8List bytes) {
    _cache[url] = bytes;
    _failed.remove(url);
  }

  Future<Uint8List?> fetch(String url) {
    if (_cache.containsKey(url)) {
      return Future.value(_cache[url]);
    }
    if (_failed.contains(url)) {
      return Future.value(null);
    }
    if (_inFlight.containsKey(url)) {
      return _inFlight[url]!;
    }

    final future = _download(url);
    _inFlight[url] = future;
    return future;
  }

  Future<Uint8List?> _download(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        _failed.add(url);
        return null;
      }
      final response = await http.get(uri).timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bytes = response.bodyBytes;
        if (bytes.isNotEmpty) {
          _cache[url] = bytes;
          _failed.remove(url);
          return bytes;
        }
      }
      _failed.add(url);
    } catch (_) {
      _failed.add(url);
    } finally {
      _inFlight.remove(url);
    }
    return null;
  }

  /// Memuat awal (prewarm) gambar di background tanpa memblokir thread UI.
  void prewarm(Iterable<String> paths) {
    for (final p in paths) {
      final trimmed = p.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        final resolved = proxyImageUrl(trimmed);
        if (!_cache.containsKey(resolved) && !_failed.contains(resolved)) {
          fetch(resolved);
        }
      }
    }
  }

  void clear() {
    _cache.clear();
    _inFlight.clear();
    _failed.clear();
  }
}

String proxyImageUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url;

  // The legacy image host is reachable but can be unreliable in browsers / CORS.
  if (uri.host == 'image.ibb.co' || uri.host == 'i.ibb.co') {
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
  }
  return url;
}

Widget heroImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final imagePath = path.trim();
  if (imagePath.isEmpty) {
    return _imagePlaceholder(width: width, height: height);
  }

  final isNetwork =
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  if (!isNetwork) {
    return Image.asset(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder:
          errorBuilder ??
          (_, __, ___) => _imagePlaceholder(width: width, height: height),
    );
  }

  final resolvedUrl = proxyImageUrl(imagePath);
  return _HeroSessionCachedImage(
    url: resolvedUrl,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}

class _HeroSessionCachedImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const _HeroSessionCachedImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  State<_HeroSessionCachedImage> createState() => _HeroSessionCachedImageState();
}

class _HeroSessionCachedImageState extends State<_HeroSessionCachedImage> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _HeroSessionCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadImage();
    }
  }

  void _loadImage() {
    final cached = HeroImageSessionCache.instance.get(widget.url);
    if (cached != null) {
      _bytes = cached;
      _hasError = false;
      return;
    }

    if (HeroImageSessionCache.instance.isFailed(widget.url)) {
      _bytes = null;
      _hasError = true;
      return;
    }

    _hasError = false;

    HeroImageSessionCache.instance.fetch(widget.url).then((bytes) {
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _hasError = (bytes == null);
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _bytes = null;
        _hasError = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: widget.errorBuilder ??
            (_, __, ___) => _imagePlaceholder(
                  width: widget.width,
                  height: widget.height,
                ),
      );
    }

    if (_hasError) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          context,
          'Gagal memuat gambar',
          StackTrace.current,
        );
      }
      return _imagePlaceholder(width: widget.width, height: widget.height);
    }

    final placeholder = _imagePlaceholder(
      width: widget.width,
      height: widget.height,
    );

    final loadingWidget = Stack(
      alignment: Alignment.center,
      children: [
        placeholder,
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: loadingWidget,
      );
    }
    return loadingWidget;
  }
}

Widget _imagePlaceholder({double? width, double? height}) {
  final isCompact =
      (width != null && width < 75) || (height != null && height < 75);
  return Container(
    width: width,
    height: height,
    color: const Color(0xFFE8ECF1),
    alignment: Alignment.center,
    child: isCompact
        ? Icon(
            Icons.person_outline_rounded,
            color: const Color(0xFF7A8696),
            size: (height != null
                    ? height * 0.45
                    : (width != null ? width * 0.45 : 24.0))
                .clamp(16.0, 32.0),
          )
        : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded, color: Color(0xFF7A8696), size: 32),
              SizedBox(height: 4),
              Text(
                'Foto belum tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7A8696),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
  );
}
