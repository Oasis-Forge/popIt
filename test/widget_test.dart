import 'package:flutter_test/flutter_test.dart';

import 'package:pop_it/main.dart';

void main() {
  testWidgets('Home shows Pop It brand and Play', (WidgetTester tester) async {
    await tester.pumpWidget(const PopItApp());
    await tester.pump();

    expect(find.text('Pop It'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}
