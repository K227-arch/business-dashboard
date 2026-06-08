import 'package:flutter_test/flutter_test.dart';
import 'package:business_dashboard/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BusinessDashboardApp());
    expect(find.byType(BusinessDashboardApp), findsOneWidget);
  });
}
