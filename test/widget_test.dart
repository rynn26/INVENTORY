import 'package:flutter_test/flutter_test.dart';
import 'package:inventorrrrryy/main.dart';

void main() {
  testWidgets('TitipKasir modular app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TitipKasirApp());
    expect(find.text('TitipKasir'), findsWidgets);
    expect(find.text('Masuk ke Aplikasi'), findsOneWidget);
  });
}
