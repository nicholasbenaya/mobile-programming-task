import 'package:flutter/material.dart';

Image heroImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final isNetwork = path.startsWith('http://') || path.startsWith('https://');
  return Image(
    image: isNetwork
        ? NetworkImage(path)
        : AssetImage(path.isEmpty ? 'assets/images/soekarno.jpg' : path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
