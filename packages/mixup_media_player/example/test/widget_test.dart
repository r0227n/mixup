import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixup_media_player_example/main.dart';

void main() {
  testWidgets('builds the example app shell', (tester) async {
    const home = SizedBox(key: Key('test-home'));

    await tester.pumpWidget(const ExampleApp(home: home));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Mixup Media Player');
    expect(find.byKey(const Key('test-home')), findsOneWidget);
  });
}
