import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pos_app/main.dart';
import 'package:pos_app/services/local_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await LocalDbService.seedData();
  });

  testWidgets('App boots to dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(expired: false));
    await tester.pumpAndSettle();

    expect(find.text('My Café POS'), findsOneWidget);
    expect(find.text('Open POS'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
