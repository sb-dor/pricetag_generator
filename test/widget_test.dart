import 'package:flutter_test/flutter_test.dart';
import 'package:canvas_barcode_generator/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
  });
}
