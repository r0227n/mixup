import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@internal
final class AudioViewer extends StatelessWidget {
  const AudioViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(Icons.graphic_eq, color: Colors.white, size: 72),
      ),
    );
  }
}
