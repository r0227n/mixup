import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@internal
final class MediaSurfaceStack extends StatelessWidget {
  const MediaSurfaceStack({
    required this.surface,
    required this.isLoading,
    required this.loadingLabel,
    super.key,
  });

  final Widget surface;
  final bool isLoading;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        surface,
        if (isLoading)
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: Semantics(
                label: loadingLabel,
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
