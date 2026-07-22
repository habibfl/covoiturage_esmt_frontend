// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:covoiturage_esmt/main.dart';

void main() {
  testWidgets('App starts on login screen', (WidgetTester tester) async {
    await tester.pumpWidget(CovoiturageESMTApp());
    expect(find.text('CovoiturageESMT'), findsOneWidget);
    expect(find.text('Pas de compte ? S\'inscrire'), findsOneWidget);
  });
}
