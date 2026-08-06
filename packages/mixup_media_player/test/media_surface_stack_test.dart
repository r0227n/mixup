import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixup_media_player/src/viewer/media_surface_stack.dart';

void main() {
  testWidgets('keeps the media surface mounted behind the loading overlay', (
    tester,
  ) async {
    const surfaceKey = ValueKey('surface');

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 320,
          height: 180,
          child: MediaSurfaceStack(
            surface: SizedBox(key: surfaceKey),
            isLoading: true,
            loadingLabel: 'Loading',
          ),
        ),
      ),
    );

    expect(find.byKey(surfaceKey), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
